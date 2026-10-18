import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/resumen_dashboard_admin.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/sedes/dominio/entidades/sede.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixture;

Usuario persona(
  String id, {
  String cargo = 'Auxiliar de operaciones',
  String sede = 's',
  bool activo = true,
  RolUsuario rol = RolUsuario.trabajador,
  DateTime? inicio,
}) => Usuario(
  id: id,
  nombreCompleto: 'Persona $id',
  correo: '$id@example.com',
  cargo: cargo,
  sedeAsignadaId: sede,
  activo: activo,
  rol: rol,
  fechaInicioLabores: inicio,
);
const sede = Sede(
  id: 's',
  nombre: 'Principal',
  latitud: -12,
  longitud: -75,
  radioPermitidoMetros: 100,
);
List<Asistencia> marcas(
  String uid, {
  int dia = 9,
  bool gps = true,
  TipoHorarioPersonal horario = TipoHorarioPersonal.plataforma,
}) => fixture
    .jornada(horario, dia: dia, gps: gps)
    .map(
      (m) => ModeloAsistencia.desdeMapa(
        ModeloAsistencia.desdeEntidad(m).aMapa()..['usuarioId'] = uid,
        '$uid-$dia-${m.id}',
      ).aEntidad(),
    )
    .toList();
ResumenDashboardAdmin resumen({
  List<Usuario>? usuarios,
  List<Asistencia> registros = const [],
  DateTime? fecha,
  List<Sede> sedes = const [sede],
}) => ResumenDashboardAdmin(
  actualizadoEn: fecha ?? DateTime(2026, 10, 9, 20),
  usuarios: usuarios ?? [persona('u')],
  sedes: sedes,
  marcaciones: registros,
);

void main() {
  test('conserva las marcas guardadas de hoy y excluye fechas futuras', () {
    final r = resumen(
      fecha: DateTime(2026, 10, 9, 9),
      registros: [...marcas('u'), ...marcas('u', dia: 10)],
    );
    expect(r.jornadas, hasLength(1));
    expect(r.correctas, 1);
  });
  test(
    'cuatro marcas son una persona y una jornada; conserva estados reales',
    () {
      final r = resumen(
        usuarios: [persona('u'), persona('v'), persona('w')],
        registros: [
          ...marcas('u'),
          ...marcas('v', gps: false),
          marcas('w').first,
        ],
      );
      expect(r.conMarcaciones, 3);
      expect(r.jornadasHoy, hasLength(3));
      expect(r.correctas, 1);
      expect(r.observadas.single.usuarioId, 'v');
      expect(r.incompletas.single.usuarioId, 'w');
    },
  );
  test('historial no incrementa totales ni encubre a quien no marcó hoy', () {
    final r = resumen(registros: marcas('u', dia: 8));
    expect(r.jornadas, hasLength(1));
    expect(r.jornadasHoy, isEmpty);
    expect(r.conMarcaciones, 0);
    expect(r.sinMarcaciones.single.id, 'u');
  });
  test(
    'excluye administradores, inactivos e inicio futuro de la cobertura diaria',
    () {
      final r = resumen(
        usuarios: [
          persona('hoy', inicio: DateTime(2026, 10, 9)),
          persona('futuro', inicio: DateTime(2026, 10, 10)),
          persona('baja', activo: false),
          persona('admin', rol: RolUsuario.administrador),
        ],
      );
      expect(r.activos, hasLength(2));
      expect(r.enLabores.single.id, 'hoy');
      expect(r.sinMarcaciones.single.id, 'hoy');
    },
  );
  test('domingo sin marcaciones no se convierte en falta', () {
    final r = resumen(fecha: DateTime(2026, 10, 11, 20));
    expect(r.esDomingo, isTrue);
    expect(r.sinMarcaciones, isEmpty);
    expect(r.enLabores, hasLength(1));
  });
  test(
    'sábado usa dos marcas sin reinterpretar la jornada partida del viernes',
    () {
      final r = resumen(
        fecha: DateTime(2026, 10, 10, 20),
        registros: [...marcas('u', dia: 10), ...marcas('u', dia: 9)],
      );
      expect(r.correctas, 1);
      expect(r.jornadas, hasLength(2));
      expect(r.jornadas.every((j) => j.estado == 'Correcta'), isTrue);
    },
  );
  test('la entrada de tarde es más reciente que la salida de mañana', () {
    final r = resumen(registros: marcas('u').take(3).toList());
    expect(r.jornadas.single.ultimaMarca.hour, 15);
    expect(r.incompletas, hasLength(1));
  });
  test(
    'cuenta cobertura por sede asignada aunque la marca provenga de otra sede',
    () {
      final r = resumen(
        usuarios: [persona('u', sede: 'otra')],
        registros: marcas('u'),
        sedes: [
          sede,
          const Sede(
            id: 'otra',
            nombre: 'Otra',
            latitud: 0,
            longitud: 0,
            radioPermitidoMetros: 100,
          ),
        ],
      );
      expect(r.coberturaSedes.first.conMarcaciones, 1);
      expect(r.coberturaSedes.last.conMarcaciones, 0);
      expect(r.jornadas.single.sede, 'Principal');
    },
  );
  test(
    'detecta cargos incompatibles y sedes ausentes o inactivas; respeta alias',
    () {
      final r = resumen(
        usuarios: [
          persona('u'),
          persona('alias', cargo: ' PLATAFORMA '),
          persona('v', cargo: 'Otro', sede: 'desconocida'),
          persona('w', sede: 'inactiva'),
        ],
        sedes: [
          sede,
          const Sede(
            id: 'inactiva',
            nombre: 'Cerrada',
            latitud: 0,
            longitud: 0,
            radioPermitidoMetros: 100,
            activa: false,
          ),
        ],
      );
      expect(r.configuracion, hasLength(2));
      expect(
        r.configuracion.first.motivo,
        'Cargo sin horario compatible · Sin sede registrada',
      );
      expect(r.configuracion.last.motivo, 'Sede inactiva');
      expect(r.sedesActivas, 1);
    },
  );
  test('sin datos no inventa sedes ni porcentajes', () {
    final r = resumen(usuarios: [], sedes: []);
    expect(r.activos, isEmpty);
    expect(r.coberturaSedes, isEmpty);
    expect(r.jornadas, isEmpty);
  });
}
