import '../entidades/asistencia.dart';
import '../repositorios/repositorio_asistencias.dart';

// Caso de uso para consultar el historial real del trabajador.
class ObtenerAsistenciasPorUsuario {
  const ObtenerAsistenciasPorUsuario(this._repositorioAsistencias);

  final RepositorioAsistencias _repositorioAsistencias;

  Future<List<Asistencia>> ejecutar(String usuarioId) {
    return _repositorioAsistencias.obtenerAsistenciasPorUsuario(usuarioId);
  }
}
