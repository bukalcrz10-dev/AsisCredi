import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/widgets/control_acceso_admin.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/controladores/sesion_trabajador.dart';

void main() {
  testWidgets(
    'bloquea hasta confirmar servidor y oculta incluso diálogos al revocar',
    (tester) async {
      final auth = StreamController<String?>();
      final permisos = StreamController<bool?>();
      final nav = GlobalKey<NavigatorState>();
      var cierres = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (context, child) => ControlAccesoAdmin(
            navigatorKey: nav,
            sesiones: auth.stream,
            permisos: (_) => permisos.stream,
            cerrarSesion: () async {
              cierres++;
              auth.add(null);
            },
            child: child!,
          ),
          home: const Scaffold(body: Text('Panel privado')),
        ),
      );
      auth.add('admin');
      await tester.pump();
      permisos.add(null);
      await tester.pump();
      expect(find.text('Panel privado'), findsNothing);
      permisos.add(true);
      await tester.pump();
      expect(find.text('Panel privado'), findsOneWidget);
      unawaited(
        showDialog<void>(
          context: nav.currentState!.overlay!.context,
          builder: (_) => const AlertDialog(title: Text('Edición privada')),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(find.text('Edición privada'), findsOneWidget);
      permisos.add(false);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
      expect(cierres, 1);
      expect(find.text('Edición privada'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      unawaited(auth.close());
      unawaited(permisos.close());
    },
  );

  testWidgets('si cerrar falla mantiene bloqueo y permite reintentar', (
    tester,
  ) async {
    final auth = StreamController<String?>();
    final permisos = StreamController<bool?>();
    var cierres = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ControlAccesoAdmin(
          navigatorKey: GlobalKey<NavigatorState>(),
          sesiones: auth.stream,
          permisos: (_) => permisos.stream,
          cerrarSesion: () async {
            cierres++;
            throw StateError('fallo');
          },
          child: const Text('Panel privado'),
        ),
      ),
    );
    auth.add('admin');
    await tester.pump();
    permisos.add(true);
    await tester.pump();
    permisos.addError(StateError('perfil inaccesible'));
    await tester.pump();
    expect(find.text('Panel privado'), findsNothing);
    expect(find.text('Reintentar cierre'), findsOneWidget);
    permisos.add(true);
    await tester.pump();
    expect(find.text('Panel privado'), findsNothing);
    await tester.tap(find.text('Reintentar cierre'));
    await tester.pump();
    expect(cierres, 2);
    await tester.pumpWidget(const SizedBox());
    unawaited(auth.close());
    unawaited(permisos.close());
  });

  test(
    'inactividad de administrador persiste y no se mezcla con mantener sesión del trabajador',
    () async {
      SharedPreferences.setMockInitialValues({});
      var ahora = DateTime(2026, 10, 14, 8);
      final trabajador = SesionTrabajador(reloj: () => ahora);
      final admin = SesionTrabajador(
        reloj: () => ahora,
        clave: 'sesion_administrador_v1',
      );
      await trabajador.establecer('u', true);
      await admin.establecer('u', false);
      ahora = ahora.add(const Duration(minutes: 15));
      final recargada = SesionTrabajador(
        reloj: () => ahora,
        clave: 'sesion_administrador_v1',
      );
      await recargada.cargar();
      expect(recargada.vencida('u'), isTrue);
      recargada.actividad('u');
      expect(recargada.vencida('u'), isTrue);
      expect(trabajador.vencida('u'), isFalse);
    },
  );
}
