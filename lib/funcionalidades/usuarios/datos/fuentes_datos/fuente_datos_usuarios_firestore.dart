import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos de usuarios en Firestore.
// Esta capa solo se ocupa de leer el documento del perfil desde la coleccion usuarios.
class FuenteDatosUsuariosFirestore {
  FuenteDatosUsuariosFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String id) async {
    final documento = await _firestore
        .collection(ColeccionesFirebase.usuarios)
        .doc(id)
        .get();

    return documento.data();
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>> obtenerUsuarios() async {
    final consulta = await _firestore
        .collection(ColeccionesFirebase.usuarios)
        .orderBy('nombreCompleto')
        .get();

    return consulta.docs
        .map((documento) => MapEntry(documento.id, documento.data()))
        .toList();
  }

  Future<void> guardarUsuario({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _firestore
        .collection(ColeccionesFirebase.usuarios)
        .doc(id)
        .set(datos);
  }

  // Actualiza únicamente el perfil, sin reemplazar fotografía, permisos o sede.
  Future<void> actualizarDatosLaborales({
    required String id,
    required String nombreCompleto,
    required String telefono,
    required String area,
    required String cargo,
    String? sedeAsignadaId,
  }) {
    final datos = <String, dynamic>{
      'nombreCompleto': nombreCompleto,
      'telefono': telefono,
      'area': area,
      'cargo': cargo,
    };

    if (sedeAsignadaId != null) {
      datos['sedeAsignadaId'] = sedeAsignadaId;
    }

    return _firestore.collection(ColeccionesFirebase.usuarios).doc(id).update(
      datos,
    );
  }
}
