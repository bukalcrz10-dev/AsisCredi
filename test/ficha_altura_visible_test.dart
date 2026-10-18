import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/item_menu_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/ficha_trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/layout_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget pantalla() => MaterialApp(
  theme: temaAplicacion(),
  home: LayoutAdmin(
    items: const [
      ItemMenuAdmin(
        id: 'trabajadores',
        titulo: 'Trabajadores',
        descripcion: '',
        icono: Icons.groups_outlined,
      ),
    ],
    indiceSeleccionado: 0,
    onSeleccionar: (_) {},
    child: Column(
      children: [
        FichaTrabajadorAdmin(
          trabajador: const TrabajadorAdmin(
            id: 'demo',
            nombreCompleto: 'Trabajador de Prueba',
            correo: 'demo@example.com',
            telefono: '999999999',
            area: 'Plataforma',
            cargo: 'Auxiliar de operaciones',
            rol: 'Trabajador',
            estadoActivo: true,
            sede: 'Sede Principal',
          ),
          onVolver: () {},
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets(
    'la tarjeta alcanza el fondo visible y responde al cambio de altura',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla());
      for (final altura in [900.0, 1100.0, 820.0]) {
        await tester.binding.setSurfaceSize(Size(1440, altura));
        await tester.pumpAndSettle();
        final tarjeta = tester.getRect(
          find.byKey(const ValueKey('tarjeta-identidad-trabajador')),
        );
        expect(tarjeta.bottom, greaterThanOrEqualTo(altura - 17));
        if (altura >= 900) {
          expect(tarjeta.bottom, closeTo(altura - 16, 1));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.text('demo'));
      await tester.pumpAndSettle();
      expect(find.text('demo').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'en una ventana estrecha no agrega altura vacía antes de las pestañas',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 1100));
      await tester.pumpWidget(pantalla());
      await tester.pumpAndSettle();
      final tarjeta = tester.getRect(
        find.byKey(const ValueKey('tarjeta-identidad-trabajador')),
      );
      expect(tarjeta.height, lessThan(900));
      expect(tester.takeException(), isNull);
    },
  );
}
