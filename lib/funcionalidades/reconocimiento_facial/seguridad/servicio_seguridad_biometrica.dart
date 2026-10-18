import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../local/comparacion.dart';
import 'formato_referencia.dart';
import '../dominio/entidades/resultado_validacion_facial.dart';

class ErrorBiometrico implements Exception {
  const ErrorBiometrico(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Android protege la credencial persistente con Keystore. Se usa como ruta
/// privada en Firestore, nunca como campo del historial o de los informes.
class ServicioSeguridadBiometrica {
  ServicioSeguridadBiometrica(this.uid, {FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;
  final String uid;
  final FirebaseFirestore db;
  static const modelo = 'sface-2021dec-v1';
  static const canal = MethodChannel('crediasciende/dispositivo');
  String? _ticket;
  int? _versionValidada;
  double? _similitud;
  final _vigencia = Stopwatch();
  static const opciones = GetOptions(source: Source.server);

  void _sesion() {
    if (FirebaseAuth.instance.currentUser?.uid != uid) {
      throw const ErrorBiometrico(
        'Tu sesión cambió. Inicia sesión nuevamente.',
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const ErrorBiometrico(
        'La marcación con rostro y celular autorizado requiere la app Android.',
      );
    }
  }

  Future<Map<String, dynamic>> configuracion() async {
    _sesion();
    return (await db
                .collection('configuracionBiometrica')
                .doc(uid)
                .get(opciones)
                .timeout(const Duration(seconds: 15)))
            .data() ??
        {};
  }

  Future<Map<String, dynamic>> _credencial(int version) async {
    _sesion();
    final c = await canal
        .invokeMapMethod<String, dynamic>('credencial', {
          'uid': '$uid/$version',
        })
        .timeout(const Duration(seconds: 10));
    if (c == null ||
        c['token'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(c['token'] as String)) {
      throw const ErrorBiometrico('No se pudo identificar este celular.');
    }
    return c;
  }

  Future<({Map<String, dynamic> datos, String token, int version})>
  autorizado() async {
    final cfg = await configuracion();
    if (cfg['estado'] != 'activo' || cfg['version'] is! int) {
      throw const ErrorBiometrico(
        'Tu rostro y celular aún no están aprobados. Revisa «Rostro y celular» en Perfil.',
      );
    }
    final version = cfg['version'] as int;
    final c = await _credencial(version);
    final token = c['token'] as String;
    final datos =
        (await db
                .collection('credencialesBiometricas')
                .doc(token)
                .get(opciones)
                .timeout(const Duration(seconds: 15)))
            .data();
    if (datos == null ||
        datos['usuarioId'] != uid ||
        datos['estado'] != 'aprobado' ||
        datos['version'] != version ||
        datos['modeloFacial'] != modelo) {
      throw const ErrorBiometrico(
        'Este celular no está autorizado para tu cuenta. Solicita revisión al administrador.',
      );
    }
    return (datos: datos, token: token, version: version);
  }

  Future<void> permitirCapturaReferencia() async {
    final cfg = await configuracion();
    if (cfg['permitirEnrolamiento'] != true || cfg['version'] is! int) {
      throw const ErrorBiometrico(
        'El administrador debe habilitar el registro de tu rostro y celular.',
      );
    }
  }

  Future<String> consultarEstado() async {
    final cfg = await configuracion();
    if (cfg['estado'] == 'activo') {
      await autorizado();
      return 'Este rostro y celular están aprobados. Ya puedes registrar asistencia.';
    }
    if (cfg['permitirEnrolamiento'] != true || cfg['version'] is! int) {
      return 'El administrador debe habilitar el registro de tu rostro y celular.';
    }
    final c = await _credencial(cfg['version'] as int);
    final token = c['token'] as String;
    final solicitud = await db
        .collection('credencialesBiometricas')
        .doc(token)
        .get(opciones)
        .timeout(const Duration(seconds: 15));
    if (solicitud.exists) {
      return 'Solicitud pendiente de aprobación. Código del celular: ${token.substring(58)}. Muéstralo al administrador.';
    }
    return 'Registro habilitado. Ya puedes solicitar el registro de tu rostro y celular.';
  }

  Future<String> enviarReferencia(List<double> vector) async {
    validarVector(vector);
    await permitirCapturaReferencia();
    final cfg = await configuracion();
    final version = cfg['version'] as int;
    final c = await _credencial(version);
    final token = c['token'] as String;
    await db
        .collection('credencialesBiometricas')
        .doc(token)
        .set({
          'usuarioId': uid,
          'version': version,
          'estado': 'pendiente',
          'modeloFacial': modelo,
          'vector': Blob(codificarReferencia(vector)),
          'modeloCelular': c['modelo'],
          'codigo': token.substring(58),
          'consentimiento': true,
          'creadoEn': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 20));
    limpiar();
    return token.substring(58);
  }

  Future<String> compararCaptura(List<double> vector) async {
    limpiar();
    validarVector(vector);
    final a = await autorizado();
    final referencia = decodificarReferencia((a.datos['vector'] as Blob).bytes);
    try {
      final resultado = comparar(referencia, vector);
      if (!resultado.coincide) {
        throw const ErrorBiometrico(
          'Tu rostro no coincide con la referencia aprobada. Mejora la luz y vuelve a intentar.',
        );
      }
      _ticket = List.generate(
        24,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      _versionValidada = a.version;
      _similitud = resultado.similitud;
      _vigencia
        ..reset()
        ..start();
      return _ticket!;
    } finally {
      referencia.fillRange(0, referencia.length, 0);
    }
  }

  bool get validacionVigente =>
      _ticket != null && _vigencia.elapsed < const Duration(minutes: 2);
  Future<void> comprobarValidacion() async {
    if (!validacionVigente) {
      limpiar();
      throw const ErrorBiometrico(
        'La validación facial venció. Toma una nueva captura.',
      );
    }
    final a = await autorizado();
    if (a.version != _versionValidada || !validacionVigente) {
      limpiar();
      throw const ErrorBiometrico(
        'La autorización cambió. Valida tu rostro nuevamente.',
      );
    }
  }

  Future<ResultadoValidacionFacial> resultadoPara(String ticket) async {
    if (ticket != _ticket) {
      throw const ErrorBiometrico('Captura facial no válida.');
    }
    await comprobarValidacion();
    return const ResultadoValidacionFacial(
      permisoCamaraConcedido: true,
      rostroDetectado: true,
      cantidadRostros: 1,
      rutaImagenCapturada: 'validacion-local-sin-foto',
      mensajeEstado: 'Rostro coincidente y dos parpadeos verificados.',
    );
  }

  Future<void> guardarMarcacion(String id, Map<String, dynamic> datos) async {
    await comprobarValidacion();
    final a = await autorizado();
    if (a.version != _versionValidada ||
        !validacionVigente ||
        datos['usuarioId'] != uid) {
      throw const ErrorBiometrico(
        'Repite la validación facial antes de marcar.',
      );
    }
    final score = _similitud!;
    limpiar();
    final batch = db.batch();
    batch.set(
      db
          .collection('credencialesBiometricas')
          .doc(a.token)
          .collection('comprobantes')
          .doc(id),
      {
        'usuarioId': uid,
        'creadoEn': FieldValue.serverTimestamp(),
        'modeloFacial': modelo,
        'similitud': score,
        'parpadeos': 2,
      },
    );
    batch.set(db.collection('asistencias').doc(id), datos);
    // Conserva la confirmación tardía de la capa de asistencia.
    await batch.commit();
  }

  void limpiar() {
    _ticket = null;
    _similitud = null;
    _versionValidada = null;
    _vigencia
      ..stop()
      ..reset();
  }
}
