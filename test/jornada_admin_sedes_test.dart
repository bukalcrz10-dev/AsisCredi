import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/jornada_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/evaluacion_asistencia_admin.dart';
import 'package:asistencia_app/funcionalidades/admin/presentacion/modelos/regularizacion_jornada.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'evaluacion_asistencia_admin_test.dart' as fixtures;

List<Asistencia> variasSedes(TipoHorarioPersonal horario, {int dia = 9}) {
  final marcas = fixtures.jornada(horario, dia: dia);
  return [
    for (var i = 0; i < marcas.length; i++)
      ModeloAsistencia.desdeMapa(
        ModeloAsistencia.desdeEntidad(marcas[i]).aMapa()
          ..['sedeId'] = i < marcas.length ~/ 2 ? 'huancayo' : 'satipo',
        marcas[i].id,
      ).aEntidad(),
  ];
}

void main() {
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    for (final dia in [9, 10]) {
      test(
        '$horario día $dia: cambio de sede conserva una jornada completa',
        () {
          final marcas = variasSedes(horario, dia: dia);
          expect(marcas.map(claveJornadaAdmin).toSet(), hasLength(1));
          final evaluacion = EvaluacionAsistenciaAdmin(
            marcas,
            marcas.first.fechaHora,
          );
          expect(evaluacion.estado, 'Correcta');
          expect(
            evaluacion.resumen.tiempoLaborado,
            dia == 10
                ? const Duration(hours: 6, minutes: 30)
                : horario == TipoHorarioPersonal.asesor
                ? const Duration(hours: 10)
                : const Duration(hours: 8),
          );
          expect(marcas.first.sedeId, 'huancayo');
          expect(marcas.last.sedeId, 'satipo');
        },
      );
    }
  }

  test('no agrupa fechas ni trabajadores distintos', () {
    final marca = variasSedes(TipoHorarioPersonal.asesor).first;
    final otro = ModeloAsistencia.desdeMapa(
      ModeloAsistencia.desdeEntidad(marca).aMapa()..['usuarioId'] = 'otro',
      'otro',
    ).aEntidad();
    final otroDia = variasSedes(TipoHorarioPersonal.asesor, dia: 10).first;
    expect([marca, otro, otroDia].map(claveJornadaAdmin).toSet(), hasLength(3));
  });

  test('corregir horas conserva la sede original de cada marca', () {
    final marcas = variasSedes(TipoHorarioPersonal.asesor);
    final jornada = RegularizacionJornada(marcas);
    final horas = {
      for (final c in jornada.campos) jornada.clave(c): jornada.texto(c),
    };
    horas[jornada.clave(jornada.campos.first)] = '08:31';
    horas[jornada.clave(jornada.campos.last)] = '18:31';
    final cambios = jornada.preparar(horas);
    for (final cambio in cambios) {
      expect(cambio.sedeId, marcas.firstWhere((m) => m.id == cambio.id).sedeId);
    }
  });

  test('completar marca entre varias sedes exige elección explícita', () {
    final marcas = variasSedes(TipoHorarioPersonal.plataforma)..removeAt(1);
    final jornada = RegularizacionJornada(marcas);
    final campo = jornada.campos.firstWhere(
      (c) => jornada.existente(c) == null,
    );
    final horas = {
      for (final c in jornada.campos) jornada.clave(c): jornada.texto(c),
    };
    horas[jornada.clave(campo)] = '13:00';
    expect(() => jornada.preparar(horas), throwsFormatException);
    expect(
      () =>
          jornada.preparar(horas, sedesNuevas: {jornada.clave(campo): 'otra'}),
      throwsFormatException,
    );
    final cambios = jornada.preparar(
      horas,
      sedesNuevas: {jornada.clave(campo): 'huancayo'},
    );
    expect(cambios, hasLength(1));
    expect(cambios.single.sedeId, 'huancayo');
    expect(cambios.single.dentroDeZona, isFalse);
    expect(cambios.single.rostroValidado, isFalse);
  });
}
