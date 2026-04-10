import 'tipo_alerta.dart';

// Entidad que representa una incidencia detectada por el sistema.
// Se separa de la asistencia porque no toda alerta equivale a una marcacion valida.
class Alerta {
  const Alerta({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.tipo,
    required this.mensaje,
    required this.fechaHora,
    this.asistenciaId,
    this.atendida = false,
  });

  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final TipoAlerta tipo;
  final String mensaje;
  final DateTime fechaHora;

  // Vincula la alerta con una asistencia cuando exista esa relacion.
  // Esto ayuda a rastrear incidentes desde reportes o auditorias.
  final String? asistenciaId;
  final bool atendida;
}
