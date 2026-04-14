import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos para recuperar sedes desde Firestore.
class FuenteDatosSedesFirestore {
  FuenteDatosSedesFirestore({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> obtenerSedePorId(String id) async {
    final documento =
        await _firestore.collection(ColeccionesFirebase.sedes).doc(id).get();

    return documento.data();
  }

  Future<void> guardarSede({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _firestore.collection(ColeccionesFirebase.sedes).doc(id).set(datos);
  }
}
