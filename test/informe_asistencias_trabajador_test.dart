import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/informe_asistencias_trabajador.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/exportacion_asistencias_trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/usuarios/datos/modelos/modelo_usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;
import 'horarios_personal_test.dart' show marca;

const usuario = Usuario(
  id: 'u',
  nombreCompleto: 'Ana Pérez',
  correo: 'ana@example.com',
  rol: RolUsuario.trabajador,
  sedeAsignadaId: 's',
);

void main() {
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    test('total al final bajo la columna de tardanza para ${horario.name}', () {
      final reporte = InformeAsistenciasTrabajador(
        usuario: usuario,
        marcaciones: fixtures.jornada(horario, retraso: 15),
      ).informe;
      final filas = Excel.decodeBytes(
        reporte.generarExcel(),
      )['Asistencias'].rows;
      final indice = reporte.columnas.indexOf('Tardanza');
      expect(filas.last.first?.value.toString(), 'TOTAL TARDANZA');
      expect(filas.last[indice]?.value.toString(), '00:15:00');
      expect(filas.last[indice]?.cellStyle?.isBold, isTrue);
    });
  }
  test('exporta todo lo mostrado sin exigir inicio de labores ni un mes', () {
    final informe = InformeAsistenciasTrabajador(
      usuario: usuario,
      marcaciones: [
        ...fixtures.jornada(TipoHorarioPersonal.asesor, dia: 0, retraso: 5),
        ...fixtures.jornada(TipoHorarioPersonal.asesor, dia: 9, retraso: 15),
      ],
    );
    expect(informe.dias.length, 2);
    expect(informe.dias.first.fecha.month, 9);
    expect(informe.tardanzaTotal, const Duration(minutes: 20));
    expect(
      informe.informe.datosAdicionales['Filtro de fechas'],
      'Sin límite inicial - Sin límite final',
    );
  });

  test(
    'rango inclusivo, una sola fecha y límites abiertos conservan el alcance por persona',
    () {
      final marcas = [
        for (final dia in [8, 9, 10])
          ...fixtures.jornada(
            TipoHorarioPersonal.asesor,
            dia: dia,
            retraso: 10,
          ),
        marca(
          TipoHorarioPersonal.asesor,
          ventanasPara(TipoHorarioPersonal.asesor).first,
          DateTime(2026, 10, 9, 11),
        ),
      ];
      final unico = InformeAsistenciasTrabajador(
        usuario: usuario,
        marcaciones: marcas,
        desde: DateTime(2026, 10, 9),
        hasta: DateTime(2026, 10, 9),
      );
      expect(unico.dias.single.fecha.day, 9);
      expect(unico.tardanzaTotal.inMinutes, 10);
      expect(
        InformeAsistenciasTrabajador(
          usuario: usuario,
          marcaciones: marcas,
          desde: DateTime(2026, 10, 9),
        ).dias.length,
        2,
      );
      expect(
        InformeAsistenciasTrabajador(
          usuario: usuario,
          marcaciones: marcas,
          hasta: DateTime(2026, 10, 9),
        ).dias.length,
        2,
      );
      expect(
        () => InformeAsistenciasTrabajador(
          usuario: usuario,
          marcaciones: marcas,
          desde: DateTime(2026, 10, 10),
          hasta: DateTime(2026, 10, 8),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'las filas suministradas por el filtro de estado determinan el total',
    () {
      final informe = InformeAsistenciasTrabajador(
        usuario: usuario,
        estado: 'Observada',
        marcaciones: fixtures.jornada(
          TipoHorarioPersonal.plataforma,
          retraso: 15,
        ),
      );
      expect(informe.informe.datosAdicionales['Filtro de estado'], 'Observada');
      expect(informe.tardanzaTotal.inMinutes, 15);
      expect(
        informe.informe.columnas,
        containsAll(['Salida mañana', 'Entrada tarde']),
      );
      final sabado = InformeAsistenciasTrabajador(
        usuario: usuario,
        marcaciones: fixtures.jornada(TipoHorarioPersonal.plataforma, dia: 10),
      );
      expect(sabado.informe.columnas, isNot(contains('Entrada tarde')));
    },
  );

  test('mantiene segundos y duraciones acumuladas mayores de un día', () {
    final reporte = InformeAsistenciasTrabajador(
      usuario: ModeloUsuario.desdeMapa(
        ModeloUsuario.desdeEntidad(usuario).aMapa(),
        'u1',
      ).aEntidad(),
      marcaciones: [
        for (final dia in [9, 10])
          marca(
            TipoHorarioPersonal.asesor,
            ventanasPara(TipoHorarioPersonal.asesor).first,
            DateTime(2026, 10, dia, 8, 30, 40),
          ),
      ],
    );
    expect(reporte.tardanzaTotal, const Duration(seconds: 80));
    expect(
      InformeAsistenciasTrabajador.duracion(reporte.tardanzaTotal),
      '00:01:20',
    );
    expect(reporte.informe.secciones.first.filas.first[3], '00:00:40');
    expect(
      InformeAsistenciasTrabajador.duracion(
        const Duration(hours: 35, minutes: 8),
      ),
      '35:08:00',
    );
  });

  testWidgets(
    'Exportar permite elegir formato sin preguntar mes ni inicio de labores',
    (tester) async {
      final informe = InformeAsistenciasTrabajador(
        usuario: usuario,
        marcaciones: fixtures.jornada(TipoHorarioPersonal.asesor),
      ).informe;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportacionAsistenciasTrabajadorAdmin(informe: informe),
          ),
        ),
      );
      await tester.tap(find.text('Exportar'));
      await tester.pumpAndSettle();
      expect(find.text('Exportar Excel'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Exportar mes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sin filas mostradas la exportación queda deshabilitada', (
    tester,
  ) async {
    final vacio = InformeAsistenciasTrabajador(
      usuario: usuario,
      marcaciones: [],
    ).informe;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportacionAsistenciasTrabajadorAdmin(informe: vacio),
        ),
      ),
    );
    expect(
      tester
          .widget<PopupMenuButton<bool>>(find.byType(PopupMenuButton<bool>))
          .enabled,
      isFalse,
    );
  });

  test('Excel y PDF contienen rango y total de las filas mostradas', () async {
    final reporte = InformeAsistenciasTrabajador(
      usuario: usuario,
      desde: DateTime(2026, 10, 8),
      hasta: DateTime(2026, 10, 9),
      marcaciones: [
        ...fixtures.jornada(TipoHorarioPersonal.asesor, dia: 8, retraso: 10),
        ...fixtures.jornada(
          TipoHorarioPersonal.plataforma,
          dia: 9,
          retraso: 15,
        ),
      ],
    ).informe;
    final xlsx = reporte.generarExcel();
    final celdas = Excel.decodeBytes(xlsx)['Asistencias'].rows
        .expand((fila) => fila)
        .map((c) => c?.value.toString());
    expect(
      celdas,
      containsAll([
        '00:25:00',
        'TOTAL TARDANZA',
        '08/10/2026 - 09/10/2026',
        'Salida mañana',
      ]),
    );
    final filas = Excel.decodeBytes(xlsx)['Asistencias'].rows;
    final totales = filas
        .where((fila) => fila.first?.value.toString() == 'TOTAL TARDANZA')
        .toList();
    expect(totales, hasLength(1));
    expect(filas.last.first?.value.toString(), 'TOTAL TARDANZA');
    expect(filas.last[5]?.value.toString(), '00:25:00');
    expect(reporte.datosAdicionales.keys, [
      'Filtro de fechas',
      'Filtro de estado',
    ]);
    final pdf = await reporte.generarPdf();
    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
    final salida = Directory('.dart_tool/verificacion_informes')
      ..createSync(recursive: true);
    File('${salida.path}/rango.pdf').writeAsBytesSync(pdf);
    File('${salida.path}/rango.xlsx').writeAsBytesSync(xlsx);
  });
}
