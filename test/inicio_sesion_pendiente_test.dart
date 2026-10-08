import 'dart:async';

import 'package:asistencia_app/funcionalidades/autenticacion/dominio/casos_de_uso/iniciar_sesion.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/dominio/repositorios/repositorio_autenticacion.dart';
import 'package:asistencia_app/funcionalidades/autenticacion/presentacion/controladores/controlador_inicio_sesion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthPendiente extends Fake implements RepositorioAutenticacion {
  final respuesta = Completer<void>();
  int solicitudes = 0;

  @override
  Future<void> iniciarSesion({required String correo, required String contrasena}) {
    solicitudes++;
    return respuesta.future;
  }
}

void main() {
  testWidgets('connection reset no se presenta como un fallo de credenciales', (tester) async {
    final auth = _AuthPendiente();
    final controlador = ControladorInicioSesion(iniciarSesion: IniciarSesion(auth));
    final intento = controlador.iniciarSesion(correo: 'prueba@example.com', contrasena: 'prueba');
    auth.respuesta.completeError(FirebaseAuthException(
      code: 'unknown',
      message: 'An internal error has occurred. [ Connection reset ]',
    ));
    await intento;
    expect(controlador.cargando, isFalse);
    expect(controlador.mensajeError, contains('conexion con Firebase se interrumpio'));
    expect(controlador.mensajeError, isNot(contains('credenciales')));
    controlador.dispose();
  });

  testWidgets('avisa la demora sin duplicar solicitudes y acepta respuesta tardia', (tester) async {
    final auth = _AuthPendiente();
    final controlador = ControladorInicioSesion(iniciarSesion: IniciarSesion(auth));
    final intento = controlador.iniciarSesion(correo: 'prueba@example.com', contrasena: 'prueba');
    await tester.pump(const Duration(seconds: 30));
    expect(controlador.mensajeError, contains('Seguimos esperando'));
    expect(controlador.cargando, isTrue);
    await controlador.iniciarSesion(correo: 'otra@example.com', contrasena: 'otra');
    expect(auth.solicitudes, 1);
    auth.respuesta.complete();
    await intento;
    expect(controlador.cargando, isFalse);
    expect(controlador.mensajeError, isNull);
    controlador.dispose();
  });

  testWidgets('un error tardio desbloquea el formulario', (tester) async {
    final auth = _AuthPendiente();
    final controlador = ControladorInicioSesion(iniciarSesion: IniciarSesion(auth));
    final intento = controlador.iniciarSesion(correo: 'prueba@example.com', contrasena: 'prueba');
    await tester.pump(const Duration(seconds: 30));
    auth.respuesta.completeError(FirebaseAuthException(code: 'network-request-failed'));
    await intento;
    expect(controlador.cargando, isFalse);
    expect(controlador.mensajeError, contains('Revisa tu internet'));
    controlador.dispose();
  });

  testWidgets('cerrar la pantalla cancela el aviso y admite finalizacion posterior', (tester) async {
    final auth = _AuthPendiente();
    final controlador = ControladorInicioSesion(iniciarSesion: IniciarSesion(auth));
    final intento = controlador.iniciarSesion(correo: 'prueba@example.com', contrasena: 'prueba');
    controlador.dispose();
    await tester.pump(const Duration(seconds: 31));
    auth.respuesta.complete();
    await expectLater(intento, completes);
    expect(tester.takeException(), isNull);
  });
}
