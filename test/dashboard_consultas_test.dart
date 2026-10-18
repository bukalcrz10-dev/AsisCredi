// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/datos/servicios/servicio_dashboard_admin.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;

List<Asistencia> marcas(int dia, int trabajadores) => [
  for (var i = 0; i < trabajadores; i++)
    for (final marca in fixtures.jornada(
      TipoHorarioPersonal.plataforma,
      dia: dia,
    ))
      ModeloAsistencia.desdeMapa(
        ModeloAsistencia.desdeEntidad(marca).aMapa()..['usuarioId'] = 'u$i',
        '$dia-$i-${marca.id}',
      ).aEntidad(),
];

PaginaAsistencias pagina(List<Asistencia> marcas, {bool hayMas = false}) =>
    PaginaAsistencias(
      asistencias: marcas,
      ultimoDocumento: _Cursor(),
      hayMas: hayMas,
    );

void main() {
  final ahora = DateTime(2026, 10, 9, 20);
  test(
    'incluye todas las jornadas de hoy y no lee el historial si ya hay cuatro',
    () async {
      final hoy = marcas(9, 20);
      final repo = _Repo([pagina(hoy, hayMas: true)]);
      final resultado = await cargarMarcacionesDashboard(repo, ahora);
      expect(resultado, hasLength(80));
      expect(repo.consultas, hasLength(1));
      expect(repo.consultas.single.desde, DateTime(2026, 10, 9));
      expect(repo.consultas.single.hasta, DateTime(2026, 10, 10));
    },
  );
  test(
    'dos jornadas de hoy se completan con actividad anterior sin repetir hoy',
    () async {
      final repo = _Repo([
        pagina(marcas(9, 2)),
        pagina(marcas(8, 2), hayMas: true),
      ]);
      final resultado = await cargarMarcacionesDashboard(repo, ahora);
      expect(resultado, hasLength(16));
      expect(repo.consultas, hasLength(2));
      expect(repo.consultas.last.desde, isNull);
      expect(repo.consultas.last.hasta, DateTime(2026, 10, 9));
    },
  );
  test(
    'cuatro marcas de Plataforma son una jornada; sigue hasta cuatro jornadas',
    () async {
      final anterior = pagina(marcas(8, 1), hayMas: true);
      final repo = _Repo([
        pagina([]),
        anterior,
        pagina(marcas(7, 3), hayMas: true),
      ]);
      final resultado = await cargarMarcacionesDashboard(repo, ahora);
      expect(resultado, hasLength(16));
      expect(repo.consultas, hasLength(3));
      expect(repo.consultas.last.cursor, same(anterior.ultimoDocumento));
    },
  );
  test(
    'sin actividad devuelve vacío y termina al agotar la consulta',
    () async {
      final repo = _Repo([pagina([]), pagina([])]);
      expect(await cargarMarcacionesDashboard(repo, ahora), isEmpty);
      expect(repo.consultas, hasLength(2));
    },
  );
  test('propaga fallas de lectura sin fabricar indicadores en cero', () async {
    final repo = _Repo([]);
    await expectLater(
      cargarMarcacionesDashboard(repo, ahora),
      throwsStateError,
    );
  });
}

class _Cursor extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class _Repo extends Fake implements RepositorioAsistenciasImpl {
  _Repo(this.paginas);
  final List<PaginaAsistencias> paginas;
  final consultas =
      <
        ({
          DateTime? desde,
          DateTime? hasta,
          QueryDocumentSnapshot<Map<String, dynamic>>? cursor,
        })
      >[];
  @override
  Future<PaginaAsistencias> obtenerPaginaAsistencias({
    int limite = 50,
    DateTime? desde,
    DateTime? hastaExclusiva,
    QueryDocumentSnapshot<Map<String, dynamic>>? despuesDe,
  }) async {
    expect(limite, 4);
    consultas.add((desde: desde, hasta: hastaExclusiva, cursor: despuesDe));
    if (paginas.isEmpty) throw StateError('Consulta no disponible');
    return paginas.removeAt(0);
  }

  @override
  Future<List<Asistencia>> obtenerAsistencias() =>
      throw StateError('No descargar todo el historial');
}
