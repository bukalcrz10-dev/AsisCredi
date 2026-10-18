import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_facial_local/main.dart';

void main() {
  for (final falla in [false, true]) {
    testWidgets('respuesta nativa termina la carga (error: $falla)', (
      tester,
    ) async {
      const canal = MethodChannel('crediasciende/prueba_facial');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method != 'extraer') return null;
            if (falla) {
              throw PlatformException(
                code: 'tiempo_agotado',
                message: 'El motor superó 40 segundos.',
              );
            }
            return {
              'vector': List.generate(128, (i) => i == 0 ? 1.0 : 0.0),
              'milisegundos': 50,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, null),
      );
      await tester.pumpWidget(const PruebaFacialApp());
      expect(find.text('Prueba facial · 0.3.6'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('1. Tomar referencia'));
      await tester.pump();
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop(Uint8List.fromList([1, 2, 3]).asUnmodifiableView());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        find.textContaining(falla ? 'superó 40 segundos' : 'Referencia lista.'),
        findsOneWidget,
      );
      final botonComparar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '2. Tomar foto y comparar'),
      );
      expect(botonComparar.onPressed, falla ? isNull : isNotNull);
      final botonReferencia = tester.widget<FilledButton>(
        find.widgetWithText(
          FilledButton,
          falla ? '1. Tomar referencia' : 'Reemplazar referencia',
        ),
      );
      expect(botonReferencia.onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }
}
