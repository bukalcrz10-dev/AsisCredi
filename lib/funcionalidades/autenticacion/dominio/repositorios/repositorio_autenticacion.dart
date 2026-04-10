// Contrato del modulo de autenticacion.
// Define las operaciones que el sistema necesita para iniciar y cerrar sesion
// sin acoplar la interfaz directamente a Firebase Auth.
abstract class RepositorioAutenticacion {
  Stream<bool> sesionIniciada();

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  Future<void> cerrarSesion();
}
