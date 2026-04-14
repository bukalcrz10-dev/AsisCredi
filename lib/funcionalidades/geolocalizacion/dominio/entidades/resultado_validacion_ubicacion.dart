// Resultado de la validacion geografica del trabajador.
// Resume el estado del GPS, la distancia calculada y si se encuentra
// dentro del radio permitido de la sede asignada.
class ResultadoValidacionUbicacion {
  const ResultadoValidacionUbicacion({
    required this.servicioHabilitado,
    required this.permisoConcedido,
    required this.latitudActual,
    required this.longitudActual,
    required this.distanciaMetros,
    required this.dentroDeZona,
    required this.mensajeEstado,
  });

  final bool servicioHabilitado;
  final bool permisoConcedido;
  final double? latitudActual;
  final double? longitudActual;
  final double? distanciaMetros;
  final bool dentroDeZona;
  final String mensajeEstado;
}
