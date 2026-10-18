import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/presentacion/servicios/exportador_historial.dart';
import '../../../asistencias/presentacion/widgets/resumen_historial_trabajador.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';

/// Instantánea de las jornadas que cumplen los filtros de la ficha.
class InformeAsistenciasTrabajador {
  InformeAsistenciasTrabajador({
    required this.usuario,
    required List<Asistencia> marcaciones,
    this.desde,
    this.hasta,
    this.estado = 'Todos',
  }) {
    final inicio = desde == null
        ? null
        : DateTime(desde!.year, desde!.month, desde!.day);
    final fin = hasta == null
        ? null
        : DateTime(hasta!.year, hasta!.month, hasta!.day + 1);
    if (inicio != null && fin != null && !inicio.isBefore(fin)) {
      throw ArgumentError('El rango de fechas no es válido.');
    }
    dias = agruparHistorialPorDia(
      marcaciones
          .where(
            (m) =>
                m.usuarioId == usuario.id &&
                (inicio == null || !m.fechaHora.isBefore(inicio)) &&
                (fin == null || m.fechaHora.isBefore(fin)),
          )
          .toList(),
    )..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  final Usuario usuario;
  final DateTime? desde, hasta;
  final String estado;
  late final List<ResumenDiaHistorial> dias;
  Duration get tardanzaTotal => dias.fold(
    Duration.zero,
    (suma, dia) => suma + (dia.tardanza ?? Duration.zero),
  );
  static String fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  static String duracion(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  InformeHistorial get informe => InformeHistorial(
    trabajador: usuario.nombreCompleto,
    dias: dias,
    encabezado: 'Reporte de asistencia',
    mostrarSegundos: true,
    incluirTotalTardanza: true,
    archivo:
        'asistencias_${usuario.id}_${dias.isEmpty ? 'sin_registros' : '${dias.first.fecha.year}-${dias.first.fecha.month}-${dias.first.fecha.day}_${dias.last.fecha.year}-${dias.last.fecha.month}-${dias.last.fecha.day}'}',
    datosAdicionales: {
      'Filtro de fechas':
          '${desde == null ? 'Sin límite inicial' : fecha(desde!)} - ${hasta == null ? 'Sin límite final' : fecha(hasta!)}',
      'Filtro de estado': estado,
    },
  );
}
