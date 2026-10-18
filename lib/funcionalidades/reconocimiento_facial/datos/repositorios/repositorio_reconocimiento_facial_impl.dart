import '../../dominio/entidades/resultado_validacion_facial.dart';
import '../../dominio/repositorios/repositorio_reconocimiento_facial.dart';
import '../fuentes_datos/fuente_datos_detector_rostro_mlkit.dart';

// Implementacion del repositorio facial usando ML Kit.
// Mantiene concentrada la dependencia externa fuera del dominio.
class RepositorioReconocimientoFacialImpl
    implements RepositorioReconocimientoFacial {
  RepositorioReconocimientoFacialImpl(this._fuenteDatos)
    : _validarSeguro = null;
  RepositorioReconocimientoFacialImpl.seguro(this._validarSeguro)
    : _fuenteDatos = null;

  final FuenteDatosDetectorRostroMlkit? _fuenteDatos;
  final Future<ResultadoValidacionFacial> Function(String)? _validarSeguro;

  @override
  Future<ResultadoValidacionFacial> validarRostroEnImagen({
    required String rutaImagen,
  }) {
    if (_validarSeguro != null) return _validarSeguro(rutaImagen);
    return _fuenteDatos!.validarRostroEnImagen(rutaImagen: rutaImagen);
  }

  Future<void> cerrar() {
    return _fuenteDatos?.cerrar() ?? Future.value();
  }
}
