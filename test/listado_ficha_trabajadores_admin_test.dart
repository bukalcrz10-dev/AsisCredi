import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/trabajador_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/listado_trabajadores_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/ficha_trabajador_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _trabajadores = List.generate(
  61,
  (i) => TrabajadorAdmin(
    id: 'id-$i',
    nombreCompleto: 'Persona ${i.toString().padLeft(2, '0')}',
    correo: 'persona$i@example.com',
    telefono: '999999999',
    area: 'Créditos',
    cargo: 'Auxiliar de operaciones',
    rol: 'Trabajador',
    estadoActivo: i % 3 != 0,
    sede: 'Sede Principal',
  ),
);

Widget _pantalla(Widget child, {double escala = 1}) => MaterialApp(
  theme: temaPanelAdmin(temaAplicacion()),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(escala)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('la cabecera separa nombres y apellidos y muestra el cargo', (
    tester,
  ) async {
    for (final caso in [
      ('Armando Fernandez Huaman', 'Armando', 'Fernandez Huaman'),
      ('Julio Cesar Quispe Zarate', 'Julio Cesar', 'Quispe Zarate'),
      ('Yemen', 'Yemen', ''),
    ]) {
      await tester.pumpWidget(
        _pantalla(
          FichaTrabajadorAdmin(
            trabajador: _trabajadores.first.copyWith(
              nombreCompleto: caso.$1,
              cargo: 'Asesor',
            ),
            onVolver: () {},
          ),
        ),
      );
      final nombres = find.byKey(const ValueKey('nombres-trabajador'));
      final apellidos = find.byKey(const ValueKey('apellidos-trabajador'));
      expect(tester.widget<Text>(nombres).data, caso.$2);
      if (caso.$3.isEmpty) {
        expect(apellidos, findsNothing);
      } else {
        expect(tester.widget<Text>(apellidos).data, caso.$3);
        expect(
          tester.getTopLeft(apellidos).dy,
          greaterThan(tester.getBottomLeft(nombres).dy),
        );
      }
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('cargo-cabecera-trabajador')),
            )
            .data,
        'Asesor',
      );
      expect(find.text('Cuenta vigente'), findsNothing);
      expect(find.text('Cuenta inactiva'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'las pestañas muestran su contenido sin enviar recuperación al abrir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      var consultas = 0, recuperaciones = 0, consultasAsistencia = 0;
      await tester.pumpWidget(
        _pantalla(
          FichaTrabajadorAdmin(
            trabajador: _trabajadores[1],
            onVolver: () {},
            onRecuperar: () => recuperaciones++,
            construirResumenAsistencia: (_) =>
                const Text('Indicadores de asistencia del trabajador'),
            construirAsistencia: (_) {
              consultasAsistencia++;
              return const Text('Asistencia del trabajador seleccionado');
            },
            construirBiometria: (_) {
              consultas++;
              return const Text(
                'Configuración de rostro y celular del trabajador',
              );
            },
          ),
        ),
      );
      expect(consultas, 0);
      expect(consultasAsistencia, 0);
      expect(
        find.text('Indicadores de asistencia del trabajador'),
        findsOneWidget,
      );
      expect(find.text('Resumen del trabajador'), findsOneWidget);
      await tester.tap(find.text('Asistencia'));
      await tester.pumpAndSettle();
      expect(consultasAsistencia, greaterThan(0));
      expect(
        find.text('Indicadores de asistencia del trabajador'),
        findsNothing,
      );
      expect(
        find.text('Asistencia del trabajador seleccionado'),
        findsOneWidget,
      );
      expect(consultas, 0);
      await tester.tap(find.text('Rostro y celular'));
      await tester.pumpAndSettle();
      expect(consultas, greaterThan(0));
      expect(
        find.text('Configuración de rostro y celular del trabajador'),
        findsOneWidget,
      );
      expect(find.text('Resumen del trabajador'), findsNothing);
      await tester.tap(find.text('Recuperar contraseña'));
      await tester.pumpAndSettle();
      expect(find.text('Recuperación de contraseña'), findsOneWidget);
      expect(recuperaciones, 0);
      await tester.tap(find.text('Enviar enlace'));
      await tester.pump();
      expect(recuperaciones, 1);
      await tester.tap(find.text('Resumen'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen del trabajador'), findsOneWidget);
      expect(find.byTooltip('Editar trabajador'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('tabla pagina, busca en todas las cuentas y filtra inactivos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pantalla(
        ListadoTrabajadoresAdmin(
          trabajadores: _trabajadores,
          cargando: false,
          onActualizar: () {},
          onSeleccionar: (_) {},
        ),
      ),
    );
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Página 2 de 2'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Persona 01');
    await tester.pump();
    expect(find.text('Página 1 de 1'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Persona 01'), findsOneWidget);
    expect(
      find.textContaining('Mostrando 1 al 1 de 1 registros'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Persona 00');
    await tester.pump();
    expect(
      find.textContaining('No hay trabajadores que coincidan'),
      findsOneWidget,
    );
    final estado = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(estado);
    await tester.tap(estado);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactivos').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Persona 00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'seleccionar un nombre abre la ficha y volver conserva la búsqueda',
    (tester) async {
      TrabajadorAdmin? seleccionado;
      await tester.pumpWidget(
        _pantalla(
          StatefulBuilder(
            builder: (context, cambiar) => Column(
              children: [
                Offstage(
                  offstage: seleccionado != null,
                  child: ListadoTrabajadoresAdmin(
                    trabajadores: _trabajadores,
                    cargando: false,
                    onActualizar: () {},
                    onSeleccionar: (t) => cambiar(() => seleccionado = t),
                  ),
                ),
                if (seleccionado != null)
                  FichaTrabajadorAdmin(
                    trabajador: seleccionado!,
                    onVolver: () => cambiar(() => seleccionado = null),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Persona 01');
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(TextButton, 'Persona 01'));
      await tester.tap(find.widgetWithText(TextButton, 'Persona 01'));
      await tester.pump();
      expect(find.text('Resumen del trabajador'), findsOneWidget);
      expect(find.text('persona1@example.com'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Volver al listado'));
      await tester.tap(find.byTooltip('Volver al listado'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Persona 01',
      );
      expect(find.widgetWithText(TextButton, 'Persona 01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tabla y ficha se adaptan a ventanas estrechas y texto ampliado',
    (tester) async {
      for (final ancho in [320.0, 768.0, 1280.0]) {
        for (final escala in [1.0, 2.0]) {
          await tester.binding.setSurfaceSize(Size(ancho, 800));
          await tester.pumpWidget(
            _pantalla(
              ListadoTrabajadoresAdmin(
                trabajadores: _trabajadores.take(3).toList(),
                cargando: false,
                onActualizar: () {},
                onSeleccionar: (_) {},
              ),
              escala: escala,
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Tabla $ancho, texto $escala',
          );
          await tester.pumpWidget(
            _pantalla(
              FichaTrabajadorAdmin(
                trabajador: _trabajadores.first,
                onVolver: () {},
                construirBiometria: (_) =>
                    const Text('Contenido biométrico de prueba'),
              ),
              escala: escala,
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'Ficha $ancho, texto $escala',
          );
          for (final etiqueta in [
            'Asistencia',
            'Rostro y celular',
            'Recuperar contraseña',
            'Resumen',
          ]) {
            final pestana = find.text(etiqueta);
            await tester.ensureVisible(find.byType(TabBar));
            await tester.pumpAndSettle();
            for (
              var intento = 0;
              intento < 8 && pestana.hitTestable().evaluate().isEmpty;
              intento++
            ) {
              final desplazamiento =
                  tester.getCenter(pestana).dx <
                      tester.getCenter(find.byType(TabBar)).dx
                  ? 200.0
                  : -200.0;
              await tester.drag(find.byType(TabBar), Offset(desplazamiento, 0));
              await tester.pumpAndSettle();
            }
            expect(pestana.hitTestable(), findsOneWidget);
            await tester.tap(pestana);
            await tester.pumpAndSettle();
            expect(
              tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
              [
                'Resumen',
                'Asistencia',
                'Rostro y celular',
                'Recuperar contraseña',
              ].indexOf(etiqueta),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$etiqueta: $ancho px, texto $escala',
            );
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
