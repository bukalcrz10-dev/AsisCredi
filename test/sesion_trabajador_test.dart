import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/controladores/sesion_trabajador.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/widgets/control_sesion_trabajador.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime ahora;
  late SesionTrabajador sesion;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ahora = DateTime(2026, 10, 7, 8);
    sesion = SesionTrabajador(reloj: () => ahora);
  });

  test(
    'vence exactamente a los 15 minutos y un toque tardio no la reactiva',
    () async {
      await sesion.establecer('u1', false);
      ahora = ahora.add(const Duration(minutes: 14, seconds: 59));
      expect(sesion.vencida('u1'), isFalse);
      ahora = ahora.add(const Duration(seconds: 1));
      sesion.actividad('u1');
      expect(sesion.vencida('u1'), isTrue);
    },
  );

  test('actividad real renueva el plazo y sobrevive al reinicio', () async {
    await sesion.establecer('u1', false);
    ahora = ahora.add(const Duration(minutes: 10));
    sesion.actividad('u1');
    await Future<void>.delayed(Duration.zero);
    final restaurada = SesionTrabajador(reloj: () => ahora);
    await restaurada.cargar();
    ahora = ahora.add(const Duration(minutes: 14));
    expect(restaurada.vencida('u1'), isFalse);
    ahora = ahora.add(const Duration(minutes: 1));
    expect(restaurada.vencida('u1'), isTrue);
  });

  test('mantener persiste por cuenta y limpiar lo invalida', () async {
    await sesion.establecer('u1', true);
    ahora = ahora.add(const Duration(days: 30));
    final restaurada = SesionTrabajador(reloj: () => ahora);
    await restaurada.cargar();
    expect(restaurada.vencida('u1'), isFalse);
    expect(restaurada.vencida('u2'), isTrue);
    await restaurada.limpiar();
    expect(restaurada.vencida('u1'), isTrue);
  });

  test(
    'sesiones antiguas sin preferencia y retroceso del reloj requieren ingreso',
    () async {
      await sesion.cargar();
      expect(sesion.vencida('u1'), isTrue);
      await sesion.establecer('u1', false);
      ahora = ahora.subtract(const Duration(minutes: 1));
      expect(sesion.vencida('u1'), isTrue);
    },
  );

  test(
    'politica se guarda antes de liberar el ingreso y no en un fallo',
    () async {
      final respuesta = Completer<void>();
      final intento = sesion.autenticar(
        mantener: true,
        ingresar: () => respuesta.future,
        usuarioActual: () => 'u1',
        cerrar: () async {},
      );
      expect(sesion.accesoEnCurso, isNotNull);
      respuesta.complete();
      await intento;
      expect(sesion.accesoEnCurso, isNull);
      expect(sesion.vencida('u1'), isFalse);
      await sesion.limpiar();
      await expectLater(
        sesion.autenticar(
          mantener: true,
          ingresar: () async => throw StateError('fallo'),
          usuarioActual: () => null,
          cerrar: () async {},
        ),
        throwsStateError,
      );
      expect(sesion.vencida('u1'), isTrue);
      expect(sesion.accesoEnCurso, isNull);
    },
  );

  for (final mantener in [false, true]) {
    testWidgets('cierre automatico con mantener=$mantener', (tester) async {
      SharedPreferences.setMockInitialValues({});
      sesion = SesionTrabajador(reloj: () => ahora);
      await sesion.establecer('u1', mantener);
      final cambios = StreamController<String?>();
      String? uid = 'u1';
      var cierres = 0;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => ControlSesionTrabajador(
            navigatorKey: navigator,
            sesion: sesion,
            sesiones: cambios.stream,
            usuarioActual: () => uid,
            cerrarSesion: () async {
              cierres++;
              uid = null;
              cambios.add(null);
            },
            child: child!,
          ),
          home: const Scaffold(body: Text('Contenido')),
        ),
      );
      cambios.add(uid);
      await tester.pump();
      await tester.pump();
      expect(find.text('Contenido'), findsOneWidget);
      ahora = ahora.add(const Duration(minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(cierres, mantener ? 0 : 1);
      // El cierre manual debe borrar la preferencia incluso si estaba marcada.
      uid = null;
      cambios.add(null);
      await tester.pump();
      await tester.pump();
      expect(sesion.vencida('u1'), isTrue);
      await tester.pumpWidget(const SizedBox());
      unawaited(cambios.close());
      await tester.pump();
    }, timeout: const Timeout(Duration(seconds: 20)));
  }

  testWidgets(
    'al regresar vencida espera una marcacion y cierra rutas superpuestas',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      sesion = SesionTrabajador(reloj: () => ahora);
      await sesion.establecer('u1', false);
      final cambios = StreamController<String?>();
      String? uid = 'u1';
      var cierres = 0;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (_, child) => ControlSesionTrabajador(
            navigatorKey: navigator,
            sesion: sesion,
            sesiones: cambios.stream,
            usuarioActual: () => uid,
            cerrarSesion: () async {
              cierres++;
              uid = null;
              cambios.add(null);
            },
            child: child!,
          ),
          home: const Scaffold(body: Text('Inicio')),
        ),
      );
      cambios.add(uid);
      await tester.pump();
      await tester.pump();
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Camara')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final escritura = Completer<void>();
      final marcacion = sesion.protegerOperacion(() => escritura.future);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      ahora = ahora.add(const Duration(minutes: 20));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(cierres, 0);
      escritura.complete();
      await marcacion;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(cierres, 1);
      expect(find.text('Camara'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(cambios.close());
      await tester.pump();
    },
  );
}
