import '../../dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/repositorios/repositorio_reconocimiento_facial.dart';
import '../fuentes_datos/fuente_datos_detector_rostro_mlkit.dart';

// Implementacion del repositorio facial usando ML Kit.
// Mantiene concentrada la dependencia externa fuera del dominio.
class RepositorioReconocimientoFacialImpl
    implements RepositorioReconocimientoFacial {
  RepositorioReconocimientoFacialImpl(this._fuenteDatos);

  final FuenteDatosDetectorRostroMlkit _fuenteDatos;

  @override
  Future<ResultadoValidacionFacial> validarRostroEnImagen({
    required String rutaImagen,
  }) {
    return _fuenteDatos.validarRostroEnImagen(rutaImagen: rutaImagen);
  }

  Future<void> cerrar() {
    return _fuenteDatos.cerrar();
  }
}
