import 'package:firebase_auth/firebase_auth.dart';

/// La sesión se comprueba aquí; el rol activo se exige en las reglas de Firestore.
void exigirSesionAdministrativa({String? Function()? usuarioActual}) {
  final uid = (usuarioActual ?? () => FirebaseAuth.instance.currentUser?.uid)();
  if (uid == null || uid.trim().isEmpty) {
    throw StateError('No hay una sesión administrativa activa.');
  }
}
