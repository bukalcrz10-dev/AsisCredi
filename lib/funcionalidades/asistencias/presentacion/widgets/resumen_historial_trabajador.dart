import '../../dominio/entidades/asistencia.dart';
import '../controladores/controlador_asistencia_auxiliares.dart';

class ResumenDiaHistorial {
  const ResumenDiaHistorial({required this.fecha, required this.marcaciones});

  final DateTime fecha;
  final List<Asistencia> marcaciones;

  Asistencia? get entradaManana => _resumenJornada.manana.entradaMarcada;

  Asistencia? get salidaManana => _resumenJornada.manana.salidaMarcada;

  Asistencia? get entradaTarde => _resumenJornada.tarde.entradaMarcada;

  Asistencia? get salidaTarde => _resumenJornada.tarde.salidaMarcada;

  bool get esJornadaContinua => _resumenJornada.esJornadaContinua;
  bool get esNoLaborable => _resumenJornada.esNoLaborable;
  Asistencia? get salidaReceso => esJornadaContinua ? null : salidaManana;
  Asistencia? get salidaFinal => esJornadaContinua ? salidaManana : salidaTarde;
  String get etiquetaHorario => switch (tipoHorario) {
    TipoHorarioPersonal.asesor => 'Asesor',
    TipoHorarioPersonal.plataforma => 'Auxiliar de operaciones',
    TipoHorarioPersonal.historico => 'Anterior',
  };

  Asistencia? get entrada {
    return entradaManana;
  }

  Asistencia? get salida {
    return salidaTarde ?? salidaManana;
  }

  Duration? get tardanza {
    return _resumenJornada.tardanzaTotal;
  }

  Duration? get tiempoLaborado {
    return _resumenJornada.tiempoLaborado;
  }

  Duration? get descanso {
    return _resumenJornada.descanso;
  }

  TipoHorarioPersonal get tipoHorario => _resumenJornada.tipoHorario;

  Duration get salidaAnticipada => _resumenJornada.salidaAnticipadaTotal;

  bool get completo =>
      !esNoLaborable &&
      _resumenJornada.totalBloquesCompletos == _resumenJornada.tramos.length;

  bool get observado {
    final tardanzaTotal = tardanza;
    return (tardanzaTotal != null && tardanzaTotal > Duration.zero) ||
        salidaAnticipada > Duration.zero;
  }

  ResumenJornadaTrabajador get _resumenJornada =>
      construirResumenJornadaTrabajador(marcaciones, fecha);
}

List<ResumenDiaHistorial> agruparHistorialPorDia(List<Asistencia> asistencias) {
  final agrupado = <String, List<Asistencia>>{};

  for (final asistencia in asistencias) {
    final llave = _soloFechaLlave(asistencia.fechaHora);
    agrupado.putIfAbsent(llave, () => []).add(asistencia);
  }

  final resumenes = <ResumenDiaHistorial>[];
  for (final entry in agrupado.entries) {
    entry.value.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    resumenes.add(
      ResumenDiaHistorial(
        fecha: entry.value.first.fechaHora,
        marcaciones: entry.value,
      ),
    );
  }

  resumenes.sort((a, b) => b.fecha.compareTo(a.fecha));
  return resumenes;
}

String _soloFechaLlave(DateTime fechaHora) {
  final dia = fechaHora.day.toString().padLeft(2, '0');
  final mes = fechaHora.month.toString().padLeft(2, '0');
  final anio = fechaHora.year.toString();
  return '$anio-$mes-$dia';
}
