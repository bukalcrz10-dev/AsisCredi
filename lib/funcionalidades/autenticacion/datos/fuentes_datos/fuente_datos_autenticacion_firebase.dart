import 'package:firebase_auth/firebase_auth.dart';

// Fuente de datos concreta basada en Firebase Auth.
// Esta capa solo se ocupa de hablar con el SDK de autenticacion.
class FuenteDatosAutenticacionFirebase {
  FuenteDatosAutenticacionFirebase({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<bool> sesionIniciada() {
    return _firebaseAuth.authStateChanges().map((usuario) => usuario != null);
  }

  User? obtenerUsuarioActual() => _firebaseAuth.currentUser;

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
  }

  Future<void> cerrarSesion() {
    return _firebaseAuth.signOut();
  }
}
