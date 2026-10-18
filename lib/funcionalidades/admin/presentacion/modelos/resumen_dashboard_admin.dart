import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import '../../../sedes/dominio/entidades/sede.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import 'evaluacion_asistencia_admin.dart';
import 'jornada_admin.dart';

/// Una lectura del panel. Los totales diarios nunca incluyen el historial
/// adicional que se consulta únicamente para mostrar las últimas jornadas.
class ResumenDashboardAdmin {
  ResumenDashboardAdmin({
    required this.actualizadoEn,
    required List<Usuario> usuarios,
    required List<Sede> sedes,
    required List<Asistencia> marcaciones,
  }) {
    final hoy = DateTime(
      actualizadoEn.year,
      actualizadoEn.month,
      actualizadoEn.day,
    );
    final usuariosPorId = {for (final u in usuarios) u.id: u};
    final sedesPorId = {for (final s in sedes) s.id: s};
    activos = usuarios
        .where((u) => u.activo && u.rol == RolUsuario.trabajador)
        .toList();
    enLabores = activos.where((u) {
      final inicio = u.fechaInicioLabores;
      return inicio == null ||
          !DateTime(inicio.year, inicio.month, inicio.day).isAfter(hoy);
    }).toList();
    final grupos = <String, List<Asistencia>>{};
    for (final m in marcaciones) {
      final fecha = DateTime(
        m.fechaHora.year,
        m.fechaHora.month,
        m.fechaHora.day,
      );
      if (fecha.isAfter(hoy)) continue;
      grupos.putIfAbsent(claveJornadaAdmin(m), () => []).add(m);
    }
    jornadas = grupos.values.map((marcas) {
      marcas.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      final ultima = marcas.last;
      final usuario = usuariosPorId[ultima.usuarioId];
      final nombresSedes =
          marcas
              .map((m) => sedesPorId[m.sedeId]?.nombre ?? 'Sede no disponible')
              .toSet()
              .toList()
            ..sort();
      return JornadaDashboardAdmin(
        usuarioId: ultima.usuarioId,
        nombre: usuario?.nombreCompleto ?? ultima.nombreUsuario,
        sede: nombresSedes.join(' / '),
        ultimaMarca: ultima.fechaHora,
        evaluacion: EvaluacionAsistenciaAdmin(marcas, ultima.fechaHora),
        usuarioDisponible: usuario != null,
      );
    }).toList()..sort((a, b) => b.ultimaMarca.compareTo(a.ultimaMarca));
    jornadasHoy = jornadas
        .where((j) => mismaFechaDashboard(j.ultimaMarca, hoy))
        .toList();
    final conMarcas = jornadasHoy.map((j) => j.usuarioId).toSet();
    conMarcaciones = enLabores.where((u) => conMarcas.contains(u.id)).length;
    sinMarcaciones = esDomingo
        ? []
        : enLabores.where((u) => !conMarcas.contains(u.id)).toList();
    sinMarcaciones.sort(
      (a, b) => a.nombreCompleto.toLowerCase().compareTo(
        b.nombreCompleto.toLowerCase(),
      ),
    );
    configuracion = [
      for (final u in activos)
        if (horarioDesdeCargo(u.cargo) == null ||
            sedesPorId[u.sedeAsignadaId]?.activa != true)
          ConfiguracionDashboardAdmin(
            usuario: u,
            motivo: [
              if (horarioDesdeCargo(u.cargo) == null)
                'Cargo sin horario compatible',
              if (!sedesPorId.containsKey(u.sedeAsignadaId))
                'Sin sede registrada'
              else if (!sedesPorId[u.sedeAsignadaId]!.activa)
                'Sede inactiva',
            ].join(' · '),
          ),
    ];
    configuracion.sort(
      (a, b) => a.usuario.nombreCompleto.compareTo(b.usuario.nombreCompleto),
    );
    coberturaSedes = [
      for (final sede in sedes)
        CoberturaSedeDashboard(
          nombre: sede.nombre,
          activa: sede.activa,
          asignados: enLabores.where((u) => u.sedeAsignadaId == sede.id).length,
          conMarcaciones: enLabores
              .where(
                (u) => u.sedeAsignadaId == sede.id && conMarcas.contains(u.id),
              )
              .length,
        ),
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));
    sedesActivas = sedes.where((s) => s.activa).length;
  }

  final DateTime actualizadoEn;
  bool get esDomingo => actualizadoEn.weekday == DateTime.sunday;
  late final List<Usuario> activos;
  late final List<Usuario> enLabores;
  late final int conMarcaciones;
  late final List<Usuario> sinMarcaciones;
  late final List<JornadaDashboardAdmin> jornadas;
  late final List<JornadaDashboardAdmin> jornadasHoy;
  late final List<ConfiguracionDashboardAdmin> configuracion;
  late final List<CoberturaSedeDashboard> coberturaSedes;
  late final int sedesActivas;
  List<JornadaDashboardAdmin> get incompletas =>
      jornadasHoy.where((j) => j.estado == 'Pendiente').toList();
  List<JornadaDashboardAdmin> get observadas =>
      jornadasHoy.where((j) => j.estado == 'Observada').toList();
  int get correctas => jornadasHoy.where((j) => j.estado == 'Correcta').length;
}

class JornadaDashboardAdmin {
  const JornadaDashboardAdmin({
    required this.usuarioId,
    required this.nombre,
    required this.sede,
    required this.ultimaMarca,
    required this.evaluacion,
    required this.usuarioDisponible,
  });
  final String usuarioId;
  final String nombre;
  final String sede;
  final DateTime ultimaMarca;
  final EvaluacionAsistenciaAdmin evaluacion;
  final bool usuarioDisponible;
  String get estado => evaluacion.estado;
}

class ConfiguracionDashboardAdmin {
  const ConfiguracionDashboardAdmin({
    required this.usuario,
    required this.motivo,
  });
  final Usuario usuario;
  final String motivo;
}

class CoberturaSedeDashboard {
  const CoberturaSedeDashboard({
    required this.nombre,
    required this.activa,
    required this.asignados,
    required this.conMarcaciones,
  });
  final String nombre;
  final bool activa;
  final int asignados;
  final int conMarcaciones;
}

bool mismaFechaDashboard(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
