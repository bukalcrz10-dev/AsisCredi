import '../../../sedes/dominio/entidades/sede.dart';
import '../../../sedes/dominio/repositorios/repositorio_sedes.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../../../usuarios/dominio/repositorios/repositorio_usuarios.dart';

// Caso de uso temporal para sembrar datos minimos de prueba en Firestore.
// Sirve para no depender de la consola de Firebase durante las primeras pruebas.
class CrearPerfilTrabajadorDemo {
  const CrearPerfilTrabajadorDemo({
    required RepositorioUsuarios repositorioUsuarios,
    required RepositorioSedes repositorioSedes,
  })  : _repositorioUsuarios = repositorioUsuarios,
        _repositorioSedes = repositorioSedes;

  final RepositorioUsuarios _repositorioUsuarios;
  final RepositorioSedes _repositorioSedes;

  Future<void> ejecutar({
    required String usuarioId,
    required String nombreCompleto,
    required String correo,
  }) async {
    const sedeDemo = Sede(
      id: 'sede_principal',
      nombre: 'Sede Principal',
      latitud: -12.057341,
      longitud: -75.289446,
      radioPermitidoMetros: 100,
      descripcion: 'Sede creada automaticamente para pruebas iniciales.',
      activa: true,
    );

    final usuarioDemo = Usuario(
      id: usuarioId,
      nombreCompleto: nombreCompleto,
      correo: correo,
      rol: RolUsuario.trabajador,
      sedeAsignadaId: sedeDemo.id,
      activo: true,
    );

    // Primero garantizamos la sede para que la referencia del usuario
    // siempre apunte a un documento existente.
    await _repositorioSedes.guardarSede(sedeDemo);
    await _repositorioUsuarios.guardarUsuario(usuarioDemo);
  }
}
