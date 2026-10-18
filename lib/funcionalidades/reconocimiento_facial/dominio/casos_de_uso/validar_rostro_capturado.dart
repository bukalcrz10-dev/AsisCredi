import '../entidades/resultado_validacion_facial.dart';
import '../repositorios/repositorio_reconocimiento_facial.dart';

// Caso de uso que recibe la foto capturada y determina
// si existe al menos un rostro antes de marcar asistencia.
class ValidarRostroCapturado {
  const ValidarRostroCapturado(this._repositorioReconocimientoFacial);

  final RepositorioReconocimientoFacial _repositorioReconocimientoFacial;

  Future<ResultadoValidacionFacial> ejecutar({required String rutaImagen}) {
    return _repositorioReconocimientoFacial.validarRostroEnImagen(
      rutaImagen: rutaImagen,
    );
  }
}
