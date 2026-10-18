import 'dart:async';
import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/modulo_dashboard_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/resumen_dashboard_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'resumen_dashboard_admin_test.dart' as fixture;

Widget vista({
  required Future<ResumenDashboardAdmin> Function() cargar,
  ValueChanged<String>? abrir,
  double escala = 1,
}) => MaterialApp(
  theme: temaPanelAdmin(temaAplicacion()),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(escala)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ModuloDashboardAdmin(
        cargarDatos: cargar,
        onAbrirTrabajador: abrir,
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'filtros muestran casos reales y abren la ficha por identificador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? seleccionado;
      final datos = fixture.resumen(
        usuarios: [fixture.persona('u'), fixture.persona('v')],
        registros: [fixture.marcas('u').first],
      );
      await tester.pumpWidget(
        vista(cargar: () async => datos, abrir: (id) => seleccionado = id),
      );
      await tester.pumpAndSettle();
      expect(find.text('Incompletas · 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Abrir ficha de Persona u').first);
      expect(seleccionado, 'u');
      await tester.tap(find.text('Sin marcaciones · 1'));
      await tester.pumpAndSettle();
      expect(find.text('v@example.com'), findsOneWidget);
      await tester.tap(find.byTooltip('Abrir ficha de Persona v'));
      expect(seleccionado, 'v');
      await tester.tap(find.text('Observadas · 0'));
      await tester.pumpAndSettle();
      expect(find.text('No hay jornadas observadas hoy.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('la carga y un error no fabrican ceros; permite reintentar', (
    tester,
  ) async {
    final pendiente = Completer<ResumenDashboardAdmin>();
    var intentos = 0;
    await tester.pumpWidget(
      vista(
        cargar: () {
          intentos++;
          return intentos == 1
              ? pendiente.future
              : Future.value(fixture.resumen());
        },
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pendiente.completeError(StateError('detalle interno'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar el Dashboard'), findsOneWidget);
    expect(find.textContaining('detalle interno'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Indicadores de hoy'), findsOneWidget);
    expect(find.text('Asistencia de hoy'), findsNothing);
    expect(intentos, 2);
  });
  for (final ancho in [320.0, 768.0, 1400.0]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets('panel completo sin desbordes en $ancho y texto $escala', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(ancho, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final datos = fixture.resumen(
          usuarios: [
            fixture.persona('u'),
            fixture.persona('v', cargo: 'Otro'),
          ],
          registros: [fixture.marcas('u').first],
        );
        await tester.pumpWidget(
          vista(cargar: () async => datos, escala: escala, abrir: (_) {}),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Últimas jornadas'));
        await tester.pumpAndSettle();
        expect(find.text('09/10/2026 · 08:30 · Principal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
