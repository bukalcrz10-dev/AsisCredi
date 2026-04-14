import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos de usuarios en Firestore.
// Esta capa solo se ocupa de leer el documento del perfil desde la coleccion usuarios.
class FuenteDatosUsuariosFirestore {
  FuenteDatosUsuariosFirestore({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String id) async {
    final documento =
        await _firestore.collection(ColeccionesFirebase.usuarios).doc(id).get();

    return documento.data();
  }

  Future<void> guardarUsuario({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _firestore.collection(ColeccionesFirebase.usuarios).doc(id).set(datos);
  }
}
