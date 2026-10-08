import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/modulo_asistencia_trabajador.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/resumen_historial_trabajador.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/servicios/exportador_historial.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/regularizacion_jornada.dart';
import 'horarios_personal_test.dart' show marca;
import 'historial_columnas_test.dart' show mostrar;

DateTime sabado(int hora, [int minuto = 0, int segundo = 0]) =>
    DateTime(2026, 10, 10, hora, minuto, segundo);

class _Domingo extends Fake implements ControladorAsistencia {
  @override
  TipoHorarioPersonal get horarioAsignado => TipoHorarioPersonal.plataforma;
  @override
  ResumenJornadaTrabajador get resumenJornadaHoy =>
      construirResumenJornadaTrabajador(
        [],
        DateTime(2026, 10, 11),
        tipoHorario: horarioAsignado,
      );
}

void main() {
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    test('${horario.name}: limites sabado, entrada previa y duplicados', () {
      final ventanas = ventanasPara(horario, fecha: sabado(0));
      expect(ventanas.length, 2);
      final vacio = construirResumenJornadaTrabajador(
        [],
        sabado(0),
        tipoHorario: horario,
      );
      expect(vacio.tramos.length, 1);
      expect(vacio.siguienteTipoMarcacionPara(sabado(7, 59, 59)), isNull);
      expect(
        vacio.siguienteTipoMarcacionPara(sabado(8)),
        TipoMarcacion.entrada,
      );
      expect(
        vacio.siguienteTipoMarcacionPara(sabado(14, 59, 59)),
        TipoMarcacion.entrada,
      );
      expect(vacio.siguienteTipoMarcacionPara(sabado(15)), isNull);
      expect(
        vacio.rechazoMarcacionPara(TipoMarcacion.salida, sabado(15)),
        contains('entrada'),
      );
      final entrada = marca(horario, ventanas[0], sabado(8, 30));
      final abierto = construirResumenJornadaTrabajador([entrada], sabado(0));
      expect(abierto.siguienteTipoMarcacionPara(sabado(14, 59, 59)), isNull);
      expect(
        abierto.siguienteTipoMarcacionPara(sabado(15)),
        TipoMarcacion.salida,
      );
      expect(
        abierto.siguienteTipoMarcacionPara(sabado(16, 0, 59)),
        TipoMarcacion.salida,
      );
      expect(abierto.siguienteTipoMarcacionPara(sabado(16, 1)), isNull);
      final completo = construirResumenJornadaTrabajador([
        entrada,
        marca(horario, ventanas[1], sabado(15)),
      ], sabado(0));
      expect(completo.siguienteTipoMarcacionPara(sabado(15, 30)), isNull);
      expect(completo.tiempoLaborado, const Duration(hours: 6, minutes: 30));
      expect(completo.tardanzaTotal, Duration.zero);
      expect(completo.descanso, isNull);
      expect(completo.totalBloquesCompletos, 1);
      expect(
        mismoProcesoMarcacion(
          sabado(14, 59),
          sabado(15),
          TipoMarcacion.entrada,
          horario,
        ),
        isFalse,
      );
      expect(
        mismoProcesoMarcacion(
          sabado(15),
          sabado(16),
          TipoMarcacion.salida,
          horario,
        ),
        isTrue,
      );
      final tarde = construirResumenJornadaTrabajador([
        marca(horario, ventanas[0], sabado(14, 30)),
      ], sabado(0));
      expect(tarde.manana.entradaMarcada, isNotNull);
      expect(tarde.tarde.entradaMarcada, isNull);
      expect(tarde.tardanzaTotal, const Duration(hours: 6));
      final edicion = RegularizacionJornada([entrada]);
      expect(edicion.campos.length, 2);
    });

    test('${horario.name}: domingo sin ventanas ni penalizaciones', () {
      final domingo = DateTime(2026, 10, 11, 9);
      final resumen = construirResumenJornadaTrabajador(
        [],
        domingo,
        tipoHorario: horario,
      );
      expect(resumen.esNoLaborable, isTrue);
      expect(resumen.tramos, isEmpty);
      expect(resumen.ventanas, isEmpty);
      expect(resumen.siguienteTipoMarcacionPara(domingo), isNull);
      expect(
        resumen.rechazoMarcacionPara(TipoMarcacion.entrada, domingo),
        contains('no laborable'),
      );
      expect(resumen.tardanzaTotal, isNull);
      expect(resumen.salidaAnticipadaTotal, Duration.zero);
      expect(resumen.tiempoLaborado, isNull);
    });

    testWidgets(
      '${horario.name}: sabado en historial y exportacion sin receso',
      (tester) async {
        final ventanas = ventanasPara(horario, fecha: sabado(0));
        final marcas = [
          marca(horario, ventanas[0], sabado(8, 30)),
          marca(horario, ventanas[1], sabado(15)),
        ];
        await mostrar(tester, marcas);
        expect(find.text('Salida mañana'), findsNothing);
        expect(find.text('Entrada tarde'), findsNothing);
        expect(find.text('03:00 PM'), findsOneWidget);
        expect(find.text('06:30'), findsOneWidget);
        final resumen = agruparHistorialPorDia(marcas).single;
        expect(resumen.completo, isTrue);
        expect(resumen.salidaReceso, isNull);
        expect(resumen.salidaFinal!.fechaHora, sabado(15));
        final informe = InformeHistorial(trabajador: 'Prueba', dias: [resumen]);
        expect(informe.filas.single[2], '03:00 PM');
        expect(informe.filas.single[4], '06:30');
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('conserva fines de semana anteriores y jornadas entre semana', () {
    final horario = TipoHorarioPersonal.plataforma;
    final antiguo = construirResumenJornadaTrabajador(
      [],
      DateTime(2026, 10, 3),
      tipoHorario: horario,
    );
    expect(antiguo.esSabado, isFalse);
    expect(antiguo.tramos.length, 2);
    for (var dia = 12; dia <= 16; dia++) {
      expect(ventanasPara(horario, fecha: DateTime(2026, 10, dia)).length, 4);
      expect(
        ventanasPara(
          TipoHorarioPersonal.asesor,
          fecha: DateTime(2026, 10, dia),
        ).length,
        2,
      );
    }
  });

  testWidgets(
    'domingo muestra descanso sin pendientes ni boton ni progreso vacio',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModuloAsistenciaTrabajador(
              controlador: _Domingo(),
              onAbrirProcesoMarcacion: (_) async {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Domingo: día no laborable'), findsOneWidget);
      expect(find.text('Registrarse'), findsNothing);
      expect(find.text('PENDIENTE'), findsNothing);
      expect(find.text('Progreso del dia'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
