import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/modulo_trabajadores_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sedes = [
  Sede(
    id: 'principal',
    nombre: 'Sede Principal',
    latitud: -12,
    longitud: -75,
    radioPermitidoMetros: 50,
  ),
];

Widget _pantalla({
  required Future<void> Function(ResultadoFormularioTrabajadorAdmin) guardar,
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
      child: FormularioTrabajadorAdmin(
        sedes: _sedes,
        onGuardar: guardar,
        onRestablecer: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('crear muestra el formulario y valida sin cerrar el submódulo', (
    tester,
  ) async {
    var guardados = 0;
    await tester.pumpWidget(
      _pantalla(
        guardar: (_) async {
          guardados++;
        },
      ),
    );
    await tester.ensureVisible(find.text('Crear trabajador'));
    await tester.tap(find.text('Crear trabajador'));
    await tester.pump();
    expect(guardados, 0);
    expect(find.textContaining('Completa:'), findsOneWidget);
    expect(find.byType(FormularioTrabajadorAdmin), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crear entrega los datos al guardado sin navegar fuera', (
    tester,
  ) async {
    ResultadoFormularioTrabajadorAdmin? guardado;
    await tester.pumpWidget(
      _pantalla(
        guardar: (resultado) async {
          guardado = resultado;
        },
      ),
    );
    for (final campo in <String, String>{
      'Nombre completo': 'Trabajador de prueba',
      'Correo institucional': 'prueba@example.com',
      'Teléfono': '999999999',
      'Área': 'Créditos',
      'Contraseña inicial': 'prueba123',
    }.entries) {
      final entrada = find.byKey(ValueKey(campo.key));
      await tester.ensureVisible(entrada);
      await tester.enterText(entrada, campo.value);
    }
    final sede = find.byKey(const ValueKey('Sede asignada'));
    final inicio = find.byKey(const ValueKey('fecha-inicio-labores'));
    await tester.ensureVisible(inicio);
    await tester.pumpAndSettle();
    await tester.tap(inicio);
    await tester.pumpAndSettle();
    final fechaInicial = tester
        .widget<DatePickerDialog>(find.byType(DatePickerDialog))
        .initialDate!;
    await tester.tap(find.text('8').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(sede);
    await tester.pumpAndSettle();
    await tester.tap(sede);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sede Principal').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear trabajador'));
    await tester.tap(find.text('Crear trabajador'));
    await tester.pump();
    expect(guardado?.trabajador.nombreCompleto, 'Trabajador de prueba');
    expect(guardado?.trabajador.sedeId, 'principal');
    expect(
      guardado?.trabajador.fechaInicioLabores,
      DateTime(fechaInicial.year, fechaInicial.month, 8),
    );
    expect(guardado?.password, 'prueba123');
    expect(find.byType(FormularioTrabajadorAdmin), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'el formulario integrado admite ventanas pequeñas y texto ampliado',
    (tester) async {
      for (final ancho in [320.0, 768.0, 1280.0]) {
        for (final escala in [1.0, 2.0]) {
          await tester.binding.setSurfaceSize(Size(ancho, 800));
          await tester.pumpWidget(
            _pantalla(guardar: (_) async {}, escala: escala),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$ancho px, escala $escala',
          );
          if (ancho == 1280 && escala == 1) {
            final fila = tester
                .getTopLeft(find.byKey(const ValueKey('Nombre completo')))
                .dy;
            for (final etiqueta in [
              'Correo institucional',
              'Teléfono',
              'Área',
            ]) {
              expect(
                tester.getTopLeft(find.byKey(ValueKey(etiqueta))).dy,
                fila,
              );
            }
          }
          if (ancho == 320) {
            expect(
              tester
                  .getTopLeft(
                    find.byKey(const ValueKey('Correo institucional')),
                  )
                  .dy,
              greaterThan(
                tester
                    .getTopLeft(find.byKey(const ValueKey('Nombre completo')))
                    .dy,
              ),
            );
          }
          await tester.ensureVisible(find.text('Crear trabajador'));
          await tester.pump();
          expect(find.text('Crear trabajador').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
