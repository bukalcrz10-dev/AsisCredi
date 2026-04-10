import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dominio/entidades/alerta.dart';
import '../../dominio/entidades/tipo_alerta.dart';

// Modelo de persistencia para alertas en Firebase.
// Su objetivo es almacenar incidentes de forma consistente y legible
// para futuras consultas del panel administrativo.
class ModeloAlerta {
  const ModeloAlerta({
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
  final String? asistenciaId;
  final bool atendida;

  factory ModeloAlerta.desdeEntidad(Alerta alerta) {
    return ModeloAlerta(
      id: alerta.id,
      usuarioId: alerta.usuarioId,
      nombreUsuario: alerta.nombreUsuario,
      tipo: alerta.tipo,
      mensaje: alerta.mensaje,
      fechaHora: alerta.fechaHora,
      asistenciaId: alerta.asistenciaId,
      atendida: alerta.atendida,
    );
  }

  factory ModeloAlerta.desdeMapa(Map<String, dynamic> mapa, String id) {
    final timestamp = mapa['fechaHora'];

    return ModeloAlerta(
      id: id,
      usuarioId: mapa['usuarioId'] as String? ?? '',
      nombreUsuario: mapa['nombreUsuario'] as String? ?? '',
      tipo: _tipoAlertaDesdeTexto(mapa['tipo'] as String?),
      mensaje: mapa['mensaje'] as String? ?? '',
      fechaHora: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      asistenciaId: mapa['asistenciaId'] as String?,
      atendida: mapa['atendida'] as bool? ?? false,
    );
  }

  Alerta aEntidad() {
    return Alerta(
      id: id,
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      tipo: tipo,
      mensaje: mensaje,
      fechaHora: fechaHora,
      asistenciaId: asistenciaId,
      atendida: atendida,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'usuarioId': usuarioId,
      'nombreUsuario': nombreUsuario,
      'tipo': tipo.name,
      'mensaje': mensaje,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'asistenciaId': asistenciaId,
      'atendida': atendida,
    };
  }

  static TipoAlerta _tipoAlertaDesdeTexto(String? valor) {
    switch (valor) {
      case 'fueraDeZona':
        return TipoAlerta.fueraDeZona;
      case 'rostroNoValido':
        return TipoAlerta.rostroNoValido;
      case 'notificacionPendiente':
        return TipoAlerta.notificacionPendiente;
      case 'marcacionRechazada':
      default:
        return TipoAlerta.marcacionRechazada;
    }
  }
}
