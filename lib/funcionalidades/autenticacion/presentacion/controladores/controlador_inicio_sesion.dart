import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../dominio/casos_de_uso/iniciar_sesion.dart';

// Controlador de la pantalla de acceso.
// Gestiona el formulario y el estado visual del intento de inicio de sesion.
class ControladorInicioSesion extends ChangeNotifier {
  ControladorInicioSesion({
    required IniciarSesion iniciarSesion,
    this.iniciarConPolitica,
  }) : _iniciarSesion = iniciarSesion;

  final IniciarSesion _iniciarSesion;
  final Future<void> Function(bool mantener, Future<void> Function() ingresar)? iniciarConPolitica;
  bool mantenerSesion = false;

  void cambiarMantenerSesion(bool valor) {
    if (cargando) return;
    _actualizarEstado(() => mantenerSesion = valor);
  }
  Timer? _avisoDemora;
  bool _cerrado = false;

  bool cargando = false;
  String? mensajeError;

  void _actualizarEstado(VoidCallback accion) {
    if (_cerrado) return;
    accion();
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _avisoDemora?.cancel();
    super.dispose();
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
    if (_cerrado || cargando) return;
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

    // Un timeout del Future no cancela la solicitud nativa de Firebase.
    // Avisamos sin permitir otro intento simultaneo que pueda cambiar la cuenta.
    _avisoDemora = Timer(const Duration(seconds: 30), () {
      _mostrarError(
        'La respuesta esta tardando mas de lo esperado. Seguimos esperando. '
        'Revisa tu conexion; si continua asi, cierra completamente la APP '
        'y vuelve a abrirla para reintentar.',
      );
    });
    try {
      Future<void> ingresar() => _iniciarSesion.ejecutar(
        correo: correo.trim(),
        contrasena: contrasena,
      );
      if (iniciarConPolitica != null) {
        await iniciarConPolitica!(mantenerSesion, ingresar);
      } else {
        await ingresar();
      }
      mensajeError = null;
    } on FirebaseAuthException catch (error) {
      mensajeError = _traducirErrorFirebase(error);
    } catch (_) {
      mensajeError =
          'No pudimos iniciar sesion en este momento. Intenta nuevamente en unos segundos.';
    } finally {
      _avisoDemora?.cancel();
      _actualizarEstado(() {
        cargando = false;
      });
    }
  }

  String _traducirErrorFirebase(FirebaseAuthException error) {
    final detalle = error.message?.toLowerCase() ?? '';
    if ((error.code == 'unknown' || error.code == 'internal-error') &&
        detalle.contains('connection reset')) {
      return 'La conexion con Firebase se interrumpio. Comprueba que puedes '
          'abrir paginas web con esta red y vuelve a intentar.';
    }
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
