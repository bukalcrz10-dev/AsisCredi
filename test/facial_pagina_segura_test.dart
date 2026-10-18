import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/local/camara.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/presentacion/paginas/pagina_rostro_seguro.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/seguridad/servicio_seguridad_biometrica.dart';

class _Servicio extends Fake implements ServicioSeguridadBiometrica {
  int solicitudes = 0;
  @override
  void limpiar() {}
  @override
  Future<({Map<String, dynamic> datos, String token, int version})>
  autorizado() async =>
      (datos: <String, dynamic>{}, token: 'prueba', version: 1);
  @override
  Future<void> permitirCapturaReferencia() async {}
  @override
  Future<String> enviarReferencia(List<double> vector) async {
    expect(vector.length, 128);
    solicitudes++;
    return 'abcdef';
  }
}

void main() {
  const canal = MethodChannel('crediasciende/rostro');
  testWidgets(
    'validar abre cámara automáticamente y cancelar vuelve a asistencia',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaginaRostroSeguro(servicio: _Servicio()),
                  ),
                ),
                child: const Text('Validar rostro'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Validar rostro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CamaraPrueba), findsOneWidget);
      expect(find.text('Capturar y verificar'), findsNothing);
      Navigator.of(tester.element(find.byType(CamaraPrueba))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(PaginaRostroSeguro), findsNothing);
      expect(find.text('Validar rostro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final fallaMotor in [false, true]) {
    testWidgets(
      'desbloquea botones con bytes de solo lectura, error=$fallaMotor',
      (tester) async {
        final servicio = _Servicio();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, (call) async {
              if (fallaMotor) {
                throw PlatformException(
                  code: 'procesamiento',
                  message: 'Prueba de fallo',
                );
              }
              return {'vector': List.generate(128, (i) => i == 0 ? 1.0 : 0.0)};
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(canal, null),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PaginaRostroSeguro(
              servicio: servicio,
              registrarReferencia: true,
            ),
          ),
        );
        final boton = find.widgetWithText(
          FilledButton,
          'Solicitar registro de rostro y celular',
        );
        expect(tester.widget<FilledButton>(boton).onPressed, isNull);
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.ensureVisible(boton);
        await tester.tap(boton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(CamaraPrueba), findsOneWidget);
        Navigator.of(
          tester.element(find.byType(CamaraPrueba)),
        ).pop(Uint8List.fromList([1, 2, 3]).asUnmodifiableView());
        await tester.pumpAndSettle();
        expect(servicio.solicitudes, fallaMotor ? 0 : 1);
        expect(
          find.textContaining(
            fallaMotor ? 'Prueba de fallo' : 'Solicitud enviada',
          ),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
