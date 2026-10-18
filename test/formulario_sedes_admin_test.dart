import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/formulario_sedes_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sedes = [
  Sede(
    id: 'h',
    nombre: 'Huancayo',
    latitud: -12,
    longitud: -75,
    radioPermitidoMetros: 100,
  ),
  Sede(
    id: 's',
    nombre: 'Satipo',
    latitud: -11,
    longitud: -74,
    radioPermitidoMetros: 80,
    activa: false,
  ),
];

Widget pantalla() => MaterialApp(
  theme: temaPanelAdmin(temaAplicacion()),
  home: Scaffold(
    body: SingleChildScrollView(
      child: FormularioSedesAdmin(sedes: sedes, onGuardado: (_) {}),
    ),
  ),
);

String valor(WidgetTester tester, String clave) =>
    tester.widget<TextFormField>(find.byKey(ValueKey(clave))).controller!.text;

void main() {
  testWidgets(
    'seleccionar y restablecer mantienen los datos y el estado de la sede',
    (tester) async {
      await tester.pumpWidget(pantalla());
      expect(valor(tester, 'nombre-sede'), 'Huancayo');
      await tester.tap(find.byKey(const ValueKey('sede-configurar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Satipo').last);
      await tester.pumpAndSettle();
      expect(valor(tester, 'nombre-sede'), 'Satipo');
      expect(valor(tester, 'Latitud'), '-11.0');
      expect(valor(tester, 'Longitud'), '-74.0');
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.enterText(
        find.byKey(const ValueKey('Radio permitido (metros)')),
        '200',
      );
      await tester.ensureVisible(find.text('Restablecer campos'));
      await tester.tap(find.text('Restablecer campos'));
      await tester.pump();
      expect(valor(tester, 'Radio permitido (metros)'), '80.0');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('coordenadas inválidas muestran validación antes de guardar', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla());
    await tester.enterText(find.byKey(const ValueKey('Latitud')), '91');
    await tester.ensureVisible(find.text('Guardar sede'));
    await tester.tap(find.text('Guardar sede'));
    await tester.pump();
    expect(find.textContaining('Ingresa un valor válido'), findsOneWidget);
    expect(find.text('Guardando…'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
