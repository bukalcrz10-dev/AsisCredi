import 'package:asistencia_app/app/aplicacion.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/modulo_trabajadores_admin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Usa la configuración real de la raíz sin abrir compuertas de Firebase.
Widget pantalla(Widget child) => Builder(
  builder: (context) {
    final configuracion = const Aplicacion().build(context) as MaterialApp;
    return MaterialApp(
      locale: configuracion.locale,
      supportedLocales: configuracion.supportedLocales,
      localizationsDelegates: configuracion.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  },
);

void main() {
  testWidgets(
    'el calendario muestra días, meses y botones en español de Perú',
    (tester) async {
      MaterialLocalizations? textos;
      DateTime? elegida;
      await tester.pumpWidget(
        pantalla(
          Builder(
            builder: (context) {
              textos = MaterialLocalizations.of(context);
              return TextButton(
                onPressed: () async {
                  elegida = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 10, 17),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                  );
                },
                child: const Text('Abrir calendario'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        textos!.formatFullDate(DateTime(2026, 10, 17)),
        contains('sábado'),
      );
      expect(
        textos!.formatFullDate(DateTime(2026, 10, 17)),
        contains('octubre'),
      );
      await tester.tap(find.text('Abrir calendario'));
      await tester.pumpAndSettle();
      expect(find.textContaining('octubre'), findsWidgets);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Select date'), findsNothing);
      expect(find.textContaining('Sat, Oct'), findsNothing);
      await tester.tap(find.text('18').last);
      await tester.tap(find.text(textos!.okButtonLabel));
      await tester.pumpAndSettle();
      expect(elegida, DateTime(2026, 10, 18));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('inicio de labores hereda el calendario en español', (
    tester,
  ) async {
    await tester.pumpWidget(
      pantalla(
        FormularioTrabajadorAdmin(sedes: const [], onGuardar: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
    final fecha = find.byKey(const ValueKey('fecha-inicio-labores'));
    await tester.ensureVisible(fecha);
    await tester.tap(fecha);
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
