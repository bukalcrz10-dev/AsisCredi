import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';
import '../../dominio/repositorios/repositorio_evidencia_facial.dart';
import '../fuentes_datos/fuente_datos_evidencia_facial_storage.dart';

// Implementacion del almacenamiento de evidencia facial usando Firebase Storage.
class RepositorioEvidenciaFacialImpl implements RepositorioEvidenciaFacial {
  RepositorioEvidenciaFacialImpl(this._fuenteDatos);

  final FuenteDatosEvidenciaFacialStorage _fuenteDatos;

  @override
  Future<String> subirEvidenciaFacial({
    required String usuarioId,
    required String rutaImagenLocal,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  }) {
    return _fuenteDatos.subirEvidenciaFacial(
      usuarioId: usuarioId,
      rutaImagenLocal: rutaImagenLocal,
      fechaHora: fechaHora,
      tipoMarcacion: tipoMarcacion,
    );
  }
}
