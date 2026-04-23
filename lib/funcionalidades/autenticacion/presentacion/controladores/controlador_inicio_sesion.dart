import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../dominio/casos_de_uso/iniciar_sesion.dart';

// Controlador de la pantalla de acceso.
// Gestiona el formulario y el estado visual del intento de inicio de sesion.
class ControladorInicioSesion extends ChangeNotifier {
  ControladorInicioSesion({
    required IniciarSesion iniciarSesion,
  }) : _iniciarSesion = iniciarSesion;

  final IniciarSesion _iniciarSesion;

  bool cargando = false;
  String? mensajeError;

  void _actualizarEstado(VoidCallback accion) {
    accion();
    notifyListeners();
  }

  void _mostrarError(String mensaje) {
    _actualizarEstado(() {
      mensajeError = mensaje;
    });
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    if (correo.trim().isEmpty || contrasena.trim().isEmpty) {
      _mostrarError(
        'Completa tu correo institucional y tu contrasena para ingresar.',
      );
      return;
    }

    _actualizarEstado(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      await _iniciarSesion.ejecutar(
        correo: correo.trim(),
        contrasena: contrasena,
      );
    } on FirebaseAuthException catch (error) {
      mensajeError = _traducirErrorFirebase(error);
    } catch (_) {
      mensajeError =
          'No pudimos iniciar sesion en este momento. Intenta nuevamente en unos segundos.';
    } finally {
      _actualizarEstado(() {
        cargando = false;
      });
    }
  }

  String _traducirErrorFirebase(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato valido. Revisa que este bien escrito.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo en Firebase Authentication.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contrasena o el correo no coinciden con una cuenta registrada.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada y no puede iniciar sesion.';
      case 'too-many-requests':
        return 'Se bloquearon temporalmente los intentos. Espera un momento y vuelve a intentar.';
      case 'network-request-failed':
        return 'No pudimos conectarnos a Firebase. Revisa tu internet y vuelve a intentar.';
      default:
        return 'No pudimos iniciar sesion (${error.code}). Revisa tus credenciales o la configuracion de Firebase.';
    }
  }
}
