import '../entidades/sede.dart';
import '../repositorios/repositorio_sedes.dart';

// Caso de uso para consultar la sede asignada al usuario.
class ObtenerSedePorId {
  const ObtenerSedePorId(this._repositorioSedes);

  final RepositorioSedes _repositorioSedes;

  Future<Sede?> ejecutar(String id) {
    return _repositorioSedes.obtenerSedePorId(id);
  }
}
