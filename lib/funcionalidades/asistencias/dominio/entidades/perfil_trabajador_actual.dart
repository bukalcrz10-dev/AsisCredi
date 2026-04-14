import '../../../sedes/dominio/entidades/sede.dart';

// Entidad adaptada para la pantalla del trabajador.
// Reune en un solo objeto la informacion del usuario autenticado
// y la sede necesaria para mostrar el panel principal de asistencias.
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
    required this.radioPermitidoMetros,
    this.nombreFallback,
    this.sede,
  });

  final String usuarioId;
  final String nombreCompleto;
  final String rolOCargo;
  final String sedeId;
  final String nombreSede;
  final String correoNotificacion;
  final double latitudSede;
  final double longitudSede;
  final double radioPermitidoMetros;
  final String? nombreFallback;
  final Sede? sede;

  // Perfil temporal usado solo como respaldo visual si aun no existe
  // el documento completo del usuario en Firestore.
  factory PerfilTrabajadorActual.desdeAutenticacion({
    required String usuarioId,
    String? nombreCompleto,
    String? correo,
  }) {
    return PerfilTrabajadorActual(
      usuarioId: usuarioId,
      nombreCompleto:
          (nombreCompleto != null && nombreCompleto.trim().isNotEmpty)
              ? nombreCompleto.trim()
              : 'Trabajador',
      rolOCargo: 'Trabajador',
      sedeId: '',
      nombreSede: 'Pendiente',
      correoNotificacion: correo ?? '',
      latitudSede: 0,
      longitudSede: 0,
      radioPermitidoMetros: 0,
      nombreFallback: nombreCompleto,
    );
  }
}
