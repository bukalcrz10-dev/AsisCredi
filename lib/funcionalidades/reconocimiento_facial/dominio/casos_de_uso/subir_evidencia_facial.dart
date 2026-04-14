import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';
import '../repositorios/repositorio_evidencia_facial.dart';

// Caso de uso para subir la foto facial asociada a una marcacion.
// Se ejecuta justo antes de guardar la asistencia para dejar
// el registro y la evidencia enlazados desde el primer momento.
class SubirEvidenciaFacial {
  const SubirEvidenciaFacial(this._repositorioEvidenciaFacial);

  final RepositorioEvidenciaFacial _repositorioEvidenciaFacial;

  Future<String> ejecutar({
    required String usuarioId,
    required String rutaImagenLocal,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  }) {
    return _repositorioEvidenciaFacial.subirEvidenciaFacial(
      usuarioId: usuarioId,
      rutaImagenLocal: rutaImagenLocal,
      fechaHora: fechaHora,
      tipoMarcacion: tipoMarcacion,
    );
  }
}
