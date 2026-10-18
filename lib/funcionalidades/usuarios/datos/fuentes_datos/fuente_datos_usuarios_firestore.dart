import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos de usuarios en Firestore.
// Esta capa solo se ocupa de leer el documento del perfil desde la coleccion usuarios.
class FuenteDatosUsuariosFirestore {
  FuenteDatosUsuariosFirestore({
    FirebaseFirestore? firestore,
    this.soloServidor = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final bool soloServidor;

  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String id) async {
    final documento = await _firestore
        .collection(ColeccionesFirebase.usuarios)
        .doc(id)
        .get(
          GetOptions(
            source: soloServidor ? Source.server : Source.serverAndCache,
          ),
        );

    return documento.data();
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>> obtenerUsuarios() async {
    final documentos = <MapEntry<String, Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final pagina = await obtenerPaginaUsuarios(
        limite: 100,
        despuesDe: cursor,
      );
      documentos.addAll(
        pagina.documentos.map(
          (documento) => MapEntry(documento.id, documento.data()),
        ),
      );
      if (!pagina.hayMas) break;
      cursor = pagina.ultimoDocumento;
    }
    return documentos;
  }

  Future<PaginaUsuariosFirestore> obtenerPaginaUsuarios({
    int limite = 30,
    QueryDocumentSnapshot<Map<String, dynamic>>? despuesDe,
  }) async {
    Query<Map<String, dynamic>> consulta = _firestore
        .collection(ColeccionesFirebase.usuarios)
        .orderBy(FieldPath.documentId);
    if (despuesDe != null) consulta = consulta.startAfterDocument(despuesDe);
    final resultado = await consulta.limit(limite).get();
    return PaginaUsuariosFirestore(
      documentos: resultado.docs,
      ultimoDocumento: resultado.docs.isEmpty ? despuesDe : resultado.docs.last,
      hayMas: resultado.docs.length == limite,
    );
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

    return _firestore
        .collection(ColeccionesFirebase.usuarios)
        .doc(id)
        .update(datos);
  }
}

class PaginaUsuariosFirestore {
  const PaginaUsuariosFirestore({
    required this.documentos,
    required this.ultimoDocumento,
    required this.hayMas,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos;
  final QueryDocumentSnapshot<Map<String, dynamic>>? ultimoDocumento;
  final bool hayMas;
}
