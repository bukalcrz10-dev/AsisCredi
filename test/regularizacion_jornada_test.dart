// Dobles para comprobar transacciones sin modificar registros reales.
// ignore_for_file: subtype_of_sealed_class
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/regularizacion_jornada.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';

Asistencia marca(
  String id,
  TipoMarcacion tipo,
  int h,
  int m, {
  String? horario = 'asesor',
  String? bloque = 'manana',
  int segundos = 0,
}) => Asistencia(
  id: id,
  usuarioId: 'u1',
  nombreUsuario: 'Ana',
  sedeId: 'satipo',
  tipoMarcacion: tipo,
  fechaHora: DateTime(2026, 9, 30, h, m, segundos),
  latitud: -11,
  longitud: -74,
  dentroDeZona: true,
  rostroValidado: true,
  tipoHorario: horario,
  bloqueJornada: bloque,
  urlEvidenciaFacial: 'foto-historica',
  correoNotificacion: 'ana@example.com',
  notificacionEnviada: true,
);
Map<String, String> horas(RegularizacionJornada j) => {
  for (final c in j.campos) j.clave(c): j.texto(c),
};

void main() {
  final entrada = marca('e', TipoMarcacion.entrada, 8, 40);
  final salida = marca('s', TipoMarcacion.salida, 18, 30);
  test(
    'Asesor tiene dos campos; corregir 08:40 a 08:30 conserva datos y recalcula tardanza',
    () {
      final j = RegularizacionJornada([entrada, salida]);
      expect(j.campos.length, 2);
      final cambios = j.preparar(horas(j)..['manana_entrada'] = '08:30');
      final corregida = ModeloAsistencia.desdeMapa(
        ModeloAsistencia.desdeEntidad(cambios.single).aMapa(),
        'e',
      ).aEntidad();
      expect(corregida.tipoHorario, 'asesor');
      expect(corregida.bloqueJornada, 'manana');
      expect(corregida.usuarioId, entrada.usuarioId);
      expect(corregida.sedeId, 'satipo');
      expect(corregida.latitud, entrada.latitud);
      expect(corregida.urlEvidenciaFacial, entrada.urlEvidenciaFacial);
      expect(corregida.notificacionEnviada, true);
      final resumen = construirResumenJornadaTrabajador([
        corregida,
        salida,
      ], entrada.fechaHora);
      expect(resumen.tardanzaTotal, Duration.zero);
      expect(resumen.tiempoLaborado, const Duration(hours: 10));
    },
  );
  test('Plataforma completa cuatro campos y conserva ocho horas', () {
    final e = marca('e', TipoMarcacion.entrada, 8, 30, horario: 'plataforma');
    final j = RegularizacionJornada([e]);
    expect(j.campos.length, 4);
    final nuevas = j.preparar(
      horas(j)..addAll({
        'manana_salida': '13:00',
        'tarde_entrada': '15:00',
        'tarde_salida': '18:30',
      }),
    );
    expect(nuevas.every((a) => a.tipoHorario == 'plataforma'), true);
    expect(nuevas.last.bloqueJornada, 'tarde');
    expect(nuevas.every((a) => !a.rostroValidado && !a.dentroDeZona), true);
    expect(
      construirResumenJornadaTrabajador([
        e,
        ...nuevas,
      ], e.fechaHora).tiempoLaborado,
      const Duration(hours: 8),
    );
  });
  test(
    'no elimina segundos ni genera cambios cuando no se modifica la hora',
    () {
      final j = RegularizacionJornada([
        marca('e', TipoMarcacion.entrada, 8, 30, segundos: 42),
        salida,
      ]);
      expect(j.preparar(horas(j)), isEmpty);
    },
  );
  test('rechaza horas inválidas, salida anterior y borrado de marca', () {
    final j = RegularizacionJornada([entrada, salida]);
    for (final valor in ['25:00', '08:60', 'texto', '']) {
      expect(
        () => j.preparar(horas(j)..['manana_entrada'] = valor),
        throwsFormatException,
      );
    }
    expect(
      () => j.preparar(horas(j)..['manana_salida'] = '08:00'),
      throwsFormatException,
    );
  });
  test(
    'histórico sin etiquetas conserva ausencia de etiquetas y no agrega marcas por suposición',
    () {
      final j = RegularizacionJornada([
        marca('e', TipoMarcacion.entrada, 8, 40, horario: null, bloque: null),
      ]);
      final editada = j.preparar(horas(j)..['manana_entrada'] = '08:30').single;
      expect(editada.tipoHorario, isNull);
      expect(editada.bloqueJornada, isNull);
      expect(
        () => j.preparar(horas(j)..['manana_salida'] = '13:00'),
        throwsFormatException,
      );
      expect(
        () => j.preparar(horas(j)..['manana_entrada'] = '15:00'),
        throwsFormatException,
      );
    },
  );
  test(
    'no permite reinterpretar jornadas con horarios mezclados o duplicados',
    () {
      expect(
        () => RegularizacionJornada([
          entrada,
          marca('otra', TipoMarcacion.entrada, 9, 0),
        ]),
        throwsFormatException,
      );
      expect(
        () => RegularizacionJornada([
          entrada,
          marca('s', TipoMarcacion.salida, 18, 30, horario: 'plataforma'),
        ]),
        throwsFormatException,
      );
    },
  );
  test(
    'la transacción actualiza solo hora/nota y conserva campos desconocidos',
    () async {
      final db = _Db();
      db.datos['e'] = ModeloAsistencia.desdeEntidad(entrada).aMapa()
        ..['campoFuturo'] = 'conservar';
      db.datos['s'] = ModeloAsistencia.desdeEntidad(salida).aMapa();
      final repo = RepositorioAsistenciasImpl(
        FuenteDatosAsistenciasFirestore(firestore: db),
      );
      final j = RegularizacionJornada([entrada, salida]);
      await repo.regularizarJornada(
        originales: j.originales,
        actualizadas: j.preparar(horas(j)..['manana_entrada'] = '08:30'),
      );
      expect(db.datos['e']!['campoFuturo'], 'conservar');
      expect(db.datos['e']!['tipoHorario'], 'asesor');
      expect(db.datos['e']!['bloqueJornada'], 'manana');
      expect((db.datos['e']!['fechaHora'] as Timestamp).toDate().minute, 30);
      expect(db.confirmaciones, 1);
    },
  );
  test('conflicto en otra marca cancela toda la corrección', () async {
    final db = _Db();
    db.datos['e'] = ModeloAsistencia.desdeEntidad(entrada).aMapa();
    db.datos['s'] = ModeloAsistencia.desdeEntidad(salida).aMapa()
      ..['fechaHora'] = Timestamp.fromDate(DateTime(2026, 9, 30, 19));
    final j = RegularizacionJornada([entrada, salida]);
    final repo = RepositorioAsistenciasImpl(
      FuenteDatosAsistenciasFirestore(firestore: db),
    );
    await expectLater(
      repo.regularizarJornada(
        originales: j.originales,
        actualizadas: j.preparar(horas(j)..['manana_entrada'] = '08:30'),
      ),
      throwsStateError,
    );
    expect((db.datos['e']!['fechaHora'] as Timestamp).toDate().minute, 40);
    expect(db.confirmaciones, 0);
  });
  test(
    'marca nueva usa ID determinista; un reintento no sobrescribe otra marca',
    () async {
      final db = _Db();
      db.datos['e'] = ModeloAsistencia.desdeEntidad(entrada).aMapa();
      final j = RegularizacionJornada([entrada]);
      final nuevas = j.preparar(horas(j)..['manana_salida'] = '18:30');
      final repo = RepositorioAsistenciasImpl(
        FuenteDatosAsistenciasFirestore(firestore: db),
      );
      await repo.regularizarJornada(
        originales: j.originales,
        actualizadas: nuevas,
      );
      expect(db.datos.containsKey(idMarcacionPorBloque(nuevas.single)), true);
      await expectLater(
        repo.regularizarJornada(originales: j.originales, actualizadas: nuevas),
        throwsStateError,
      );
      expect(db.datos.length, 2);
    },
  );
}

class _Db extends Fake implements FirebaseFirestore {
  final datos = <String, Map<String, dynamic>>{};
  int confirmaciones = 0;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Col(this);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final tx = _Tx(this);
    final resultado = await handler(tx);
    for (final escribir in tx.escrituras) {
      escribir();
    }
    confirmaciones++;
    return resultado;
  }
}

class _Col extends Fake implements CollectionReference<Map<String, dynamic>> {
  _Col(this.db);
  final _Db db;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Doc(db, path!);
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.db, this.id);
  final _Db db;
  @override
  final String id;
}

class _Snap extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snap(this.valor);
  final Map<String, dynamic>? valor;
  @override
  bool get exists => valor != null;
  @override
  Map<String, dynamic>? data() => valor;
}

class _Tx extends Fake implements Transaction {
  _Tx(this.db);
  final _Db db;
  final escrituras = <void Function()>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    expect(
      escrituras,
      isEmpty,
      reason: 'Todas las lecturas deben preceder las escrituras',
    );
    return _Snap(db.datos[ref.id]) as DocumentSnapshot<T>;
  }

  @override
  Transaction update(DocumentReference ref, Map<String, dynamic> data) {
    escrituras.add(() => db.datos[ref.id]!.addAll(data));
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    escrituras.add(
      () => db.datos[ref.id] = Map<String, dynamic>.from(data as Map),
    );
    return this;
  }
}
