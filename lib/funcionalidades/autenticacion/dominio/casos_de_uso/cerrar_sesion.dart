import '../repositorios/repositorio_autenticacion.dart';

// Caso de uso para cerrar la sesion actual.
class CerrarSesion {
  const CerrarSesion(this._repositorioAutenticacion);

  final RepositorioAutenticacion _repositorioAutenticacion;

  Future<void> ejecutar() {
    return _repositorioAutenticacion.cerrarSesion();
  }
}
