import 'rol_usuario.dart';

// Entidad principal del modulo de usuarios.
// Esta clase representa al usuario dentro del negocio, sin depender
// de Firebase ni de detalles de almacenamiento.
class Usuario {
  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    this.telefono = '',
    this.area = '',
    this.cargo = '',
    required this.rol,
    required this.sedeAsignadaId,
    this.urlFotoFacial,
    this.activo = true,
  });

  final String id;
  final String nombreCompleto;
  final String correo;
  final String telefono;
  final String area;
  final String cargo;
  final RolUsuario rol;

  // Cada trabajador o administrador puede estar asociado a una sede.
  // Esta relacion luego permitira validar desde donde puede marcar asistencia.
  final String sedeAsignadaId;

  // Este campo deja lista la base para el registro facial del usuario.
  // Mas adelante podria apuntar a una foto, plantilla o evidencia en Storage.
  final String? urlFotoFacial;
  final bool activo;
}
