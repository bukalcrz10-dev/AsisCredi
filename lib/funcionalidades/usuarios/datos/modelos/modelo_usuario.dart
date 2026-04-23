import '../../dominio/entidades/rol_usuario.dart';
import '../../dominio/entidades/usuario.dart';

// Modelo usado para transformar un Usuario a un formato compatible con Firebase.
// Vive en datos porque aqui ya hablamos de mapas y persistencia.
class ModeloUsuario {
  const ModeloUsuario({
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
  final String sedeAsignadaId;
  final String? urlFotoFacial;
  final bool activo;

  factory ModeloUsuario.desdeEntidad(Usuario usuario) {
    return ModeloUsuario(
      id: usuario.id,
      nombreCompleto: usuario.nombreCompleto,
      correo: usuario.correo,
      telefono: usuario.telefono,
      area: usuario.area,
      cargo: usuario.cargo,
      rol: usuario.rol,
      sedeAsignadaId: usuario.sedeAsignadaId,
      urlFotoFacial: usuario.urlFotoFacial,
      activo: usuario.activo,
    );
  }

  factory ModeloUsuario.desdeMapa(Map<String, dynamic> mapa, String id) {
    return ModeloUsuario(
      id: id,
      nombreCompleto: mapa['nombreCompleto'] as String? ?? '',
      correo: mapa['correo'] as String? ?? '',
      telefono: mapa['telefono'] as String? ?? '',
      area: mapa['area'] as String? ?? '',
      cargo: mapa['cargo'] as String? ?? '',
      rol: _rolDesdeTexto(mapa['rol'] as String?),
      sedeAsignadaId: mapa['sedeAsignadaId'] as String? ?? '',
      urlFotoFacial: mapa['urlFotoFacial'] as String?,
      activo: mapa['activo'] as bool? ?? true,
    );
  }

  Usuario aEntidad() {
    return Usuario(
      id: id,
      nombreCompleto: nombreCompleto,
      correo: correo,
      telefono: telefono,
      area: area,
      cargo: cargo,
      rol: rol,
      sedeAsignadaId: sedeAsignadaId,
      urlFotoFacial: urlFotoFacial,
      activo: activo,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'nombreCompleto': nombreCompleto,
      'correo': correo,
      'telefono': telefono,
      'area': area,
      'cargo': cargo,
      'rol': rol.name,
      'sedeAsignadaId': sedeAsignadaId,
      'urlFotoFacial': urlFotoFacial,
      'activo': activo,
    };
  }

  static RolUsuario _rolDesdeTexto(String? valor) {
    switch (valor) {
      case 'administrador':
        return RolUsuario.administrador;
      case 'trabajador':
      default:
        return RolUsuario.trabajador;
    }
  }
}
