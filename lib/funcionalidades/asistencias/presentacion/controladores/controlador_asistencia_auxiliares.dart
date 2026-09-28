import 'package:flutter/material.dart';

import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

// Modos de consulta del historial personal del trabajador.
// Permiten alternar entre el dia actual, un rango concreto o todo el historial.
enum FiltroHistorial { hoy, rango, todo }

enum BloqueJornada { manana, tarde }

class TramoJornadaLaboral {
  const TramoJornadaLaboral({
    required this.bloque,
    required this.orden,
    required this.entradaProgramada,
    required this.salidaProgramada,
    required this.entradaMarcada,
    required this.salidaMarcada,
  });

  final BloqueJornada bloque;
  final int orden;
  final DateTime entradaProgramada;
  final DateTime salidaProgramada;
  final Asistencia? entradaMarcada;
  final Asistencia? salidaMarcada;

  bool get completo => entradaMarcada != null && salidaMarcada != null;
  bool get tieneAlgo => entradaMarcada != null || salidaMarcada != null;
  bool get pendiente => !completo;

  Duration get tardanza {
    final entrada = entradaMarcada;
    if (entrada == null || !entrada.fechaHora.isAfter(entradaProgramada)) {
      return Duration.zero;
    }

    return entrada.fechaHora.difference(entradaProgramada);
  }

  bool get dentroDeTolerancia => tardanza <= _toleranciaInstitucional;
}

class ResumenJornadaTrabajador {
  const ResumenJornadaTrabajador({
    required this.fecha,
    required this.manana,
    required this.tarde,
  });

  final DateTime fecha;
  final TramoJornadaLaboral manana;
  final TramoJornadaLaboral tarde;

  List<TramoJornadaLaboral> get tramos => [manana, tarde];

  int get totalBloquesCompletos =>
      tramos.where((tramo) => tramo.completo).length;

  int get totalMarcacionesRegistradas => tramos.fold<int>(
    0,
    (total, tramo) =>
        total +
        (tramo.entradaMarcada != null ? 1 : 0) +
        (tramo.salidaMarcada != null ? 1 : 0),
  );

  Duration? get tardanzaTotal {
    Duration total = Duration.zero;
    var tieneMarcacion = false;

    for (final tramo in tramos) {
      if (tramo.entradaMarcada != null) {
        total += tramo.tardanza;
        tieneMarcacion = true;
      }
    }

    if (!tieneMarcacion) {
      return null;
    }

    return total;
  }

  Duration? get tiempoLaborado {
    Duration total = Duration.zero;

    for (final tramo in tramos) {
      final entrada = tramo.entradaMarcada;
      final salida = tramo.salidaMarcada;
      if (entrada != null &&
          salida != null &&
          !salida.fechaHora.isBefore(entrada.fechaHora)) {
        total += salida.fechaHora.difference(entrada.fechaHora);
      }
    }

    if (total == Duration.zero) {
      return null;
    }

    return total;
  }

  Duration? get descanso {
    final salidaManana = manana.salidaMarcada;
    final entradaTarde = tarde.entradaMarcada;

    if (salidaManana == null ||
        entradaTarde == null ||
        !entradaTarde.fechaHora.isAfter(salidaManana.fechaHora)) {
      return null;
    }

    return entradaTarde.fechaHora.difference(salidaManana.fechaHora);
  }

  DateTime get _ahora => DateTime.now();

  DateTime? get proximaHoraHabilitada {
    if (mensajeBloqueoJornada != null) {
      return null;
    }

    if (manana.entradaMarcada == null) {
      return manana.entradaProgramada.subtract(const Duration(minutes: 30));
    }

    if (manana.salidaMarcada != null && tarde.entradaMarcada == null) {
      return tarde.entradaProgramada.subtract(const Duration(minutes: 30));
    }

    if (tarde.entradaMarcada != null && tarde.salidaMarcada == null) {
      return tarde.salidaProgramada.subtract(const Duration(minutes: 30));
    }

    if (manana.entradaMarcada != null && manana.salidaMarcada == null) {
      return manana.salidaProgramada.subtract(const Duration(minutes: 10));
    }

    return null;
  }

  bool get siguienteAccionHabilitada {
    final horaHabilitada = proximaHoraHabilitada;
    if (horaHabilitada == null) {
      return true;
    }

    return !_ahora.isBefore(horaHabilitada);
  }

  String? get mensajeEsperaSiguienteAccion {
    if (mensajeBloqueoJornada != null) {
      return null;
    }

    final horaHabilitada = proximaHoraHabilitada;
    if (horaHabilitada == null || siguienteAccionHabilitada) {
      return null;
    }

    if (manana.entradaMarcada == null) {
      return 'La entrada de la manana se habilitara a las 8:00 AM.';
    }

    if (manana.salidaMarcada != null && tarde.entradaMarcada == null) {
      return 'La entrada del segundo bloque se habilitara 30 minutos antes de las 3:00 PM.';
    }

    if (manana.entradaMarcada != null && manana.salidaMarcada == null) {
      return 'La salida del primer bloque se habilitara 10 minutos antes de la 1:00 PM.';
    }

    if (tarde.entradaMarcada != null && tarde.salidaMarcada == null) {
      return 'La salida del segundo bloque se habilitara 30 minutos antes de las 7:00 PM.';
    }

    return null;
  }

  String? get mensajeBloqueoJornada {
    if (tarde.entradaMarcada != null &&
        manana.entradaMarcada == null &&
        tarde.salidaMarcada != null) {
      return 'La jornada de hoy tiene una entrada de la tarde registrada antes de completar la entrada de la manana. Ya no se puede seguir marcando hasta revisar el orden.';
    }

    if (tarde.entradaMarcada != null &&
        manana.salidaMarcada == null &&
        tarde.salidaMarcada != null) {
      return 'La jornada de hoy tiene la entrada de la tarde registrada, pero falta la salida de la manana. La secuencia debe revisarse antes de continuar.';
    }

    if (tarde.salidaMarcada != null && tarde.entradaMarcada == null) {
      return 'La jornada de hoy tiene una salida de la tarde sin entrada previa del mismo bloque. La secuencia debe revisarse antes de continuar.';
    }

    return null;
  }

  TipoMarcacion? get siguienteTipoMarcacion {
    if (mensajeBloqueoJornada != null || !siguienteAccionHabilitada) {
      return null;
    }
    if (manana.entradaMarcada == null) return TipoMarcacion.entrada;
    if (manana.salidaMarcada == null) return TipoMarcacion.salida;
    if (tarde.entradaMarcada == null) return TipoMarcacion.entrada;
    if (tarde.salidaMarcada == null) return TipoMarcacion.salida;
    return null;
  }

  String? get siguienteEtiquetaAccion {
    if (mensajeBloqueoJornada != null || !siguienteAccionHabilitada) {
      return null;
    }
    if (manana.entradaMarcada == null) return 'Registrar entrada';
    if (manana.salidaMarcada == null) return 'Registrar salida';
    if (tarde.entradaMarcada == null) return 'Registrar entrada';
    if (tarde.salidaMarcada == null) return 'Registrar salida';
    return null;
  }
}

const Duration _toleranciaInstitucional = Duration(minutes: 10);

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

ResumenJornadaTrabajador construirResumenJornadaTrabajador(
  List<Asistencia> marcaciones,
  DateTime fecha,
) {
  final marcacionesOrdenadas = [...marcaciones]
    ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

  Asistencia? entradaManana;
  Asistencia? salidaManana;
  Asistencia? entradaTarde;
  Asistencia? salidaTarde;

  for (final marcacion in marcacionesOrdenadas) {
    final minutos = marcacion.fechaHora.hour * 60 + marcacion.fechaHora.minute;

    if (marcacion.tipoMarcacion == TipoMarcacion.entrada) {
      if (minutos < 13 * 60) {
        entradaManana ??= marcacion;
      } else {
        entradaTarde ??= marcacion;
      }
    } else {
      if (minutos < 14 * 60) {
        salidaManana ??= marcacion;
      } else {
        salidaTarde ??= marcacion;
      }
    }
  }

  return ResumenJornadaTrabajador(
    fecha: fecha,
    manana: TramoJornadaLaboral(
      bloque: BloqueJornada.manana,
      orden: 1,
      entradaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 8, 30),
      salidaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 13, 0),
      entradaMarcada: entradaManana,
      salidaMarcada: salidaManana,
    ),
    tarde: TramoJornadaLaboral(
      bloque: BloqueJornada.tarde,
      orden: 2,
      entradaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 15, 0),
      salidaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 19, 0),
      entradaMarcada: entradaTarde,
      salidaMarcada: salidaTarde,
    ),
  );
}
