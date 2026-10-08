import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Politica local de sesion. Nunca almacena credenciales ni sustituye permisos.
class SesionTrabajador {
  SesionTrabajador({DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;
  static final instancia = SesionTrabajador();
  static const limite = Duration(minutes: 15);
  static const _clave = 'sesion_trabajador_v1';
  final DateTime Function() _reloj;
  SharedPreferences? _prefs;
  String? _uid;
  bool _mantener = false;
  DateTime? _actividad;
  Future<void> _escritura = Future.value();
  Future<void>? accesoEnCurso;
  int _operaciones = 0;
  bool get operacionEnCurso => _operaciones > 0;

  Future<void> cargar() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    try {
      final datos = jsonDecode(_prefs!.getString(_clave) ?? '{}') as Map;
      _uid = datos['uid'] as String?;
      _mantener = datos['mantener'] == true;
      _actividad = DateTime.tryParse(datos['actividad'] as String? ?? '');
    } catch (_) {
      _uid = null;
      _mantener = false;
      _actividad = null;
    }
  }

  bool vencida(String uid) {
    if (_uid != uid || _actividad == null) return true;
    if (_mantener) return false;
    final transcurrido = _reloj().difference(_actividad!);
    return transcurrido.isNegative || transcurrido >= limite;
  }

  Future<void> establecer(String uid, bool mantener) async {
    await cargar();
    _uid = uid;
    _mantener = mantener;
    _actividad = _reloj();
    await _guardar();
  }

  Future<void> autenticar({
    required bool mantener,
    required Future<void> Function() ingresar,
    required String? Function() usuarioActual,
    required Future<void> Function() cerrar,
  }) async {
    final terminado = Completer<void>();
    accesoEnCurso = terminado.future;
    try {
      await ingresar();
      final uid = usuarioActual();
      if (uid == null) throw StateError('No se pudo confirmar la sesion.');
      try {
        await establecer(uid, mantener);
      } catch (_) {
        await cerrar();
        rethrow;
      }
    } finally {
      terminado.complete();
      accesoEnCurso = null;
    }
  }

  void actividad(String uid) {
    if (vencida(uid) || _mantener) return;
    // Limita escrituras durante gestos continuos, sin extender una sesion vencida.
    if (_reloj().difference(_actividad!) < const Duration(seconds: 1)) return;
    _actividad = _reloj();
    unawaited(
      _guardar().catchError((Object _) {
        _actividad = null;
      }),
    );
  }

  Future<void> limpiar() async {
    _uid = null;
    _mantener = false;
    _actividad = null;
    await _guardar();
  }

  Future<void> _guardar() {
    final texto = jsonEncode({
      'uid': _uid,
      'mantener': _mantener,
      'actividad': _actividad?.toIso8601String(),
    });
    final siguiente = _escritura.catchError((Object _) {}).then((_) async {
      if (!await _prefs!.setString(_clave, texto)) {
        throw StateError('No se pudo guardar la preferencia de sesion.');
      }
    });
    _escritura = siguiente;
    return siguiente;
  }

  Future<T> protegerOperacion<T>(Future<T> Function() accion) async {
    _operaciones++;
    try {
      return await accion();
    } finally {
      _operaciones--;
    }
  }
}
