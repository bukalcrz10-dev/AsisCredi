import '../../../sedes/dominio/casos_de_uso/obtener_sede_por_id.dart';
import '../../../sedes/dominio/entidades/sede.dart';
import '../../../usuarios/dominio/casos_de_uso/obtener_usuario_por_id.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../entidades/perfil_trabajador_actual.dart';

// Caso de uso que une la informacion del usuario y su sede
// para construir el perfil real que necesita la pantalla del trabajador.
class ObtenerPerfilTrabajadorActual {
  const ObtenerPerfilTrabajadorActual({
    required ObtenerUsuarioPorId obtenerUsuarioPorId,
    required ObtenerSedePorId obtenerSedePorId,
  })  : _obtenerUsuarioPorId = obtenerUsuarioPorId,
        _obtenerSedePorId = obtenerSedePorId;

  final ObtenerUsuarioPorId _obtenerUsuarioPorId;
  final ObtenerSedePorId _obtenerSedePorId;

  static const _sedePrincipalConGuion = 'sede-principal';
  static const _sedePrincipalConGuionBajo = 'sede_principal';

  Future<PerfilTrabajadorActual?> ejecutar({
    required String usuarioId,
    String? nombreFallback,
    String? correoFallback,
  }) async {
    final usuario = await _obtenerUsuarioPorId.ejecutar(usuarioId);

    if (usuario == null) {
      return null;
    }

    final sede = await _obtenerSedeConCompatibilidad(usuario.sedeAsignadaId);

    final sedeIdNormalizado = _normalizarSedeId(usuario.sedeAsignadaId);

    return PerfilTrabajadorActual(
      usuarioId: usuario.id,
      nombreCompleto: usuario.nombreCompleto,
      rolOCargo: _rolATexto(usuario),
      sedeId: sedeIdNormalizado,
      nombreSede: sede?.nombre ?? 'Sede no encontrada',
      correoNotificacion:
          usuario.correo.isNotEmpty ? usuario.correo : (correoFallback ?? ''),
      latitudSede: sede?.latitud ?? 0,
      longitudSede: sede?.longitud ?? 0,
      radioPermitidoMetros: sede?.radioPermitidoMetros ?? 0,
      nombreFallback: nombreFallback,
      sede: sede,
    );
  }

  Future<Sede?> _obtenerSedeConCompatibilidad(String sedeIdOriginal) async {
    final sedeIdNormalizado = _normalizarSedeId(sedeIdOriginal);

    final sedePrincipal = await _obtenerSedePorId.ejecutar(sedeIdNormalizado);
    if (sedePrincipal != null) {
      return sedePrincipal;
    }

    if (sedeIdNormalizado == _sedePrincipalConGuionBajo) {
      return _obtenerSedePorId.ejecutar(_sedePrincipalConGuion);
    }

    return null;
  }

  String _normalizarSedeId(String sedeIdOriginal) {
    final sedeId = sedeIdOriginal.trim();
    if (sedeId == _sedePrincipalConGuion ||
        sedeId == _sedePrincipalConGuionBajo) {
      return _sedePrincipalConGuionBajo;
    }

    return sedeId;
  }

  String _rolATexto(Usuario usuario) {
    if (usuario.cargo.trim().isNotEmpty) {
      return usuario.cargo;
    }

    return usuario.rol == RolUsuario.administrador
        ? 'Administrador'
        : 'Trabajador';
  }
}
