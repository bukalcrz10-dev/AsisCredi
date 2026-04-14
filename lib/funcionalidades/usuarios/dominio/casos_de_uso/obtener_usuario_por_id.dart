import '../entidades/usuario.dart';
import '../repositorios/repositorio_usuarios.dart';

// Caso de uso para traer el perfil del usuario desde la fuente de datos.
class ObtenerUsuarioPorId {
  const ObtenerUsuarioPorId(this._repositorioUsuarios);

  final RepositorioUsuarios _repositorioUsuarios;

  Future<Usuario?> ejecutar(String id) {
    return _repositorioUsuarios.obtenerUsuarioPorId(id);
  }
}
