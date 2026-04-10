import '../repositorios/repositorio_autenticacion.dart';

// Caso de uso para iniciar sesion con correo y contrasena.
// Vive en dominio para mantener la regla de negocio separada de la UI.
class IniciarSesion {
  const IniciarSesion(this._repositorioAutenticacion);

  final RepositorioAutenticacion _repositorioAutenticacion;

  Future<void> ejecutar({
    required String correo,
    required String contrasena,
  }) {
    return _repositorioAutenticacion.iniciarSesion(
      correo: correo,
      contrasena: contrasena,
    );
  }
}
