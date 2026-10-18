import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_facial_local/main.dart';

void main() {
  testWidgets(
    'una inferencia bloqueada libera la interfaz e ignora el resultado tardío',
    (tester) async {
      const canal = MethodChannel('crediasciende/prueba_facial');
      final pendiente = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method == 'extraer') return pendiente.future;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, null),
      );
      await tester.pumpWidget(const PruebaFacialApp());
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('1. Tomar referencia'));
      await tester.pump();
      // Simula la devolución de una captura; no ejercita hardware de cámara.
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 45));
      await tester.pump();
      expect(find.textContaining('superó 45 segundos'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      pendiente.complete({
        'vector': List.generate(128, (i) => i == 0 ? 1.0 : 0.0),
        'milisegundos': 46000,
      });
      await tester.pump();
      expect(find.textContaining('Referencia lista.'), findsNothing);
      final comparar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '2. Tomar foto y comparar'),
      );
      expect(comparar.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
