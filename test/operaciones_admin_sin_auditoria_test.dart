// Dobles transaccionales: los cambios se aplican solo si toda la operación termina.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/datos/servicios/servicio_sedes_admin.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/seguridad/servicio_biometria_admin.dart';
import 'package:asistencia_app/funcionalidades/reconocimiento_facial/seguridad/formato_referencia.dart';

void main() {
  test('guarda sede sin crear auditorías', () async {
    final db = _Db()
      ..datos['sedes/satipo'] = {
        'nombre': 'Satipo',
        'radioPermitidoMetros': 50,
      };
    await guardarSedeAdministrativa(
      id: 'satipo',
      datos: {'nombre': 'Satipo', 'radioPermitidoMetros': 80},
      firestore: db,
      usuarioActual: () => 'admin',
    );
    expect(db.datos['sedes/satipo']!['radioPermitidoMetros'], 80);
    expect(db.auditorias, isEmpty);
    expect(db.confirmaciones, 1);
  });
  test('un fallo de guardado no confirma la sede', () async {
    final db = _Db()..fallaSede = true;
    await expectLater(
      guardarSedeAdministrativa(
        id: 'satipo',
        datos: {'nombre': 'Satipo'},
        firestore: db,
        usuarioActual: () => 'admin',
      ),
      throwsStateError,
    );
    expect(db.datos, isEmpty);
    expect(db.confirmaciones, 0);
  });
  test(
    'habilitar aprobar y revocar conservan el control del dispositivo sin auditorías',
    () async {
      final db = _Db();
      final servicio = ServicioBiometriaAdmin(
        firestore: db,
        usuarioActual: () => 'admin',
      );
      await servicio.habilitar('u');
      expect(db.datos['configuracionBiometrica/u']!['estado'], 'pendiente');
      expect(db.datos['configuracionBiometrica/u']!['version'], 1);
      db.datos['credencialesBiometricas/secreto'] = {
        'usuarioId': 'u',
        'version': 1,
        'estado': 'pendiente',
        'vector': Blob(codificarReferencia(List.filled(128, 0.1))),
      };
      await servicio.aprobar('u', 'secreto');
      expect(db.datos['vinculosBiometricosPrivados/u']!['token'], 'secreto');
      expect(db.datos['configuracionBiometrica/u']!['estado'], 'activo');
      await expectLater(servicio.habilitar('u'), throwsA(isA<Exception>()));
      await servicio.revocarYEliminar('u');
      expect(db.datos['configuracionBiometrica/u']!['estado'], 'revocado');
      expect(db.datos['configuracionBiometrica/u']!['version'], 2);
      expect(db.datos.containsKey('credencialesBiometricas/secreto'), isFalse);
      expect(db.datos.containsKey('vinculosBiometricosPrivados/u'), isFalse);
      expect(db.auditorias, isEmpty);
    },
  );
  test('sin sesión no se confirma una autorización biométrica', () async {
    final db = _Db();
    final servicio = ServicioBiometriaAdmin(
      firestore: db,
      usuarioActual: () => null,
    );
    await expectLater(servicio.habilitar('u'), throwsStateError);
    expect(db.datos, isEmpty);
  });
}

class _Db extends Fake implements FirebaseFirestore {
  final datos = <String, Map<String, dynamic>>{};
  int confirmaciones = 0, contador = 0;
  bool fallaSede = false;
  Iterable<Map<String, dynamic>> get auditorias => datos.entries
      .where((e) => e.key.startsWith('auditoriaAdministrativa/'))
      .map((e) => e.value);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Col(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final tx = _Tx(this);
    final resultado = await handler(tx);
    for (final aplicar in tx.escrituras) {
      aplicar();
    }
    confirmaciones++;
    return resultado;
  }
}

class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Col(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Doc(db, '${this.path}/${path ?? 'audit-${db.contador++}'}');
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
  }) => _Query(db, path, field.toString(), isEqualTo);
}

class _Query extends Fake implements Query<Map<String, dynamic>> {
  _Query(this.db, this.path, this.campo, this.valor);
  final _Db db;
  final String path, campo;
  final Object? valor;
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _QuerySnap([
    for (final e in db.datos.entries)
      if (e.key.startsWith('$path/') && e.value[campo] == valor)
        _QueryDoc(db, e.key, Map.of(e.value)),
  ]);
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snap(db.datos[path]);
  @override
  Future<void> delete() async {
    db.datos.remove(path);
  }
}

class _Snap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snap(Map<String, dynamic>? datos)
    : valor = datos == null ? null : Map.of(datos);
  final Map<String, dynamic>? valor;
  @override
  Map<String, dynamic>? data() => valor == null ? null : Map.of(valor!);
}

class _QueryDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDoc(this.db, this.path, this.valor);
  final _Db db;
  final String path;
  final Map<String, dynamic> valor;
  @override
  Map<String, dynamic> data() => Map.of(valor);
  @override
  DocumentReference<Map<String, dynamic>> get reference => _Doc(db, path);
}

class _QuerySnap extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnap(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Tx extends Fake implements Transaction {
  _Tx(this.db);
  final _Db db;
  final escrituras = <void Function()>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    expect(escrituras, isEmpty, reason: 'Lecturas antes de escrituras');
    return _Snap(db.datos[ref.path]) as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    if (db.fallaSede && ref.path.startsWith('sedes/')) {
      throw StateError('Sede denegada');
    }
    final mapa = Map<String, dynamic>.from(data as Map);
    escrituras.add(() => db.datos[ref.path] = mapa);
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    escrituras.add(() => db.datos[ref.path]!.addAll(data));
    return this;
  }

  @override
  Transaction delete(DocumentReference ref) {
    escrituras.add(() => db.datos.remove(ref.path));
    return this;
  }
}
