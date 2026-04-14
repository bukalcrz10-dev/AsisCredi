import 'tipo_marcacion.dart';

// Entidad principal del sistema de asistencias.
// Resume el resultado de una marcacion y deja trazabilidad suficiente
// para reportes, auditoria y futuras notificaciones por correo.
class Asistencia {
  const Asistencia({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.sedeId,
    required this.tipoMarcacion,
    required this.fechaHora,
    required this.latitud,
    required this.longitud,
    required this.dentroDeZona,
    required this.rostroValidado,
    this.observacion,
    this.correoNotificacion,
    this.urlEvidenciaFacial,
    this.notificacionEnviada = false,
  });

  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String sedeId;
  final TipoMarcacion tipoMarcacion;
  final DateTime fechaHora;
  final double latitud;
  final double longitud;

  // Estas validaciones quedan dentro del registro porque luego
  // serviran para auditar por que una marcacion fue aceptada o rechazada.
  final bool dentroDeZona;
  final bool rostroValidado;
  final String? observacion;

  // Este campo prepara la integracion futura con el envio de correos
  // que mencionaste para informar al administrador cada nueva marcacion.
  final String? correoNotificacion;
  // URL de la evidencia facial almacenada en Firebase Storage.
  // Queda asociada a la asistencia para auditoria o panel administrativo.
  final String? urlEvidenciaFacial;
  final bool notificacionEnviada;
}
