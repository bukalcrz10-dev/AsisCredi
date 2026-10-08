import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/modulo_historial_trabajador.dart';
import 'horarios_personal_test.dart' show marca;

class _Controlador extends Fake implements ControladorAsistencia {
  _Controlador(this.historialFiltrado);
  @override
  final List<Asistencia> historialFiltrado;
  @override
  bool get cargandoHistorial => false;
  @override
  DateTime? get fechaInicioHistorialSeleccionada => null;
  @override
  DateTime? get fechaFinHistorialSeleccionada => null;
}

List<Asistencia> jornada(TipoHorarioPersonal horario, int dia) {
  final ventanas = ventanasPara(horario);
  final horas = horario == TipoHorarioPersonal.asesor ? [8, 18] : [8, 13, 15, 18];
  return [for (var i = 0; i < ventanas.length; i++)
    marca(horario, ventanas[i], DateTime(2026, 10, dia, horas[i],
      horas[i] == 8 || horas[i] == 18 ? 30 : 0))];
}

Future<void> mostrar(WidgetTester tester, List<Asistencia> marcas) =>
  tester.pumpWidget(MaterialApp(home: Scaffold(body: ModuloHistorialTrabajador(
    controlador: _Controlador(marcas),
    onSeleccionarFechaInicio: () async {},
    onSeleccionarFechaFin: () async {}, onBuscarRango: () async {},
  ))));

void main() {
  testWidgets('asesor solo muestra entrada mañana y salida tarde sin huecos de receso', (tester) async {
    await mostrar(tester, jornada(TipoHorarioPersonal.asesor, 7));
    expect(find.text('Entrada mañana'), findsOneWidget);
    expect(find.text('Salida tarde'), findsOneWidget);
    expect(find.text('Salida mañana'), findsNothing);
    expect(find.text('Entrada tarde'), findsNothing);
    expect(find.text('08:30 AM'), findsOneWidget);
    expect(find.text('06:30 PM'), findsOneWidget);
    expect(find.text('--:--'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('plataforma conserva cuatro columnas y sus cuatro horas', (tester) async {
    await mostrar(tester, jornada(TipoHorarioPersonal.plataforma, 7));
    for (final texto in ['Entrada mañana', 'Salida mañana', 'Entrada tarde', 'Salida tarde',
      '08:30 AM', '01:00 PM', '03:00 PM', '06:30 PM']) {
      expect(find.text(texto), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('cambio de cargo conserva el formato de cada jornada', (tester) async {
    await mostrar(tester, [...jornada(TipoHorarioPersonal.asesor, 7),
      ...jornada(TipoHorarioPersonal.plataforma, 6)]);
    expect(find.text('Entrada mañana'), findsNWidgets(2));
    expect(find.text('Salida tarde'), findsNWidgets(2));
    expect(find.text('Salida mañana'), findsOneWidget);
    expect(find.text('Entrada tarde'), findsOneWidget);
    expect(find.text('06:30 PM'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
