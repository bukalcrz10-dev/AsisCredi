import 'package:flutter/foundation.dart';

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

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    if (correo.trim().isEmpty || contrasena.trim().isEmpty) {
      mensajeError =
          'Completa tu correo institucional y tu contrasena para ingresar.';
      notifyListeners();
      return;
    }

    cargando = true;
    mensajeError = null;
    notifyListeners();

    try {
      await _iniciarSesion.ejecutar(
        correo: correo.trim(),
        contrasena: contrasena,
      );
    } catch (_) {
      mensajeError =
          'No pudimos iniciar sesion. Verifica tu correo, tu contrasena y que tu cuenta este habilitada.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
