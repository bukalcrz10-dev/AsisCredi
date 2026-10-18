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
    this.fechaInicioLabores,
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
  final DateTime? fechaInicioLabores;

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
      fechaInicioLabores: usuario.fechaInicioLabores,
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
      fechaInicioLabores: _leerFecha(mapa['fechaInicioLabores']),
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
      fechaInicioLabores: fechaInicioLabores,
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
      if (fechaInicioLabores != null)
        'fechaInicioLabores': fechaInicioLabores!.toIso8601String().substring(
          0,
          10,
        ),
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

  static DateTime? _leerFecha(dynamic valor) {
    if (valor is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) {
      return null;
    }
    final fecha = DateTime.tryParse(valor);
    return fecha != null && fecha.toIso8601String().startsWith(valor)
        ? fecha
        : null;
  }
}
