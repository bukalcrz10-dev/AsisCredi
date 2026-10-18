import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';

/// Las notas documentan el registro; el estado depende de la jornada y sus validaciones.
class EvaluacionAsistenciaAdmin {
  EvaluacionAsistenciaAdmin(List<Asistencia> marcaciones, DateTime fecha)
    : resumen = construirResumenJornadaTrabajador(marcaciones, fecha),
      todasDentroZona = marcaciones.every((m) => m.dentroDeZona),
      todasConRostro = marcaciones.every((m) => m.rostroValidado),
      notas = marcaciones
          .map((m) => m.observacion?.trim() ?? '')
          .where((nota) => nota.isNotEmpty)
          .toList();

  final ResumenJornadaTrabajador resumen;
  final bool todasDentroZona;
  final bool todasConRostro;
  final List<String> notas;

  List<String> get incidencias => [
    if ((resumen.tardanzaTotal ?? Duration.zero) > Duration.zero)
      'La jornada registra tardanza.',
    if (resumen.salidaAnticipadaTotal > Duration.zero)
      'La jornada registra salida anticipada.',
    if (!todasDentroZona) 'Hay marcaciones sin ubicación validada.',
    if (!todasConRostro) 'Hay marcaciones sin rostro validado.',
    if (!resumen.esNoLaborable && resumen.mensajeBloqueoJornada != null)
      resumen.mensajeBloqueoJornada!,
  ];

  String get estado {
    if (resumen.esNoLaborable) return 'No laborable';
    if (!resumen.tramos.every((tramo) => tramo.completo)) return 'Pendiente';
    return incidencias.isEmpty ? 'Correcta' : 'Observada';
  }

  String get detalle => [
    switch (estado) {
      'Correcta' => 'La jornada está completa y no presenta incidencias.',
      'Pendiente' => 'Faltan marcaciones para completar la jornada.',
      'No laborable' => 'No corresponde registrar asistencia en esta jornada.',
      _ => 'La jornada completa requiere revisión.',
    },
    ...incidencias,
    ...notas,
  ].join(' | ');
}
