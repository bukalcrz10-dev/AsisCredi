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
      mensajeError = 'Ingresa correo y contrasena.';
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
          'No se pudo iniciar sesion. Verifica el correo, la contrasena y Firebase Auth.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
