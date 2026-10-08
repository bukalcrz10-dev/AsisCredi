import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/resumen_historial_trabajador.dart';
import '../widgets/soporte_panel_trabajador.dart';

/// Instantánea de los días del filtro aplicado.
class InformeHistorial {
  InformeHistorial({
    required this.trabajador,
    required List<ResumenDiaHistorial> dias,
  }) : dias = List.unmodifiable(dias);

  final String trabajador;
  final List<ResumenDiaHistorial> dias;
  bool get jornadaContinua =>
      dias.isNotEmpty && dias.every((d) => d.esJornadaContinua);
  List<String> get columnas => [
    'Fecha',
    'Entrada',
    if (!jornadaContinua) 'Salida mañana',
    if (!jornadaContinua) 'Entrada tarde',
    jornadaContinua ? 'Salida' : 'Salida tarde',
    'Tardanza',
    'T. laborado',
    if (!jornadaContinua) 'Descanso',
    'Salida anticipada',
    'Horario',
  ];

  // Conserva el orden del historial y separa las jornadas con dos y cuatro marcas.
  List<InformeHistorial> get secciones {
    final grupos = <List<ResumenDiaHistorial>>[];
    for (final dia in dias) {
      if (grupos.isEmpty ||
          grupos.last.last.esJornadaContinua != dia.esJornadaContinua) {
        grupos.add([]);
      }
      grupos.last.add(dia);
    }
    return grupos
        .map((grupo) => InformeHistorial(trabajador: trabajador, dias: grupo))
        .toList();
  }

  String get periodo {
    if (dias.isEmpty) return 'Sin registros';
    final fechas = dias.map((d) => d.fecha).toList()..sort();
    return '${formatearFechaPanel(fechas.first)} - ${formatearFechaPanel(fechas.last)}';
  }

  String get nombreArchivo {
    if (dias.isEmpty) return 'asistencias';
    final fechas = dias.map((d) => d.fecha).toList()..sort();
    String fecha(DateTime f) =>
        '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    return 'asistencias_${fecha(fechas.first)}_${fecha(fechas.last)}';
  }

  List<List<String>> get filas => dias.map((dia) {
    String hora(DateTime? fecha) =>
        fecha == null ? '--:--' : formatearHoraAmPmPanel(fecha);
    String duracion(Duration? valor) =>
        valor == null ? '--:--' : formatearDuracionPanel(valor);
    return [
      formatearFechaPanel(dia.fecha),
      hora(dia.entradaManana?.fechaHora),
      if (!jornadaContinua) hora(dia.salidaReceso?.fechaHora),
      if (!jornadaContinua) hora(dia.entradaTarde?.fechaHora),
      hora(dia.salidaFinal?.fechaHora),
      duracion(dia.tardanza),
      duracion(dia.tiempoLaborado),
      if (!jornadaContinua) duracion(dia.descanso),
      duracion(dia.salidaAnticipada),
      dia.etiquetaHorario,
    ];
  }).toList();

  Uint8List generarExcel() {
    final libro = Excel.createExcel();
    final hoja = libro['Asistencias'];
    libro.delete('Sheet1');
    libro.setDefaultSheet('Asistencias');
    void agregar(List<String> valores) =>
        hoja.appendRow(valores.map(TextCellValue.new).toList());
    agregar(['Informe de asistencias']);
    agregar(['Trabajador', trabajador]);
    agregar(['Fechas con registros', periodo]);
    agregar(['Días registrados', dias.length.toString()]);
    for (final seccion in secciones) {
      final filaCabecera = hoja.maxRows;
      agregar(seccion.columnas);
      for (final fila in seccion.filas) {
        agregar(fila);
      }
      for (var columna = 0; columna < seccion.columnas.length; columna++) {
        hoja.setColumnWidth(columna, 21);
        hoja
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columna,
                rowIndex: filaCabecera,
              ),
            )
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#DCE8F2'),
        );
      }
    }
    return Uint8List.fromList(libro.encode()!);
  }

  Future<Uint8List> generarPdf({PdfPageFormat? formato}) async {
    final documento = pw.Document();
    documento.addPage(
      pw.MultiPage(
        pageFormat: formato ?? PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 1000,
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Informe de asistencias',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Trabajador: $trabajador'),
              pw.Text(
                'Fechas con registros: $periodo',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (_) => [
          for (final seccion in secciones) ...[
            pw.TableHelper.fromTextArray(
              headers: seccion.columnas,
              data: seccion.filas,
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
            pw.SizedBox(height: 10),
          ],
          pw.Text(
            'Días registrados: ${dias.length}. --:-- indica un dato no disponible.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    return documento.save();
  }
}
