// Dobles de consulta: no acceden a Firebase ni modifican datos reales.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/evaluacion_asistencia_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/regularizacion_jornada.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;

void main() {
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    test(
      '$horario: completa jornada cortada y avanza sin duplicados',
      () async {
        final db = _Db();
        for (final dia in [8, 9, 10]) {
          for (final marca in fixtures.jornada(horario, dia: dia)) {
            db.documentos.add(
              _Doc(
                '$dia-${marca.id}',
                ModeloAsistencia.desdeEntidad(marca).aMapa(),
              ),
            );
          }
        }
        final repo = RepositorioAsistenciasImpl(
          FuenteDatosAsistenciasFirestore(firestore: db),
        );
        // Dos marcas del sábado y solo una del viernes caben en este límite.
        final primera = await repo.obtenerPaginaAsistencias(limite: 3);
        final viernes = primera.asistencias
            .where((a) => a.fechaHora.day == 9)
            .toList();
        expect(viernes.length, horario == TipoHorarioPersonal.asesor ? 2 : 4);
        expect(
          EvaluacionAsistenciaAdmin(viernes, DateTime(2026, 10, 9)).estado,
          'Correcta',
        );
        final regularizacion = RegularizacionJornada(viernes);
        expect(
          regularizacion.campos.every(
            (c) => regularizacion.existente(c) != null,
          ),
          isTrue,
        );
        final segunda = await repo.obtenerPaginaAsistencias(
          limite: 3,
          despuesDe: primera.ultimoDocumento,
        );
        final ids = [
          ...primera.asistencias,
          ...segunda.asistencias,
        ].map((a) => a.id).toList();
        expect(ids.toSet().length, db.documentos.length);
        expect(ids.length, db.documentos.length);
        expect(segunda.asistencias.every((a) => a.fechaHora.day == 8), isTrue);
        expect(db.fuentes.every((s) => s == Source.server), isTrue);
      },
    );
  }

  test(
    'respeta fechas y no entrega una página parcial si falla completar el día',
    () async {
      final db = _Db();
      for (final dia in [8, 9, 10]) {
        for (final marca in fixtures.jornada(
          TipoHorarioPersonal.plataforma,
          dia: dia,
        )) {
          db.documentos.add(
            _Doc(
              '$dia-${marca.id}',
              ModeloAsistencia.desdeEntidad(marca).aMapa(),
            ),
          );
        }
      }
      final repo = RepositorioAsistenciasImpl(
        FuenteDatosAsistenciasFirestore(firestore: db),
      );
      final pagina = await repo.obtenerPaginaAsistencias(
        limite: 1,
        desde: DateTime(2026, 10, 9),
        hastaExclusiva: DateTime(2026, 10, 10),
      );
      expect(pagina.asistencias, hasLength(4));
      expect(pagina.asistencias.every((a) => a.fechaHora.day == 9), isTrue);
      db.fallarDia = true;
      await expectLater(
        repo.obtenerPaginaAsistencias(limite: 1),
        throwsStateError,
      );
    },
  );

  test('lista vacía y última página pequeña', () async {
    final db = _Db();
    final repo = RepositorioAsistenciasImpl(
      FuenteDatosAsistenciasFirestore(firestore: db),
    );
    expect((await repo.obtenerPaginaAsistencias()).asistencias, isEmpty);
    final marca = fixtures.jornada(TipoHorarioPersonal.asesor).first;
    db.documentos.add(
      _Doc('entrada', ModeloAsistencia.desdeEntidad(marca).aMapa()),
    );
    final pagina = await repo.obtenerPaginaAsistencias();
    expect(pagina.hayMas, isFalse);
    expect(pagina.asistencias, hasLength(1));
    expect(
      EvaluacionAsistenciaAdmin(pagina.asistencias, marca.fechaHora).estado,
      'Pendiente',
    );
  });
}

class _Db extends Fake implements FirebaseFirestore {
  final documentos = <_Doc>[];
  final fuentes = <Source>[];
  bool fallarDia = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Query(this);
}

class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Doc(this.id, this.valor);
  @override
  final String id;
  final Map<String, dynamic> valor;
  @override
  Map<String, dynamic> data() => valor;
  DateTime get fecha => (valor['fechaHora'] as Timestamp).toDate();
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

// El doble acumula restricciones; no es una consulta real inmutable del SDK.
// ignore: must_be_immutable
class _Query extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Query(this.db);
  final _Db db;
  DateTime? desde, hasta;
  String? cursor;
  int? maximo;
  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    if (isGreaterThanOrEqualTo != null) {
      desde = (isGreaterThanOrEqualTo as Timestamp).toDate();
    }
    if (isLessThan != null) hasta = (isLessThan as Timestamp).toDate();
    return this;
  }

  @override
  Query<Map<String, dynamic>> startAfterDocument(
    DocumentSnapshot documentSnapshot,
  ) {
    cursor = documentSnapshot.id;
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    maximo = limit;
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    db.fuentes.add(options?.source ?? Source.serverAndCache);
    if (db.fallarDia && maximo == null) throw StateError('Sin conexión');
    var filas =
        db.documentos
            .where(
              (d) =>
                  (desde == null || !d.fecha.isBefore(desde!)) &&
                  (hasta == null || d.fecha.isBefore(hasta!)),
            )
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    if (cursor != null) {
      filas = filas.skip(filas.indexWhere((d) => d.id == cursor) + 1).toList();
    }
    return _Snapshot(filas.take(maximo ?? filas.length).toList());
  }
}
