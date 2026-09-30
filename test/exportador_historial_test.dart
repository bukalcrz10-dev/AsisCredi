import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/servicios/exportador_historial.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/resumen_historial_trabajador.dart';
import 'horarios_marcacion_test.dart' show marca;

void main() {
  final dias = agruparHistorialPorDia([
    marca(TipoMarcacion.entrada, 8, 30),
    marca(TipoMarcacion.salida, 13, 0),
    marca(TipoMarcacion.entrada, 15, 0),
    marca(TipoMarcacion.salida, 19, 0),
  ]);
  final informe = InformeHistorial(trabajador: 'María Muñoz', dias: dias);

  test(
    'Excel válido conserva cuatro marcas, duraciones y nombre como texto',
    () {
      final libro = Excel.decodeBytes(informe.generarExcel());
      final hoja = libro['Asistencias'];
      expect(libro.tables.keys, ['Asistencias']);
      expect(hoja.rows.length, 6);
      expect(hoja.rows[1][1]!.value, TextCellValue('María Muñoz'));
      expect(
        hoja.rows[5].map((c) => c!.value.toString()).toList(),
        informe.filas.single,
      );
      expect(
        informe.filas.single.sublist(1, 5).every((v) => v != '--:--'),
        isTrue,
      );
      expect(informe.filas.single[6], '08:30');
      final formula = InformeHistorial(trabajador: '=1+1', dias: dias);
      expect(
        Excel.decodeBytes(
          formula.generarExcel(),
        )['Asistencias'].rows[1][1]!.value,
        isA<TextCellValue>(),
      );
    },
  );

  test('Solo exporta días recibidos y conserva huecos en turno incompleto', () {
    final parcial = InformeHistorial(
      trabajador: 'Ana',
      dias: agruparHistorialPorDia([marca(TipoMarcacion.entrada, 15, 0)]),
    );
    expect(parcial.filas.length, 1);
    expect(parcial.filas.single[1], '--:--');
    expect(parcial.filas.single[3], isNot('--:--'));
    expect(parcial.filas.single[4], '--:--');
    expect(parcial.nombreArchivo, 'asistencias_2026-09-25_2026-09-25');
  });

  test(
    'Genera PDF y Excel de muestra y PDF paginado para historial extenso',
    () async {
      final bytes = await informe.generarPdf();
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      final salida = Directory('.dart_tool/verificacion_informes')
        ..createSync(recursive: true);
      File('${salida.path}/historial.pdf').writeAsBytesSync(bytes);
      File(
        '${salida.path}/historial.xlsx',
      ).writeAsBytesSync(informe.generarExcel());
      final largo = InformeHistorial(
        trabajador: 'María Muñoz',
        dias: List.generate(
          150,
          (i) => ResumenDiaHistorial(
            fecha: dias.first.fecha.add(Duration(days: i)),
            marcaciones: dias.first.marcaciones,
          ),
        ),
      );
      final pdfLargo = await largo.generarPdf();
      expect(pdfLargo.length, greaterThan(bytes.length));
      File('${salida.path}/historial_extenso.pdf').writeAsBytesSync(pdfLargo);
    },
  );
}
