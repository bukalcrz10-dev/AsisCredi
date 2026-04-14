import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos para registrar alertas en Firestore.
class FuenteDatosAlertasFirestore {
  FuenteDatosAlertasFirestore({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String crearId() {
    return _firestore.collection(ColeccionesFirebase.alertas).doc().id;
  }

  Future<void> guardarAlerta({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _firestore.collection(ColeccionesFirebase.alertas).doc(id).set(datos);
  }

  // Recupera las alertas del trabajador autenticado para poder mostrarlas
  // en la app sin obligarlo a revisar Firebase Console.
  Future<List<MapEntry<String, Map<String, dynamic>>>> obtenerAlertasPorUsuario(
    String usuarioId,
  ) async {
    final consulta = await _firestore
        .collection(ColeccionesFirebase.alertas)
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    return consulta.docs
        .map((documento) => MapEntry(documento.id, documento.data()))
        .toList();
  }
}
