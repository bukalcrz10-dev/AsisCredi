// Resultado de la validacion facial de la marcacion.
// Resume si se logro abrir la camara, si se detecto un rostro
// y deja mensajes claros para la pantalla del trabajador.
class ResultadoValidacionFacial {
  const ResultadoValidacionFacial({
    required this.permisoCamaraConcedido,
    required this.rostroDetectado,
    required this.cantidadRostros,
    required this.rutaImagenCapturada,
    required this.mensajeEstado,
  });

  final bool permisoCamaraConcedido;
  final bool rostroDetectado;
  final int cantidadRostros;
  final String? rutaImagenCapturada;
  final String mensajeEstado;
}
