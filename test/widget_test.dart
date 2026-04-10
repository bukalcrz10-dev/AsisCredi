import 'package:flutter_test/flutter_test.dart';

import 'package:asistencia_app/app/aplicacion.dart';

void main() {
  // Esta prueba valida la base visual minima del proyecto.
  // Se apoya en app/aplicacion.dart porque ese archivo representa
  // el punto de entrada de la interfaz sin depender de main.dart.
  testWidgets('muestra la pantalla inicial del proyecto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Aplicacion());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Entrar al sistema'), findsOneWidget);
  });
}
