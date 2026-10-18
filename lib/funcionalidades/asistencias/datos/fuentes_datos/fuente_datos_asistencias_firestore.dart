import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/fecha_asistencia_invalida.dart';

import '../../../../nucleo/constantes/colecciones_firebase.dart';

// Fuente de datos concreta para Firestore.
// Esta capa se encarga solo del acceso directo a Firebase y no conoce
// pantallas ni reglas de interfaz.
class FuenteDatosAsistenciasFirestore {
  FuenteDatosAsistenciasFirestore({
    FirebaseFirestore? firestore,
    this.guardarConSeguridad,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Future<void> Function(String, Map<String, dynamic>)?
  guardarConSeguridad;

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
    if (guardarConSeguridad != null) return guardarConSeguridad!(id, datos);
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
    // También cubre escrituras persistidas antes de cerrar/reabrir la app.
    // Una lectura de servidor puede incluir cambios locales pendientes: no los
    // mostramos como confirmados ni permitimos reintentar hasta resolverlos.
    await _firestore.waitForPendingWrites().timeout(
      const Duration(seconds: 20),
    );
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
    final documentos = <MapEntry<String, Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final pagina = await obtenerPaginaAsistencias(
        limite: 300,
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

  Future<PaginaAsistenciasFirestore> obtenerPaginaAsistencias({
    int limite = 50,
    bool completarUltimoDia = false,
    DateTime? desde,
    DateTime? hastaExclusiva,
    QueryDocumentSnapshot<Map<String, dynamic>>? despuesDe,
  }) async {
    Query<Map<String, dynamic>> consulta = _firestore
        .collection(ColeccionesFirebase.asistencias)
        .orderBy('fechaHora', descending: true);
    if (desde != null) {
      consulta = consulta.where(
        'fechaHora',
        isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
      );
    }
    if (hastaExclusiva != null) {
      consulta = consulta.where(
        'fechaHora',
        isLessThan: Timestamp.fromDate(hastaExclusiva),
      );
    }
    if (despuesDe != null) consulta = consulta.startAfterDocument(despuesDe);
    final opciones = GetOptions(
      source: completarUltimoDia ? Source.server : Source.serverAndCache,
    );
    final resultado = await consulta.limit(limite).get(opciones);
    final documentos = resultado.docs.toList();
    if (completarUltimoDia && documentos.length == limite) {
      final ultimo = documentos.last;
      final timestamp = ultimo.data()['fechaHora'];
      if (timestamp is! Timestamp) throw FechaAsistenciaInvalida(ultimo.id);
      final fecha = timestamp.toDate();
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = DateTime(fecha.year, fecha.month, fecha.day + 1);
      // La página termina al finalizar un día, nunca a mitad de una jornada.
      // Releer ese día completo evita evaluar o regularizar grupos parciales.
      final diaCompleto = await _firestore
          .collection(ColeccionesFirebase.asistencias)
          .orderBy('fechaHora', descending: true)
          .where(
            'fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              desde != null && desde.isAfter(inicioDia) ? desde : inicioDia,
            ),
          )
          .where(
            'fechaHora',
            isLessThan: Timestamp.fromDate(
              hastaExclusiva != null && hastaExclusiva.isBefore(finDia)
                  ? hastaExclusiva
                  : finDia,
            ),
          )
          .get(opciones);
      if (diaCompleto.docs.isEmpty) {
        throw StateError(
          'La jornada cambió durante la consulta. Actualiza la lista.',
        );
      }
      // Conservar los días más recientes en orden descendente y reemplazar solo
      // el día del límite; sus documentos determinan el siguiente cursor.
      documentos
        ..clear()
        ..addAll(
          resultado.docs.where((doc) {
            final valor = doc.data()['fechaHora'];
            return valor is! Timestamp || !valor.toDate().isBefore(finDia);
          }),
        )
        ..addAll(diaCompleto.docs);
    }
    return PaginaAsistenciasFirestore(
      documentos: documentos,
      ultimoDocumento: documentos.isEmpty ? despuesDe : documentos.last,
      hayMas: resultado.docs.length == limite,
    );
  }
}

class PaginaAsistenciasFirestore {
  const PaginaAsistenciasFirestore({
    required this.documentos,
    required this.ultimoDocumento,
    required this.hayMas,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos;
  final QueryDocumentSnapshot<Map<String, dynamic>>? ultimoDocumento;
  final bool hayMas;
}
