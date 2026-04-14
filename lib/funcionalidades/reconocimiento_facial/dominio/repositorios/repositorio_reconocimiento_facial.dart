import '../entidades/resultado_validacion_facial.dart';

// Contrato del modulo facial.
// Aisla la deteccion de rostros para que la pantalla y el controlador
// no dependan directamente del plugin de ML Kit.
abstract class RepositorioReconocimientoFacial {
  Future<ResultadoValidacionFacial> validarRostroEnImagen({
    required String rutaImagen,
  });
}
