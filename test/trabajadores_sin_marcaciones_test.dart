import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/trabajadores_sin_marcaciones.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/usuario.dart';
import 'package:asistencia_app/funcionalidades/usuarios/dominio/entidades/rol_usuario.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;

Usuario usuario(
  String id, {
  bool activo = true,
  RolUsuario rol = RolUsuario.trabajador,
  String cargo = 'asesor',
}) => Usuario(
  id: id,
  nombreCompleto: id,
  correo: '$id@example.com',
  cargo: cargo,
  rol: rol,
  sedeAsignadaId: 'sede',
  activo: activo,
);

void main() {
  final viernes = DateTime(2026, 10, 9);
  test('incluye solo trabajadores activos sin ninguna marcación de hoy', () {
    final resultado = trabajadoresSinMarcaciones(
      usuarios: [
        usuario('u'),
        usuario('z'),
        usuario('a', cargo: 'plataforma'),
        usuario('inactivo', activo: false),
        usuario('admin', rol: RolUsuario.administrador),
      ],
      marcaciones: [fixtures.jornada(TipoHorarioPersonal.asesor).first],
      fecha: viernes,
    );
    expect(resultado.map((u) => u.id), ['a', 'z']);
  });
  test('las marcas de ayer y mañana no ocultan a quien no marcó hoy', () {
    expect(
      trabajadoresSinMarcaciones(
        usuarios: [usuario('u')],
        fecha: viernes,
        marcaciones: [
          ...fixtures.jornada(TipoHorarioPersonal.asesor, dia: 8),
          ...fixtures.jornada(TipoHorarioPersonal.asesor, dia: 10),
        ],
      ),
      hasLength(1),
    );
  });
  test('domingo no cuenta trabajadores sin marcas', () {
    expect(
      trabajadoresSinMarcaciones(
        usuarios: [usuario('u')],
        marcaciones: [],
        fecha: DateTime(2026, 10, 11),
      ),
      isEmpty,
    );
  });
  test('sábado sí cuenta y una marca basta para salir de sin marcaciones', () {
    final usuarios = [usuario('u'), usuario('otro', cargo: 'plataforma')];
    expect(
      trabajadoresSinMarcaciones(
        usuarios: usuarios,
        marcaciones: [
          fixtures.jornada(TipoHorarioPersonal.asesor, dia: 10).first,
        ],
        fecha: DateTime(2026, 10, 10),
      ).map((u) => u.id),
      ['otro'],
    );
  });
  test('el cambio de sede y marcas repetidas no alteran la identificación', () {
    final marca = fixtures.jornada(TipoHorarioPersonal.asesor).first;
    final otraSede = ModeloAsistencia.desdeMapa(
      ModeloAsistencia.desdeEntidad(marca).aMapa()..['sedeId'] = 'otra',
      'otra',
    ).aEntidad();
    expect(
      trabajadoresSinMarcaciones(
        usuarios: [usuario('u')],
        marcaciones: [marca, otraSede],
        fecha: viernes,
      ),
      isEmpty,
    );
  });
  test(
    'sin cargo o antes de iniciar la jornada sigue siendo solo sin marcaciones',
    () {
      expect(
        trabajadoresSinMarcaciones(
          usuarios: [usuario('u', cargo: '')],
          marcaciones: [],
          fecha: viernes,
        ).map((u) => u.id),
        ['u'],
      );
    },
  );
}
