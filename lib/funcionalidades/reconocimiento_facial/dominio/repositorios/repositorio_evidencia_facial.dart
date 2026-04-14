import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';

// Contrato para guardar la evidencia facial capturada.
// Permite cambiar el backend de almacenamiento sin tocar la UI ni el dominio de asistencias.
abstract class RepositorioEvidenciaFacial {
  Future<String> subirEvidenciaFacial({
    required String usuarioId,
    required String rutaImagenLocal,
    required DateTime fechaHora,
    required TipoMarcacion tipoMarcacion,
  });
}
