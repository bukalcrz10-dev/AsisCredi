import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos concreta para Firestore.
// Esta capa se encarga solo del acceso directo a Firebase y no conoce
// pantallas ni reglas de interfaz.
class FuenteDatosAsistenciasFirestore {
  FuenteDatosAsistenciasFirestore({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Genera ids desde la coleccion real para que el documento y la entidad
  // compartan la misma referencia desde el momento de guardado.
  String crearId() {
    return _firestore.collection(ColeccionesFirebase.asistencias).doc().id;
  }

  // Guarda el mapa listo para Firestore en la coleccion de asistencias.
  Future<void> guardarAsistencia({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _firestore
        .collection(ColeccionesFirebase.asistencias)
        .doc(id)
        .set(datos);
  }

  // Consulta las asistencias del trabajador ordenadas desde la mas reciente.
  Future<List<MapEntry<String, Map<String, dynamic>>>> obtenerAsistenciasPorUsuario(
    String usuarioId,
  ) async {
    final consulta = await _firestore
        .collection(ColeccionesFirebase.asistencias)
        .where('usuarioId', isEqualTo: usuarioId)
        .get();

    return consulta.docs
        .map((documento) => MapEntry(documento.id, documento.data()))
        .toList();
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>> obtenerAsistencias() async {
    final consulta = await _firestore
        .collection(ColeccionesFirebase.asistencias)
        .orderBy('fechaHora', descending: true)
        .limit(300)
        .get();

    return consulta.docs
        .map((documento) => MapEntry(documento.id, documento.data()))
        .toList();
  }
}
