import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/monitor_conexion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/cabecera_trabajador_panel.dart';

void main() {
  testWidgets(
    'verifica antes de mostrar en línea; detecta pérdida y recuperación',
    (tester) async {
      var disponible = true;
      var consultas = 0;
      final monitor = MonitorConexion(
        comprobar: () async {
          consultas++;
          return disponible;
        },
      );
      addTearDown(monitor.dispose);
      monitor.iniciar();
      expect(monitor.estado, EstadoConexion.verificando);
      await tester.pump();
      expect(monitor.estado, EstadoConexion.enLinea);
      disponible = false;
      await tester.pump(const Duration(minutes: 1));
      expect(monitor.estado, EstadoConexion.sinConexion);
      disponible = true;
      await tester.pump(const Duration(minutes: 1));
      expect(monitor.estado, EstadoConexion.enLinea);
      expect(consultas, 3);
      monitor.pausar();
    },
  );
  testWidgets(
    'timeout no conserva el punto verde y una respuesta tardía no lo cambia',
    (tester) async {
      final respuesta = Completer<bool>();
      final monitor = MonitorConexion(comprobar: () => respuesta.future);
      addTearDown(monitor.dispose);
      monitor.iniciar();
      await tester.pump(const Duration(seconds: 5));
      expect(monitor.estado, EstadoConexion.sinConexion);
      respuesta.complete(true);
      await tester.pump();
      expect(monitor.estado, EstadoConexion.sinConexion);
      monitor.pausar();
    },
  );
  testWidgets(
    'pausa no consulta y al volver verifica; ignora consulta anterior',
    (tester) async {
      final anterior = Completer<bool>();
      var consultas = 0;
      final monitor = MonitorConexion(
        comprobar: () =>
            ++consultas == 1 ? anterior.future : Future.value(false),
      );
      addTearDown(monitor.dispose);
      monitor.iniciar();
      monitor.pausar();
      await tester.pump(const Duration(minutes: 2));
      expect(consultas, 1);
      monitor.iniciar();
      await tester.pump();
      expect(monitor.estado, EstadoConexion.sinConexion);
      anterior.complete(true);
      await tester.pump();
      expect(monitor.estado, EstadoConexion.sinConexion);
      monitor.pausar();
    },
  );
  testWidgets(
    'error del servidor y cierre durante una consulta no notifican tras dispose',
    (tester) async {
      final respuesta = Completer<bool>();
      final monitor = MonitorConexion(comprobar: () => respuesta.future);
      monitor.iniciar();
      monitor.dispose();
      respuesta.completeError(StateError('Sin conexión'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  for (final (estado, texto) in [
    (EstadoConexion.verificando, 'Verificando conexión…'),
    (EstadoConexion.enLinea, 'En línea'),
    (EstadoConexion.sinConexion, 'Sin conexión'),
  ]) {
    testWidgets('cabecera muestra $texto sin desbordar en pantalla pequeña', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CabeceraTrabajadorPanel(
              nombre: 'Trabajador de prueba',
              sede: 'Huancayo',
              fecha: '11/10/2026',
              hora: '08:30:00',
              estadoConexion: estado,
            ),
          ),
        ),
      );
      expect(find.text(texto), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
