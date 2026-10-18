import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../presentacion/modelos/jornada_admin.dart';

/// Obtiene el día actual completo y solo retrocede hasta reunir la actividad
/// mostrada. Las páginas del repositorio siempre terminan con días completos.
Future<List<Asistencia>> cargarMarcacionesDashboard(
  RepositorioAsistenciasImpl repositorio,
  DateTime ahora,
) async {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final manana = DateTime(ahora.year, ahora.month, ahora.day + 1);
  final paginaHoy = await repositorio.obtenerPaginaAsistencias(
    limite: 4,
    desde: hoy,
    hastaExclusiva: manana,
  );
  final marcas = [...paginaHoy.asistencias];
  final jornadas = marcas.map(claveJornadaAdmin).toSet();
  QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
  while (jornadas.length < 4) {
    final pagina = await repositorio.obtenerPaginaAsistencias(
      limite: 4,
      hastaExclusiva: hoy,
      despuesDe: cursor,
    );
    marcas.addAll(pagina.asistencias);
    jornadas.addAll(pagina.asistencias.map(claveJornadaAdmin));
    if (!pagina.hayMas) break;
    cursor = pagina.ultimoDocumento;
  }
  return marcas;
}
