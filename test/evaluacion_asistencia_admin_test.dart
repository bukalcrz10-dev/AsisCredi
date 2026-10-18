import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/evaluacion_asistencia_admin.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';

List<Asistencia> jornada(
  TipoHorarioPersonal horario, {
  int dia = 9,
  int retraso = 0,
  int adelanto = 0,
  bool gps = true,
  bool rostro = true,
  String nota = 'Marcacion generada desde la pantalla del trabajador.',
}) {
  final fecha = DateTime(2026, 10, dia);
  final ventanas = ventanasPara(horario, fecha: fecha);
  final horas = dia == 10
      ? [510, 900]
      : horario == TipoHorarioPersonal.asesor
      ? [510, 1110]
      : [510, 780, 900, 1110];
  return [
    for (var i = 0; i < ventanas.length; i++)
      Asistencia(
        id: '$i',
        usuarioId: 'u',
        nombreUsuario: 'Ana',
        sedeId: 's',
        tipoMarcacion: ventanas[i].tipo,
        tipoHorario: horario.name,
        bloqueJornada: ventanas[i].bloque.name,
        fechaHora: fecha.add(
          Duration(
            minutes:
                horas[i] +
                (i == 0 ? retraso : 0) -
                (i == ventanas.length - 1 ? adelanto : 0),
          ),
        ),
        latitud: 0,
        longitud: 0,
        dentroDeZona: gps,
        rostroValidado: rostro,
        observacion: nota,
      ),
  ];
}

void main() {
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    test(
      '${horario.name}: nota automática conservada sin falsa observación',
      () {
        final marcas = jornada(horario);
        final evaluacion = EvaluacionAsistenciaAdmin(
          marcas,
          marcas.first.fechaHora,
        );
        expect(evaluacion.estado, 'Correcta');
        expect(evaluacion.incidencias, isEmpty);
        expect(evaluacion.detalle, contains(marcas.first.observacion!));
        expect(
          marcas.first.observacion,
          'Marcacion generada desde la pantalla del trabajador.',
        );
      },
    );
    test(
      '${horario.name}: tardanza, salida anticipada, GPS o rostro generan revisión',
      () {
        for (final marcas in [
          jornada(horario, retraso: 5),
          jornada(horario, adelanto: 5),
          jornada(horario, gps: false),
          jornada(horario, rostro: false),
        ]) {
          final evaluacion = EvaluacionAsistenciaAdmin(
            marcas,
            marcas.first.fechaHora,
          );
          expect(evaluacion.estado, 'Observada');
          expect(evaluacion.incidencias, isNotEmpty);
        }
      },
    );
    test(
      '${horario.name}: incompleta sigue pendiente aunque tenga tardanza',
      () {
        final marcas = jornada(horario, retraso: 5).take(1).toList();
        final evaluacion = EvaluacionAsistenciaAdmin(
          marcas,
          marcas.first.fechaHora,
        );
        expect(evaluacion.estado, 'Pendiente');
        expect(evaluacion.detalle, contains('tardanza'));
      },
    );
    test('${horario.name}: sábado requiere únicamente dos marcas', () {
      final marcas = jornada(horario, dia: 10);
      expect(
        EvaluacionAsistenciaAdmin(marcas, marcas.first.fechaHora).estado,
        'Correcta',
      );
    });
  }
  test('Plataforma con solo la mañana no está completa', () {
    final marcas = jornada(TipoHorarioPersonal.plataforma).take(2).toList();
    expect(
      EvaluacionAsistenciaAdmin(marcas, marcas.first.fechaHora).estado,
      'Pendiente',
    );
  });
  test('Notas manuales no son incidencias por sí solas, pero se conservan', () {
    final marcas = jornada(
      TipoHorarioPersonal.asesor,
      nota: 'Regularizado manualmente desde el panel administrativo.',
    );
    final evaluacion = EvaluacionAsistenciaAdmin(
      marcas,
      marcas.first.fechaHora,
    );
    expect(evaluacion.estado, 'Correcta');
    expect(evaluacion.detalle, contains('Regularizado manualmente'));
  });
  test('Domingo conserva estado no laborable', () {
    expect(
      EvaluacionAsistenciaAdmin([], DateTime(2026, 10, 11)).estado,
      'Pendiente',
    );
    final marcas = jornada(TipoHorarioPersonal.asesor)
        .map(
          (m) => Asistencia(
            id: m.id,
            usuarioId: m.usuarioId,
            nombreUsuario: m.nombreUsuario,
            sedeId: m.sedeId,
            tipoMarcacion: m.tipoMarcacion,
            fechaHora: m.fechaHora.add(const Duration(days: 2)),
            latitud: 0,
            longitud: 0,
            dentroDeZona: true,
            rostroValidado: true,
            tipoHorario: m.tipoHorario,
            bloqueJornada: m.bloqueJornada,
          ),
        )
        .toList();
    expect(
      EvaluacionAsistenciaAdmin(marcas, marcas.first.fechaHora).estado,
      'No laborable',
    );
  });
}
