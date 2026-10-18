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
    this.encabezado = 'Informe de asistencias',
    this.datosAdicionales = const {},
    this.archivo,
    this.mostrarSegundos = false,
    this.incluirTotalTardanza = false,
  }) : dias = List.unmodifiable(dias);

  final String trabajador;
  final List<ResumenDiaHistorial> dias;
  final String encabezado;
  final Map<String, String> datosAdicionales;
  final String? archivo;
  final bool mostrarSegundos;
  final bool incluirTotalTardanza;

  String get totalTardanzaTexto {
    final total = dias.fold(
      Duration.zero,
      (suma, dia) => suma + (dia.tardanza ?? Duration.zero),
    );
    return '${formatearDuracionPanel(total)}${mostrarSegundos ? ':${(total.inSeconds % 60).toString().padLeft(2, '0')}' : ''}';
  }

  List<String> _filaTotal(InformeHistorial seccion) {
    final fila = List.filled(seccion.columnas.length, '');
    fila[0] = 'TOTAL TARDANZA';
    fila[seccion.columnas.indexOf('Tardanza')] = totalTardanzaTexto;
    return fila;
  }

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
        .map(
          (grupo) => InformeHistorial(
            trabajador: trabajador,
            dias: grupo,
            mostrarSegundos: mostrarSegundos,
          ),
        )
        .toList();
  }

  String get periodo {
    if (dias.isEmpty) return 'Sin registros';
    final fechas = dias.map((d) => d.fecha).toList()..sort();
    return '${formatearFechaPanel(fechas.first)} - ${formatearFechaPanel(fechas.last)}';
  }

  String get nombreArchivo {
    if (archivo != null) return archivo!;
    if (dias.isEmpty) return 'asistencias';
    final fechas = dias.map((d) => d.fecha).toList()..sort();
    String fecha(DateTime f) =>
        '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
    return 'asistencias_${fecha(fechas.first)}_${fecha(fechas.last)}';
  }

  List<List<String>> get filas => dias.map((dia) {
    String hora(DateTime? fecha) =>
        fecha == null ? '--:--' : formatearHoraAmPmPanel(fecha);
    String duracion(Duration? valor) => valor == null
        ? '--:--'
        : '${formatearDuracionPanel(valor)}${mostrarSegundos ? ':${(valor.inSeconds % 60).toString().padLeft(2, '0')}' : ''}';
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
    if (datosAdicionales.isNotEmpty) {
      for (var columna = 0; columna < 7; columna++) {
        hoja.setColumnWidth(columna, 21);
      }
    }
    void agregar(List<String> valores) =>
        hoja.appendRow(valores.map(TextCellValue.new).toList());
    agregar([encabezado]);
    agregar(['Trabajador', trabajador]);
    for (final dato in datosAdicionales.entries) {
      final fila = hoja.maxRows;
      agregar([dato.key, dato.value]);
      hoja.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: fila),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: fila),
      );
      hoja.setRowHeight(fila, 32);
      for (final columna in [0, 1]) {
        hoja
            .cell(
              CellIndex.indexByColumnRow(columnIndex: columna, rowIndex: fila),
            )
            .cellStyle = CellStyle(
          bold: columna == 0,
          textWrapping: TextWrapping.WrapText,
        );
      }
    }
    agregar(['Fechas con registros', periodo]);
    agregar(['Días registrados', dias.length.toString()]);
    final seccionesInforme = secciones;
    for (final seccion in seccionesInforme) {
      final filaCabecera = hoja.maxRows;
      agregar(seccion.columnas);
      for (final fila in seccion.filas) {
        agregar(fila);
      }
      if (incluirTotalTardanza && identical(seccion, seccionesInforme.last)) {
        final filaTotal = hoja.maxRows;
        agregar(_filaTotal(seccion));
        for (var columna = 0; columna < seccion.columnas.length; columna++) {
          hoja
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: columna,
                  rowIndex: filaTotal,
                ),
              )
              .cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#DCEEE9'),
          );
        }
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
    final seccionesInforme = secciones;
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
                encabezado,
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Trabajador: $trabajador'),
              for (final dato in datosAdicionales.entries)
                pw.Text(
                  '${dato.key}: ${dato.value}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
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
          for (final seccion in seccionesInforme) ...[
            pw.TableHelper.fromTextArray(
              headers: seccion.columnas,
              data: [
                ...seccion.filas,
                if (incluirTotalTardanza &&
                    identical(seccion, seccionesInforme.last))
                  _filaTotal(seccion),
              ],
              textStyleBuilder: (_, valor, fila) => pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    incluirTotalTardanza &&
                        identical(seccion, seccionesInforme.last) &&
                        fila == seccion.dias.length + 1
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
              cellDecoration: (_, valor, fila) =>
                  incluirTotalTardanza &&
                      identical(seccion, seccionesInforme.last) &&
                      fila == seccion.dias.length + 1
                  ? const pw.BoxDecoration(color: PdfColors.green50)
                  : const pw.BoxDecoration(),
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
