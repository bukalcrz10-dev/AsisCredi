import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';

class ResumenDiaHistorial {
  const ResumenDiaHistorial({
    required this.fecha,
    required this.marcaciones,
  });

  final DateTime fecha;
  final List<Asistencia> marcaciones;

  Asistencia? get entrada {
    for (final marcacion in marcaciones) {
      if (marcacion.tipoMarcacion == TipoMarcacion.entrada) {
        return marcacion;
      }
    }
    return null;
  }

  Asistencia? get salida {
    for (final marcacion in marcaciones.reversed) {
      if (marcacion.tipoMarcacion == TipoMarcacion.salida) {
        return marcacion;
      }
    }
    return null;
  }

  Duration? get tardanza {
    final primeraEntrada = entrada;
    if (primeraEntrada == null) {
      return null;
    }

    final horaProgramada = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      8,
      0,
    );

    if (!primeraEntrada.fechaHora.isAfter(horaProgramada)) {
      return Duration.zero;
    }

    return primeraEntrada.fechaHora.difference(horaProgramada);
  }

  Duration? get tiempoLaborado {
    Duration total = Duration.zero;
    Asistencia? entradaAbierta;

    for (final marcacion in marcaciones) {
      if (marcacion.tipoMarcacion == TipoMarcacion.entrada) {
        entradaAbierta = marcacion;
      } else if (marcacion.tipoMarcacion == TipoMarcacion.salida &&
          entradaAbierta != null &&
          !marcacion.fechaHora.isBefore(entradaAbierta.fechaHora)) {
        total += marcacion.fechaHora.difference(entradaAbierta.fechaHora);
        entradaAbierta = null;
      }
    }

    if (total == Duration.zero) {
      return null;
    }

    return total;
  }

  Duration? get descanso {
    Duration total = Duration.zero;
    Asistencia? ultimaSalida;

    for (final marcacion in marcaciones) {
      if (marcacion.tipoMarcacion == TipoMarcacion.salida) {
        ultimaSalida = marcacion;
      } else if (marcacion.tipoMarcacion == TipoMarcacion.entrada &&
          ultimaSalida != null &&
          marcacion.fechaHora.isAfter(ultimaSalida.fechaHora)) {
        total += marcacion.fechaHora.difference(ultimaSalida.fechaHora);
        ultimaSalida = null;
      }
    }

    if (total == Duration.zero) {
      return null;
    }

    return total;
  }
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
