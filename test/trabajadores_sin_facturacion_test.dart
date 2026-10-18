// Fakes locales para probar fallos entre Auth y Firestore sin cuentas reales.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/datos/servicios/servicio_trabajadores_firebase.dart';

void main() {
  late _Db db;
  late _Auth admin;
  late _Auth auxiliar;
  late ServicioTrabajadoresFirebase servicio;
  late bool liberada;
  setUp(() {
    db = _Db();
    admin = _Auth('admin');
    auxiliar = _Auth('nuevo');
    liberada = false;
    db.datos['admin'] = {'activo': true, 'rol': 'administrador'};
    servicio = ServicioTrabajadoresFirebase(
      auth: admin,
      firestore: db,
      abrirSesionAlta: () async => SesionAltaTrabajador(auxiliar, () async {
        liberada = true;
      }),
    );
  });
  Future<String> crear() => servicio.crearTrabajadorConAcceso(
    nombreCompleto: 'Ana',
    correo: 'ana@example.com',
    telefono: '',
    area: '',
    cargo: 'Asesor',
    rol: 'Trabajador',
    activo: true,
    sedeAsignadaId: 'satipo',
    password: 'clave segura',
  );
  Future<void> editar({
    String uid = 'nuevo',
    String correo = 'ana@example.com',
    bool activo = false,
    String rol = 'Trabajador',
  }) => servicio.actualizarTrabajador(
    uid: uid,
    nombreCompleto: 'Ana',
    correo: correo,
    telefono: '',
    area: '',
    cargo: 'Plataforma',
    rol: rol,
    activo: activo,
    sedeAsignadaId: 'huancayo',
  );
  Matcher codigo(String valor) =>
      isA<FirebaseAuthException>().having((e) => e.code, 'code', valor);

  test(
    'crea perfil con UID Auth y conserva sesión admin; no almacena contraseña',
    () async {
      expect(await crear(), 'nuevo');
      expect(admin.currentUser!.uid, 'admin');
      expect(admin.altas, 0);
      expect(db.datos['nuevo']?['sedeAsignadaId'], 'satipo');
      expect(db.datos['nuevo']?['rol'], 'trabajador');
      expect(db.datos['nuevo']!.containsKey('password'), false);
      expect(auxiliar.salidas, 1);
      expect(liberada, true);
      expect(db.datos.keys.toSet(), {'admin', 'nuevo'});
    },
  );
  test('no crea cuentas si el operador no es administrador activo', () async {
    db.datos['admin']!['activo'] = false;
    await expectLater(crear(), throwsA(codigo('permission-denied')));
    expect(auxiliar.altas, 0);
  });
  test('una cuenta existente con perfil nunca se sobrescribe', () async {
    auxiliar.duplicada = true;
    db.datos['nuevo'] = {'nombreCompleto': 'Original', 'rol': 'administrador'};
    await expectLater(crear(), throwsA(codigo('profile-already-exists')));
    expect(db.datos['nuevo']?['nombreCompleto'], 'Original');
    expect(liberada, true);
  });
  test(
    'recupera un alta incompleta después de un fallo de Firestore',
    () async {
      db.falla = true;
      await expectLater(crear(), throwsA(codigo('profile-save-unconfirmed')));
      expect(auxiliar.eliminaciones, 0);
      expect(liberada, true);
      db.falla = false;
      auxiliar.duplicada = true;
      expect(await crear(), 'nuevo');
      expect(auxiliar.ingresos, 1);
    },
  );
  test('no recupera cuentas existentes sin demostrar la contraseña', () async {
    auxiliar.duplicada = true;
    auxiliar.claveIncorrecta = true;
    await expectLater(crear(), throwsA(codigo('invalid-credential')));
    expect(db.datos.containsKey('nuevo'), false);
    expect(liberada, true);
  });
  test(
    'activa/desactiva perfil y cambia sede conservando fotografía e historial',
    () async {
      db.datos['nuevo'] = {
        'correo': 'ana@example.com',
        'urlFotoFacial': 'foto',
        'activo': true,
      };
      await editar();
      expect(
        db.datos.values.any((d) => d['tipo'] == 'editar_trabajador'),
        isFalse,
      );
      expect(db.datos['nuevo']?['activo'], false);
      expect(db.datos['nuevo']?['cargo'], 'Plataforma');
      expect(db.datos['nuevo']?['sedeAsignadaId'], 'huancayo');
      expect(db.datos['nuevo']?['urlFotoFacial'], 'foto');
      await editar(activo: true);
      expect(db.datos['nuevo']?['activo'], true);
    },
  );
  test('impide cambiar únicamente el correo del perfil', () async {
    db.datos['nuevo'] = {'correo': 'ana@example.com'};
    await expectLater(
      editar(correo: 'otro@example.com'),
      throwsA(codigo('email-change-not-supported')),
    );
    expect(db.datos['nuevo']?['correo'], 'ana@example.com');
  });
  test('impide que admin se quite su propio acceso', () async {
    db.datos['admin']!['correo'] = 'ana@example.com';
    await expectLater(
      editar(uid: 'admin'),
      throwsA(codigo('self-access-change')),
    );
    expect(db.datos['admin']?['activo'], true);
  });
  test(
    'restablece mediante correo del perfil, sin elegir contraseña ajena',
    () async {
      db.datos['nuevo'] = {'correo': 'ana@example.com'};
      await servicio.restablecerContrasenaTrabajador(uid: 'nuevo');
      expect(admin.correoReset, 'ana@example.com');
      expect(admin.currentUser!.uid, 'admin');
    },
  );
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(String uid) : usuario = _User(uid);
  final _User usuario;
  bool duplicada = false, claveIncorrecta = false;
  int altas = 0, ingresos = 0, salidas = 0, eliminaciones = 0;
  String? correoReset;
  @override
  User? get currentUser => usuario;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    altas++;
    if (duplicada) throw FirebaseAuthException(code: 'email-already-in-use');
    return _Credencial(usuario);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    ingresos++;
    if (claveIncorrecta) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return _Credencial(usuario);
  }

  @override
  Future<void> signOut() async {
    salidas++;
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {}
  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    correoReset = email;
  }
}

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  String get email => 'ana@example.com';
}

class _Credencial extends Fake implements UserCredential {
  _Credencial(this.user);
  @override
  final User user;
}

class _Db extends Fake implements FirebaseFirestore {
  final datos = <String, Map<String, dynamic>>{};
  int siguienteAuditoria = 0;
  bool falla = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Coleccion(this);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (falla) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return transactionHandler(_Transaccion(this));
  }
}

class _Coleccion extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Coleccion(this.db);
  final _Db db;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Documento(db, path ?? 'auditoria-${db.siguienteAuditoria++}');
}

class _Documento extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Documento(this.db, this.id);
  final _Db db;
  @override
  final String id;
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(db.datos[id]);
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.valor);
  final Map<String, dynamic>? valor;
  @override
  bool get exists => valor != null;
  @override
  Map<String, dynamic>? data() => valor;
}

class _Transaccion extends Fake implements Transaction {
  _Transaccion(this.db);
  final _Db db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async => _Snapshot(db.datos[documentReference.id]) as DocumentSnapshot<T>;
  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    db.datos[documentReference.id] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  Transaction update(
    DocumentReference documentReference,
    Map<String, dynamic> data,
  ) {
    db.datos[documentReference.id]!.addAll(data);
    return this;
  }
}
