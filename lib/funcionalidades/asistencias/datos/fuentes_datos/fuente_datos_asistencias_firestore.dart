import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos concreta para Firestore.
// Esta capa se encarga solo del acceso directo a Firebase y no conoce
// pantallas ni reglas de interfaz.
class FuenteDatosAsistenciasFirestore {
  FuenteDatosAsistenciasFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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

  // Lee todos los documentos antes de escribir: todo se confirma o nada cambia.
  Future<void> regularizarJornada({
    required Map<String, Map<String, dynamic>> esperados,
    required Map<String, Map<String, dynamic>> cambios,
  }) async {
    await _firestore.runTransaction((tx) async {
      final referencias = {
        for (final id in {...esperados.keys, ...cambios.keys})
          id: _firestore.collection(ColeccionesFirebase.asistencias).doc(id),
      };
      for (final entry in referencias.entries) {
        final actual = await tx.get(entry.value);
        final esperado = esperados[entry.key];
        if (esperado == null) {
          if (actual.exists) {
            throw StateError(
              'Otra operación ya registró una marca. Actualiza la lista antes de reintentar.',
            );
          }
        } else {
          final datos = actual.data();
          if (datos == null ||
              [
                'fechaHora',
                'usuarioId',
                'sedeId',
                'tipoMarcacion',
                'tipoHorario',
                'bloqueJornada',
                'observacion',
              ].any((campo) => datos[campo] != esperado[campo])) {
            throw StateError(
              'La jornada cambió. Cierra el diálogo y actualiza la lista.',
            );
          }
        }
      }
      for (final entry in cambios.entries) {
        if (esperados.containsKey(entry.key)) {
          tx.update(referencias[entry.key]!, entry.value);
        } else {
          tx.set(referencias[entry.key]!, entry.value);
        }
      }
    });
  }

  Future<void> eliminarAsistencia(String id) {
    return _firestore
        .collection(ColeccionesFirebase.asistencias)
        .doc(id)
        .delete();
  }

  // Consulta las asistencias del trabajador ordenadas desde la mas reciente.
  Future<List<MapEntry<String, Map<String, dynamic>>>>
  obtenerAsistenciasPorUsuario(String usuarioId) async {
    final consulta = await _firestore
        .collection(ColeccionesFirebase.asistencias)
        .where('usuarioId', isEqualTo: usuarioId)
        .get(const GetOptions(source: Source.server));

    return consulta.docs
        .map((documento) => MapEntry(documento.id, documento.data()))
        .toList();
  }

  Future<List<MapEntry<String, Map<String, dynamic>>>>
  obtenerAsistencias() async {
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
