import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

// Modelo de datos para la coleccion de asistencias en Firebase.
// Aqui convertimos entre la entidad de negocio y el formato almacenado
// en Firestore, incluyendo Timestamp para fecha y hora.
class ModeloAsistencia {
  const ModeloAsistencia({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.sedeId,
    required this.tipoMarcacion,
    required this.fechaHora,
    required this.latitud,
    required this.longitud,
    required this.dentroDeZona,
    required this.rostroValidado,
    this.observacion,
    this.correoNotificacion,
    this.urlEvidenciaFacial,
    this.notificacionEnviada = false,
  });

  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String sedeId;
  final TipoMarcacion tipoMarcacion;
  final DateTime fechaHora;
  final double latitud;
  final double longitud;
  final bool dentroDeZona;
  final bool rostroValidado;
  final String? observacion;
  final String? correoNotificacion;
  final String? urlEvidenciaFacial;
  final bool notificacionEnviada;

  factory ModeloAsistencia.desdeEntidad(Asistencia asistencia) {
    return ModeloAsistencia(
      id: asistencia.id,
      usuarioId: asistencia.usuarioId,
      nombreUsuario: asistencia.nombreUsuario,
      sedeId: asistencia.sedeId,
      tipoMarcacion: asistencia.tipoMarcacion,
      fechaHora: asistencia.fechaHora,
      latitud: asistencia.latitud,
      longitud: asistencia.longitud,
      dentroDeZona: asistencia.dentroDeZona,
      rostroValidado: asistencia.rostroValidado,
      observacion: asistencia.observacion,
      correoNotificacion: asistencia.correoNotificacion,
      urlEvidenciaFacial: asistencia.urlEvidenciaFacial,
      notificacionEnviada: asistencia.notificacionEnviada,
    );
  }

  factory ModeloAsistencia.desdeMapa(Map<String, dynamic> mapa, String id) {
    final timestamp = mapa['fechaHora'];

    return ModeloAsistencia(
      id: id,
      usuarioId: mapa['usuarioId'] as String? ?? '',
      nombreUsuario: mapa['nombreUsuario'] as String? ?? '',
      sedeId: mapa['sedeId'] as String? ?? '',
      tipoMarcacion: _tipoMarcacionDesdeTexto(mapa['tipoMarcacion'] as String?),
      fechaHora: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      latitud: (mapa['latitud'] as num?)?.toDouble() ?? 0,
      longitud: (mapa['longitud'] as num?)?.toDouble() ?? 0,
      dentroDeZona: mapa['dentroDeZona'] as bool? ?? false,
      rostroValidado: mapa['rostroValidado'] as bool? ?? false,
      observacion: mapa['observacion'] as String?,
      correoNotificacion: mapa['correoNotificacion'] as String?,
      urlEvidenciaFacial: mapa['urlEvidenciaFacial'] as String?,
      notificacionEnviada: mapa['notificacionEnviada'] as bool? ?? false,
    );
  }

  Asistencia aEntidad() {
    return Asistencia(
      id: id,
      usuarioId: usuarioId,
      nombreUsuario: nombreUsuario,
      sedeId: sedeId,
      tipoMarcacion: tipoMarcacion,
      fechaHora: fechaHora,
      latitud: latitud,
      longitud: longitud,
      dentroDeZona: dentroDeZona,
      rostroValidado: rostroValidado,
      observacion: observacion,
      correoNotificacion: correoNotificacion,
      urlEvidenciaFacial: urlEvidenciaFacial,
      notificacionEnviada: notificacionEnviada,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'usuarioId': usuarioId,
      'nombreUsuario': nombreUsuario,
      'sedeId': sedeId,
      'tipoMarcacion': tipoMarcacion.name,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'latitud': latitud,
      'longitud': longitud,
      'dentroDeZona': dentroDeZona,
      'rostroValidado': rostroValidado,
      'observacion': observacion,
      'correoNotificacion': correoNotificacion,
      'urlEvidenciaFacial': urlEvidenciaFacial,
      'notificacionEnviada': notificacionEnviada,
      // Este enlace se guarda ya preparado para poder mostrarlo
      // en historial, reportes o futuros correos automaticos.
      'enlaceMapa': 'https://maps.google.com/?q=$latitud,$longitud',
    };
  }

  static TipoMarcacion _tipoMarcacionDesdeTexto(String? valor) {
    switch (valor) {
      case 'salida':
        return TipoMarcacion.salida;
      case 'entrada':
      default:
        return TipoMarcacion.entrada;
    }
  }
}
