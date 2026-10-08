import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/widgets/acceso_perfil_activo.dart';

void main() {
  test('la cache no se confunde con un perfil inexistente o inactivo', () {
    expect(
      evaluarPerfilActivo(desdeCache: true, existe: false, activo: false),
      EstadoPerfilActivo.verificando,
    );
    expect(
      evaluarPerfilActivo(desdeCache: true, existe: true, activo: true),
      EstadoPerfilActivo.verificando,
    );
    expect(
      evaluarPerfilActivo(desdeCache: false, existe: false, activo: false),
      EstadoPerfilActivo.sinPerfil,
    );
    expect(
      evaluarPerfilActivo(desdeCache: false, existe: true, activo: false),
      EstadoPerfilActivo.inactivo,
    );
    expect(
      evaluarPerfilActivo(desdeCache: false, existe: true, activo: true),
      EstadoPerfilActivo.activo,
    );
  });

  testWidgets(
    'espera al servidor, avisa demora y recupera acceso al confirmar',
    (tester) async {
      final permisos = StreamController<EstadoPerfilActivo>.broadcast();
      await tester.pumpWidget(
        MaterialApp(
          home: AccesoPerfilActivo(
            permisos: permisos.stream,
            onCerrarSesion: () async {},
            child: const Text('Asistencia permitida'),
          ),
        ),
      );
      permisos.add(EstadoPerfilActivo.verificando);
      await tester.pump();
      expect(
        find.text('Verificando tu perfil con el servidor…'),
        findsOneWidget,
      );
      expect(find.textContaining('no está habilitado'), findsNothing);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Asistencia permitida'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(
        find.text('Verificando tu perfil con el servidor…'),
        findsOneWidget,
      );
      permisos.add(EstadoPerfilActivo.activo);
      await tester.pump();
      expect(find.text('Asistencia permitida'), findsOneWidget);
      permisos.add(EstadoPerfilActivo.sinPerfil);
      await tester.pump();
      expect(find.textContaining('no tiene un perfil'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(permisos.close());
      await tester.pump();
    },
  );

  testWidgets(
    'retira la pantalla al desactivar el perfil y bloquea ante errores',
    (tester) async {
      final permisos = StreamController<EstadoPerfilActivo>();
      addTearDown(permisos.close);
      await tester.pumpWidget(
        MaterialApp(
          home: AccesoPerfilActivo(
            permisos: permisos.stream,
            onCerrarSesion: () async {},
            child: const Text('Asistencia permitida'),
          ),
        ),
      );
      expect(find.text('Asistencia permitida'), findsNothing);
      permisos.add(EstadoPerfilActivo.activo);
      await tester.pump();
      expect(find.text('Asistencia permitida'), findsOneWidget);
      permisos.add(EstadoPerfilActivo.inactivo);
      await tester.pump();
      expect(find.text('Asistencia permitida'), findsNothing);
      permisos.add(EstadoPerfilActivo.activo);
      await tester.pump();
      permisos.addError(Exception('Sin conexión'));
      await tester.pump();
      expect(find.text('Asistencia permitida'), findsNothing);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    },
  );
}
