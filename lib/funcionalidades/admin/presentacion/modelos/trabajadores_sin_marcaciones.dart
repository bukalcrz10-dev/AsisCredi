import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';

/// Seguimiento del día consultado, no una declaración de falta o tardanza.
List<Usuario> trabajadoresSinMarcaciones({
  required List<Usuario> usuarios,
  required List<Asistencia> marcaciones,
  required DateTime fecha,
}) {
  if (fecha.weekday == DateTime.sunday) return [];
  final conMarcas = marcaciones
      .where(
        (m) =>
            m.fechaHora.year == fecha.year &&
            m.fechaHora.month == fecha.month &&
            m.fechaHora.day == fecha.day,
      )
      .map((m) => m.usuarioId)
      .toSet();
  final resultado = usuarios
      .where(
        (u) =>
            u.activo &&
            u.rol == RolUsuario.trabajador &&
            !conMarcas.contains(u.id),
      )
      .toList();
  resultado.sort((a, b) {
    final nombre = a.nombreCompleto.toLowerCase().compareTo(
      b.nombreCompleto.toLowerCase(),
    );
    return nombre != 0 ? nombre : a.id.compareTo(b.id);
  });
  return resultado;
}
