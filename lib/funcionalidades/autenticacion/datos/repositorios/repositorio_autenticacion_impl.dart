import '../../dominio/repositorios/repositorio_autenticacion.dart';
import '../fuentes_datos/fuente_datos_autenticacion_firebase.dart';

// Implementacion del contrato de autenticacion usando Firebase Auth.
class RepositorioAutenticacionImpl implements RepositorioAutenticacion {
  RepositorioAutenticacionImpl(this._fuenteDatos);

  final FuenteDatosAutenticacionFirebase _fuenteDatos;

  @override
  Stream<bool> sesionIniciada() {
    return _fuenteDatos.sesionIniciada();
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _fuenteDatos.iniciarSesion(
      correo: correo,
      contrasena: contrasena,
    );
  }

  @override
  Future<void> cerrarSesion() {
    return _fuenteDatos.cerrarSesion();
  }
}
