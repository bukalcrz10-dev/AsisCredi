import 'package:flutter/material.dart';

import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

// Modos de consulta del historial personal del trabajador.
// Permiten alternar entre el dia actual, un rango concreto o todo el historial.
enum FiltroHistorial {
  hoy,
  rango,
  todo,
}

String formatearFechaControlAsistencia(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  return '$dia/$mes/$anio';
}

String formatearHoraControlAsistencia(DateTime fechaHora) {
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  final segundo = fechaHora.second.toString().padLeft(2, '0');
  return '$hora:$minuto:$segundo';
}

List<Asistencia> filtrarMarcacionesPorDia(
  List<Asistencia> historial,
  DateTime fecha,
) {
  return historial.where((asistencia) {
    final fechaAsistencia = asistencia.fechaHora;
    return fechaAsistencia.year == fecha.year &&
        fechaAsistencia.month == fecha.month &&
        fechaAsistencia.day == fecha.day;
  }).toList();
}

List<Asistencia> filtrarMarcacionesPorRango(
  List<Asistencia> historial,
  DateTimeRange? rango,
) {
  if (rango == null) {
    return List<Asistencia>.unmodifiable(historial);
  }

  final inicio = DateTime(rango.start.year, rango.start.month, rango.start.day);
  final fin = DateTime(
    rango.end.year,
    rango.end.month,
    rango.end.day,
    23,
    59,
    59,
    999,
  );

  return historial.where((asistencia) {
    final fecha = asistencia.fechaHora;
    return !fecha.isBefore(inicio) && !fecha.isAfter(fin);
  }).toList();
}

Asistencia? obtenerUltimaMarcacionPorTipo(
  List<Asistencia> historial,
  TipoMarcacion tipoMarcacion,
) {
  for (final asistencia in historial) {
    if (asistencia.tipoMarcacion == tipoMarcacion) {
      return asistencia;
    }
  }
  return null;
}
