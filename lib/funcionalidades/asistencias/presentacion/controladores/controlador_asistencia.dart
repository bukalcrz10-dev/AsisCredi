import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

// Perfil del trabajador mostrado en pantalla.
// Esta clase adapta la informacion del usuario autenticado a la vista de asistencias.
class PerfilTrabajadorActual {
  const PerfilTrabajadorActual({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.rolOCargo,
    required this.sedeId,
    required this.nombreSede,
    required this.correoNotificacion,
    required this.latitudSede,
    required this.longitudSede,
  });

  final String usuarioId;
  final String nombreCompleto;
  final String rolOCargo;
  final String sedeId;
  final String nombreSede;
  final String correoNotificacion;
  final double latitudSede;
  final double longitudSede;

  // Constructor auxiliar para crear un perfil temporal a partir
  // del usuario autenticado mientras aun no leemos su ficha completa desde Firestore.
  factory PerfilTrabajadorActual.desdeUsuarioAutenticado({
    required String usuarioId,
    required String? nombreCompleto,
    required String? correo,
  }) {
    return PerfilTrabajadorActual(
      usuarioId: usuarioId,
      nombreCompleto: (nombreCompleto != null && nombreCompleto.trim().isNotEmpty)
          ? nombreCompleto.trim()
          : 'Trabajador',
      rolOCargo: 'Trabajador',
      sedeId: 'sede_principal',
      nombreSede: 'Sede Principal',
      correoNotificacion: correo ?? '',
      latitudSede: -12.057341,
      longitudSede: -75.289446,
    );
  }

  // Constructor auxiliar para reusar la entidad Usuario del dominio.
  factory PerfilTrabajadorActual.desdeEntidadUsuario(Usuario usuario) {
    return PerfilTrabajadorActual(
      usuarioId: usuario.id,
      nombreCompleto: usuario.nombreCompleto,
      rolOCargo: usuario.rol == RolUsuario.administrador
          ? 'Administrador'
          : 'Trabajador',
      sedeId: usuario.sedeAsignadaId,
      nombreSede: 'Sede asignada',
      correoNotificacion: usuario.correo,
      latitudSede: -12.057341,
      longitudSede: -75.289446,
    );
  }
}

// Controlador principal de la pantalla del trabajador.
// Maneja el reloj, la marcacion automatica y un historial local basico
// para que la experiencia ya se parezca al flujo real del usuario final.
class ControladorAsistencia extends ChangeNotifier {
  ControladorAsistencia({
    required RegistrarAsistencia registrarAsistencia,
    required this.perfilActual,
  }) : _registrarAsistencia = registrarAsistencia {
    _iniciarReloj();
  }

  final RegistrarAsistencia _registrarAsistencia;
  final PerfilTrabajadorActual perfilActual;
  final List<Asistencia> _historialReciente = [];

  Timer? _temporizador;
  DateTime fechaHoraActual = DateTime.now();
  bool guardando = false;
  String? mensajeEstado;
  String? ultimoIdRegistrado;

  // Estas banderas siguen simuladas hasta integrar GPS y biometria reales.
  bool get dentroDeZona => true;
  bool get rostroValidado => true;

  List<Asistencia> get historialReciente =>
      List<Asistencia>.unmodifiable(_historialReciente);

  Asistencia? get ultimaMarcacion =>
      _historialReciente.isEmpty ? null : _historialReciente.first;

  Asistencia? get ultimaEntrada {
    for (final asistencia in _historialReciente) {
      if (asistencia.tipoMarcacion == TipoMarcacion.entrada) {
        return asistencia;
      }
    }
    return null;
  }

  Asistencia? get ultimaSalida {
    for (final asistencia in _historialReciente) {
      if (asistencia.tipoMarcacion == TipoMarcacion.salida) {
        return asistencia;
      }
    }
    return null;
  }

  void _iniciarReloj() {
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      fechaHoraActual = DateTime.now();
      notifyListeners();
    });
  }

  Future<void> registrarMarcacion(TipoMarcacion tipoMarcacion) async {
    guardando = true;
    mensajeEstado = null;
    notifyListeners();

    try {
      final asistencia = Asistencia(
        id: '',
        usuarioId: perfilActual.usuarioId,
        nombreUsuario: perfilActual.nombreCompleto,
        sedeId: perfilActual.sedeId,
        tipoMarcacion: tipoMarcacion,
        fechaHora: DateTime.now(),
        latitud: perfilActual.latitudSede,
        longitud: perfilActual.longitudSede,
        dentroDeZona: dentroDeZona,
        rostroValidado: rostroValidado,
        observacion: 'Marcacion generada desde la pantalla del trabajador.',
        correoNotificacion: perfilActual.correoNotificacion,
      );

      final idGenerado = await _registrarAsistencia.ejecutar(asistencia);

      final asistenciaRegistrada = Asistencia(
        id: idGenerado,
        usuarioId: asistencia.usuarioId,
        nombreUsuario: asistencia.nombreUsuario,
        sedeId: asistencia.sedeId,
        tipoMarcacion: asistencia.tipoMarcacion,
        fechaHora: asistencia.fechaHora,
        latitud: asistencia.latitud,
        longitud: asistencia.longitud,
        dentroDeZona: asistencia.dentroDeZona,
        rostroValidado: asistencia.rostroValidado,
        observacion: asistencia.observacion,
        correoNotificacion: asistencia.correoNotificacion,
        notificacionEnviada: asistencia.notificacionEnviada,
      );

      _historialReciente.insert(0, asistenciaRegistrada);
      if (_historialReciente.length > 5) {
        _historialReciente.removeLast();
      }

      ultimoIdRegistrado = idGenerado;
      mensajeEstado =
          'Se registro la ${tipoMarcacion.name} correctamente a las ${_formatearHora(asistencia.fechaHora)}.';
    } catch (_) {
      mensajeEstado =
          'No se pudo registrar la asistencia en Firebase. Revisa la configuracion del proyecto.';
    } finally {
      guardando = false;
      notifyListeners();
    }
  }

  String _formatearHora(DateTime fechaHora) {
    final hora = fechaHora.hour.toString().padLeft(2, '0');
    final minuto = fechaHora.minute.toString().padLeft(2, '0');
    final segundo = fechaHora.second.toString().padLeft(2, '0');
    return '$hora:$minuto:$segundo';
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
