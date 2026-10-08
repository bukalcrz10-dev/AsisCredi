import 'package:flutter/material.dart';

import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

// Modos de consulta del historial personal del trabajador.
// Permiten alternar entre el dia actual, un rango concreto o todo el historial.
enum FiltroHistorial { hoy, rango, todo }

enum BloqueJornada { manana, tarde }

// historico conserva la interpretación de registros anteriores al cambio.
enum TipoHorarioPersonal { historico, asesor, plataforma }

TipoHorarioPersonal? horarioDesdeCargo(String cargo) {
  final valor = cargo.trim().toLowerCase();
  if (valor == 'asesor' || valor == 'asesora') {
    return TipoHorarioPersonal.asesor;
  }
  if (valor == 'plataforma') return TipoHorarioPersonal.plataforma;
  return null;
}

TipoHorarioPersonal? horarioDesdeTexto(String? texto) {
  for (final horario in TipoHorarioPersonal.values) {
    if (horario.name == texto) return horario;
  }
  return null;
}

class VentanaMarcacion {
  const VentanaMarcacion(
    this.bloque,
    this.tipo,
    this.inicioMinutos,
    this.finMinutos, [
    this.nombre,
  ]);
  final BloqueJornada bloque;
  final TipoMarcacion tipo;
  final int inicioMinutos;
  final int finMinutos;
  final String? nombre;

  bool contiene(DateTime ahora) {
    final minutos = ahora.hour * 60 + ahora.minute;
    return minutos >= inicioMinutos && minutos < finMinutos;
  }

  String get etiqueta =>
      nombre ??
      'Registrar ${tipo.name} ${bloque == BloqueJornada.manana ? 'mañana' : 'tarde'}';
}

// El fin es exclusivo: 13:31 incluye todo el minuto 13:30.
const ventanasMarcacion = [
  VentanaMarcacion(BloqueJornada.manana, TipoMarcacion.entrada, 480, 770),
  VentanaMarcacion(BloqueJornada.manana, TipoMarcacion.salida, 780, 811),
  VentanaMarcacion(BloqueJornada.tarde, TipoMarcacion.entrada, 870, 1101),
  VentanaMarcacion(BloqueJornada.tarde, TipoMarcacion.salida, 1110, 1171),
];

// Vigencia del calendario nuevo: no reinterpreta las jornadas anteriores.
final inicioCalendarioSemanal = DateTime(2026, 10, 8);
bool aplicaCalendarioSemanal(TipoHorarioPersonal horario, DateTime fecha) =>
    horario != TipoHorarioPersonal.historico &&
    !fecha.isBefore(inicioCalendarioSemanal);
bool esSabadoContinuo(TipoHorarioPersonal horario, DateTime fecha) =>
    aplicaCalendarioSemanal(horario, fecha) &&
    fecha.weekday == DateTime.saturday;
bool esDomingoNoLaborable(TipoHorarioPersonal horario, DateTime fecha) =>
    aplicaCalendarioSemanal(horario, fecha) && fecha.weekday == DateTime.sunday;

List<VentanaMarcacion> ventanasPara(
  TipoHorarioPersonal horario, {
  DateTime? fecha,
}) {
  if (fecha != null) {
    if (esDomingoNoLaborable(horario, fecha)) return const [];
    if (esSabadoContinuo(horario, fecha)) {
      return const [
        VentanaMarcacion(
          BloqueJornada.manana,
          TipoMarcacion.entrada,
          480,
          900,
          'Registrar entrada',
        ),
        VentanaMarcacion(
          BloqueJornada.manana,
          TipoMarcacion.salida,
          900,
          961,
          'Registrar salida final',
        ),
      ];
    }
  }
  return switch (horario) {
    TipoHorarioPersonal.historico => ventanasMarcacion,
    TipoHorarioPersonal.asesor => const [
      VentanaMarcacion(
        BloqueJornada.manana,
        TipoMarcacion.entrada,
        480,
        1100,
        'Registrar entrada',
      ),
      VentanaMarcacion(
        BloqueJornada.manana,
        TipoMarcacion.salida,
        1110,
        1171,
        'Registrar salida final',
      ),
    ],
    TipoHorarioPersonal.plataforma => const [
      VentanaMarcacion(
        BloqueJornada.manana,
        TipoMarcacion.entrada,
        480,
        780,
        'Registrar entrada mañana',
      ),
      VentanaMarcacion(
        BloqueJornada.manana,
        TipoMarcacion.salida,
        780,
        900,
        'Registrar salida a receso',
      ),
      VentanaMarcacion(
        BloqueJornada.tarde,
        TipoMarcacion.entrada,
        890,
        1100,
        'Registrar entrada tarde',
      ),
      VentanaMarcacion(
        BloqueJornada.tarde,
        TipoMarcacion.salida,
        1110,
        1171,
        'Registrar salida final',
      ),
    ],
  };
}

bool mismoProcesoMarcacion(
  DateTime inicio,
  DateTime actual,
  TipoMarcacion tipo,
  TipoHorarioPersonal horario,
) {
  if (inicio.year != actual.year ||
      inicio.month != actual.month ||
      inicio.day != actual.day) {
    return false;
  }
  return ventanasPara(
    horario,
    fecha: actual,
  ).any((v) => v.tipo == tipo && v.contiene(inicio) && v.contiene(actual));
}

bool mismoTurnoMarcacion(DateTime inicio, DateTime actual) =>
    inicio.year == actual.year &&
    inicio.month == actual.month &&
    inicio.day == actual.day &&
    (inicio.hour < 14) == (actual.hour < 14);

class TramoJornadaLaboral {
  const TramoJornadaLaboral({
    required this.bloque,
    required this.orden,
    required this.entradaProgramada,
    required this.salidaProgramada,
    required this.entradaMarcada,
    required this.salidaMarcada,
    this.tolerancia = const Duration(minutes: 10),
  });

  final BloqueJornada bloque;
  final int orden;
  final DateTime entradaProgramada;
  final DateTime salidaProgramada;
  final Asistencia? entradaMarcada;
  final Asistencia? salidaMarcada;

  final Duration tolerancia;

  Duration get salidaAnticipada {
    final salida = salidaMarcada;
    return salida != null && salida.fechaHora.isBefore(salidaProgramada)
        ? salidaProgramada.difference(salida.fechaHora)
        : Duration.zero;
  }

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

  bool get dentroDeTolerancia => tardanza <= tolerancia;
}

class ResumenJornadaTrabajador {
  const ResumenJornadaTrabajador({
    required this.fecha,
    required this.manana,
    required this.tarde,
    this.tipoHorario = TipoHorarioPersonal.historico,
  });

  final TipoHorarioPersonal tipoHorario;
  final DateTime fecha;
  final TramoJornadaLaboral manana;
  final TramoJornadaLaboral tarde;

  bool get esSabado => esSabadoContinuo(tipoHorario, fecha);
  bool get esNoLaborable => esDomingoNoLaborable(tipoHorario, fecha);
  bool get esJornadaContinua =>
      tipoHorario == TipoHorarioPersonal.asesor || esSabado;
  List<TramoJornadaLaboral> get tramos => esNoLaborable
      ? []
      : esJornadaContinua
      ? [manana]
      : [manana, tarde];

  List<VentanaMarcacion> get ventanas =>
      ventanasPara(tipoHorario, fecha: fecha);
  Duration get salidaAnticipadaTotal => tramos.fold(
    Duration.zero,
    (total, tramo) => total + tramo.salidaAnticipada,
  );

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
        var duracion = salida.fechaHora.difference(entrada.fechaHora);
        if (tipoHorario == TipoHorarioPersonal.plataforma && !esSabado) {
          final inicioReceso = DateTime(fecha.year, fecha.month, fecha.day, 13);
          final finReceso = DateTime(fecha.year, fecha.month, fecha.day, 15);
          final inicio = entrada.fechaHora.isAfter(inicioReceso)
              ? entrada.fechaHora
              : inicioReceso;
          final fin = salida.fechaHora.isBefore(finReceso)
              ? salida.fechaHora
              : finReceso;
          if (fin.isAfter(inicio)) duracion -= fin.difference(inicio);
        }
        total += duracion;
      }
    }

    if (total == Duration.zero) {
      return null;
    }

    return total;
  }

  Duration? get descanso {
    if (esJornadaContinua || esNoLaborable) return null;
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

  TramoJornadaLaboral tramoPara(BloqueJornada bloque) =>
      bloque == BloqueJornada.manana ? manana : tarde;

  String? rechazoMarcacionPara(TipoMarcacion tipo, DateTime ahora) {
    if (ahora.year != fecha.year ||
        ahora.month != fecha.month ||
        ahora.day != fecha.day) {
      return 'La jornada cambio. Actualiza la pantalla antes de marcar.';
    }
    if (esNoLaborable) {
      return 'Domingo: día no laborable. No corresponde registrar asistencia.';
    }
    final candidatas = ventanas.where(
      (v) => v.tipo == tipo && v.contiene(ahora),
    );
    if (candidatas.isEmpty) {
      return 'Fuera del horario permitido para registrar ${tipo.name}.';
    }
    final ventana = candidatas.first;
    final tramo = tramoPara(ventana.bloque);
    final existente = tipo == TipoMarcacion.entrada
        ? tramo.entradaMarcada
        : tramo.salidaMarcada;
    if (existente != null) {
      return 'Ya registraste esta ${tipo.name} del turno. No puedes repetirla hoy.';
    }
    if (tipo == TipoMarcacion.salida &&
        (tramo.entradaMarcada == null ||
            tramo.entradaMarcada!.fechaHora.isAfter(ahora))) {
      return 'Primero debes registrar la entrada de este mismo turno.';
    }
    if (tipo == TipoMarcacion.entrada && tramo.salidaMarcada != null) {
      return 'Este turno tiene una salida sin entrada. Solicita revision administrativa.';
    }
    if (tipoHorario == TipoHorarioPersonal.plataforma &&
        ventana.bloque == BloqueJornada.tarde &&
        tipo == TipoMarcacion.entrada &&
        manana.entradaMarcada != null &&
        manana.salidaMarcada == null) {
      return 'Falta registrar la salida a receso. Solicita revisión si el horario ya terminó.';
    }
    if (tipoHorario == TipoHorarioPersonal.plataforma &&
        ventana.bloque == BloqueJornada.tarde &&
        tipo == TipoMarcacion.entrada &&
        manana.salidaMarcada != null &&
        manana.salidaMarcada!.fechaHora.isAfter(ahora)) {
      return 'La entrada tarde debe ser posterior a la salida a receso.';
    }
    return null;
  }

  VentanaMarcacion? siguienteVentanaPara(DateTime ahora) {
    for (final ventana in ventanas) {
      if (ventana.contiene(ahora) &&
          rechazoMarcacionPara(ventana.tipo, ahora) == null) {
        return ventana;
      }
    }
    return null;
  }

  TipoMarcacion? siguienteTipoMarcacionPara(DateTime ahora) =>
      siguienteVentanaPara(ahora)?.tipo;
  String? siguienteEtiquetaAccionPara(DateTime ahora) =>
      siguienteVentanaPara(ahora)?.etiqueta;
  TipoMarcacion? get siguienteTipoMarcacion =>
      siguienteTipoMarcacionPara(_ahora);
  String? get siguienteEtiquetaAccion => siguienteEtiquetaAccionPara(_ahora);
  bool get siguienteAccionHabilitada => siguienteTipoMarcacion != null;

  DateTime? get proximaHoraHabilitada {
    for (final ventana in ventanas) {
      final tramo = tramoPara(ventana.bloque);
      final pendiente = ventana.tipo == TipoMarcacion.entrada
          ? tramo.entradaMarcada == null && tramo.salidaMarcada == null
          : tramo.entradaMarcada != null && tramo.salidaMarcada == null;
      if (pendiente) {
        return DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          ventana.inicioMinutos ~/ 60,
          ventana.inicioMinutos % 60,
        );
      }
    }
    return null;
  }

  String? get mensajeEsperaSiguienteAccion => siguienteAccionHabilitada
      ? null
      : 'No hay una marcacion disponible en este horario.';

  String? get mensajeBloqueoJornada => esNoLaborable
      ? 'Domingo: día no laborable. No corresponde registrar asistencia.'
      : tramos.any((t) => t.salidaMarcada != null && t.entradaMarcada == null)
      ? 'Hay un turno con salida sin entrada. Solicita revision administrativa.'
      : null;
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

ResumenJornadaTrabajador construirResumenJornadaTrabajador(
  List<Asistencia> marcaciones,
  DateTime fecha, {
  TipoHorarioPersonal? tipoHorario,
}) {
  final marcacionesOrdenadas = [...marcaciones]
    ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

  final guardados = marcacionesOrdenadas
      .map((m) => horarioDesdeTexto(m.tipoHorario))
      .whereType<TipoHorarioPersonal>();
  final horario = guardados.isNotEmpty
      ? guardados.first
      : (tipoHorario ?? TipoHorarioPersonal.historico);
  final sabado = esSabadoContinuo(horario, fecha);
  final continua = horario == TipoHorarioPersonal.asesor || sabado;
  Asistencia? entradaManana;
  Asistencia? salidaManana;
  Asistencia? entradaTarde;
  Asistencia? salidaTarde;

  for (final marcacion in marcacionesOrdenadas) {
    final minutos = marcacion.fechaHora.hour * 60 + marcacion.fechaHora.minute;

    if (marcacion.tipoMarcacion == TipoMarcacion.entrada) {
      if (continua ||
          marcacion.bloqueJornada == 'manana' ||
          (marcacion.bloqueJornada == null && minutos < 13 * 60)) {
        entradaManana ??= marcacion;
      } else {
        entradaTarde ??= marcacion;
      }
    } else {
      if (continua ||
          marcacion.bloqueJornada == 'manana' ||
          (marcacion.bloqueJornada == null &&
              minutos <
                  (horario == TipoHorarioPersonal.plataforma ? 15 : 14) * 60)) {
        salidaManana ??= marcacion;
      } else {
        salidaTarde ??= marcacion;
      }
    }
  }

  return ResumenJornadaTrabajador(
    fecha: fecha,
    tipoHorario: horario,
    manana: TramoJornadaLaboral(
      bloque: BloqueJornada.manana,
      orden: 1,
      entradaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 8, 30),
      salidaProgramada: DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        sabado
            ? 15
            : horario == TipoHorarioPersonal.asesor
            ? 18
            : 13,
        !sabado && horario == TipoHorarioPersonal.asesor ? 30 : 0,
      ),
      tolerancia: horario == TipoHorarioPersonal.historico
          ? const Duration(minutes: 10)
          : Duration.zero,
      entradaMarcada: entradaManana,
      salidaMarcada: salidaManana,
    ),
    tarde: TramoJornadaLaboral(
      bloque: BloqueJornada.tarde,
      orden: 2,
      entradaProgramada: DateTime(fecha.year, fecha.month, fecha.day, 15, 0),
      salidaProgramada: DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horario == TipoHorarioPersonal.historico ? 19 : 18,
        horario == TipoHorarioPersonal.historico ? 0 : 30,
      ),
      tolerancia: horario == TipoHorarioPersonal.historico
          ? const Duration(minutes: 10)
          : Duration.zero,
      entradaMarcada: entradaTarde,
      salidaMarcada: salidaTarde,
    ),
  );
}
