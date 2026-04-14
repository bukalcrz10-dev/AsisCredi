import '../entidades/usuario.dart';

// Contrato del modulo de usuarios para consultar perfiles del sistema.
// Vive en dominio porque la UI y los casos de uso no deben depender
// directamente de Firestore ni de detalles de infraestructura.
abstract class RepositorioUsuarios {
  Future<Usuario?> obtenerUsuarioPorId(String id);

  Future<void> guardarUsuario(Usuario usuario);
}
