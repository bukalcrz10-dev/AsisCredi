// Entidad de negocio para las sedes autorizadas.
// La sede es clave para la validacion geografica de las asistencias.
class Sede {
  const Sede({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.radioPermitidoMetros,
    this.descripcion,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final double latitud;
  final double longitud;
  final double radioPermitidoMetros;
  final String? descripcion;
  final bool activa;
}
