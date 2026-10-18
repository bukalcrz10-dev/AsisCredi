import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/app/tema.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/tema_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/panel_biometria_admin.dart';

void main() {
  testWidgets('rostro y celular aprobados tienen bordes y títulos alineados', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: temaPanelAdmin(temaAplicacion()),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SeccionesBiometriaAdmin(
              registroActivo: true,
              registro: EstadoBiometriaAdmin(
                estado: 'activo',
                registroHabilitado: false,
              ),
              dispositivos: [
                TarjetaDispositivoBiometriaAdmin(
                  modelo: 'HUAWEI POT-LX3',
                  codigo: '75d24b',
                  estado: 'aprobado',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rostro = tester.getRect(find.byType(EstadoBiometriaAdmin));
    final celular = tester.getRect(
      find.byType(TarjetaDispositivoBiometriaAdmin),
    );
    expect(rostro.top, celular.top);
    expect(rostro.bottom, celular.bottom);
    expect(
      tester.getTopLeft(find.text('Rostro')).dy,
      tester.getTopLeft(find.text('Celular')).dy,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
  testWidgets(
    'el estado biométrico distingue autorización, registro y retiro',
    (tester) async {
      for (final estado in [
        ('activo', false, false, 'Aprobado'),
        ('pendiente', true, false, 'Esperando solicitud'),
        ('pendiente', true, true, 'Por aprobar'),
        ('pendiente', false, false, 'Sin registrar'),
        ('revocado', false, false, 'Sin registrar'),
        ('', false, false, 'Sin registrar'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EstadoBiometriaAdmin(
                estado: estado.$1,
                registroHabilitado: estado.$2,
                solicitudPendiente: estado.$3,
              ),
            ),
          ),
        );
        expect(find.text(estado.$4), findsOneWidget);
        expect(find.text('Rostro'), findsOneWidget);
        expect(find.text('Revisar y aprobar'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('el registro retirado explica cómo comenzar de nuevo', (
    tester,
  ) async {
    var iniciados = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EstadoBiometriaAdmin(
              estado: 'revocado',
              registroHabilitado: false,
              accion: FilledButton(
                onPressed: () => iniciados++,
                child: const Text('Permitir registro'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Sin registrar'), findsOneWidget);
    await tester.tap(find.text('Permitir registro'));
    expect(iniciados, 1);
  });

  testWidgets(
    'tarjeta de celular muestra modelo, código y aprobación separados',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TarjetaDispositivoBiometriaAdmin(
              modelo: 'HUAWEI POT-LX3',
              codigo: '75d24b',
              estado: 'aprobado',
            ),
          ),
        ),
      );
      expect(find.text('HUAWEI POT-LX3'), findsOneWidget);
      expect(find.text('Código'), findsOneWidget);
      expect(find.text('75d24b'), findsOneWidget);
      expect(find.text('Aprobado'), findsOneWidget);
    },
  );

  testWidgets(
    'estado y solicitudes pendientes se adaptan a ventanas y texto ampliado',
    (tester) async {
      for (final ancho in [320.0, 560.0, 1100.0]) {
        for (final escala in [1.0, 2.0]) {
          await tester.binding.setSurfaceSize(Size(ancho, 900));
          await tester.pumpWidget(
            MaterialApp(
              theme: temaPanelAdmin(temaAplicacion()),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(escala)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SeccionesBiometriaAdmin(
                    registroActivo: false,
                    registro: const EstadoBiometriaAdmin(
                      estado: 'pendiente',
                      registroHabilitado: true,
                      solicitudPendiente: true,
                    ),
                    dispositivos: [
                      TarjetaDispositivoBiometriaAdmin(
                        modelo:
                            'Samsung Galaxy con nombre de dispositivo extenso',
                        codigo: '75d24b',
                        estado: 'pendiente',
                        aprobacion: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: false,
                              onChanged: (_) {},
                              title: const Text(
                                'Verifiqué la identidad y el código con el trabajador presente.',
                              ),
                            ),
                            FilledButton(
                              onPressed: null,
                              child: const Text(
                                'Aprobar este rostro y celular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Pendiente'), findsOneWidget);
          expect(find.byType(CheckboxListTile), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '$ancho px, texto $escala',
          );
          await tester.pumpWidget(const SizedBox());
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('sin registro muestra rostro, celular vacío y una acción clara', (
    tester,
  ) async {
    for (final ancho in [320.0, 1100.0]) {
      await tester.binding.setSurfaceSize(Size(ancho, 1000));
      await tester.pumpWidget(
        MaterialApp(
          theme: temaPanelAdmin(temaAplicacion()),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SeccionesBiometriaAdmin(
                registroActivo: false,
                registro: EstadoBiometriaAdmin(
                  estado: 'revocado',
                  registroHabilitado: false,
                  accion: FilledButton(
                    onPressed: () {},
                    child: const Text('Permitir registro'),
                  ),
                ),
                dispositivos: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rostro'), findsOneWidget);
      expect(find.text('Celular'), findsOneWidget);
      expect(find.text('Sin celular vinculado'), findsOneWidget);
      expect(find.text('Permitir registro'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
  });
}
