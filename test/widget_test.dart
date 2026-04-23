import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/paginas/pagina_inicio_sesion.dart';

void main() {
  // Esta prueba evita depender de Firebase durante el entorno de test
  // y valida la composicion basica de la pantalla de acceso.
  testWidgets('muestra la pantalla institucional de inicio de sesion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaAplicacion(),
        home: const PaginaInicioSesion(),
      ),
    );
    await tester.pump();

    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('UNACHU'), findsOneWidget);
    expect(find.text('INGRESAR AL SISTEMA'), findsOneWidget);
  });
}
