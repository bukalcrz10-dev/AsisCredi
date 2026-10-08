import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/widgets/resumen_historial_trabajador.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/servicios/exportador_historial.dart';

DateTime h(int hora, [int minuto = 0]) => DateTime(2026, 10, 1, hora, minuto);
Asistencia marca(
  TipoHorarioPersonal horario,
  VentanaMarcacion ventana,
  DateTime fecha,
) => Asistencia(
  id: '',
  usuarioId: 'u1',
  nombreUsuario: 'Ana',
  sedeId: 's1',
  tipoMarcacion: ventana.tipo,
  fechaHora: fecha,
  latitud: 0,
  longitud: 0,
  dentroDeZona: true,
  rostroValidado: true,
  tipoHorario: horario.name,
  bloqueJornada: ventana.bloque.name,
);

void main() {
  test('Plataforma: salida mañana visible y evaluada desde las 13:00', () {
    const horario = TipoHorarioPersonal.plataforma;
    final ventanas = ventanasPara(horario);
    final entrada = marca(horario, ventanas[0], h(8, 30));
    final resumen = construirResumenJornadaTrabajador([entrada], h(0));
    expect(resumen.manana.salidaProgramada, h(13));
    for (final instante in [
      h(12, 50),
      h(13).subtract(const Duration(seconds: 1)),
    ]) {
      expect(resumen.siguienteTipoMarcacionPara(instante), isNull);
      expect(
        resumen.rechazoMarcacionPara(TipoMarcacion.salida, instante),
        isNotNull,
      );
    }
    expect(resumen.siguienteTipoMarcacionPara(h(13)), TipoMarcacion.salida);
    expect(resumen.rechazoMarcacionPara(TipoMarcacion.salida, h(13)), isNull);
    expect(
      resumen.rechazoMarcacionPara(TipoMarcacion.salida, h(14, 59)),
      isNull,
    );
    expect(
      resumen.rechazoMarcacionPara(TipoMarcacion.salida, h(15)),
      isNotNull,
    );
    final cerrado = construirResumenJornadaTrabajador([
      entrada,
      marca(horario, ventanas[1], h(13)),
    ], h(0));
    expect(cerrado.salidaAnticipadaTotal, Duration.zero);
    expect(cerrado.tiempoLaborado, const Duration(hours: 4, minutes: 30));
  });
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    test('${horario.name}: salida final visible solo de 18:30 a 19:30', () {
      final ventanas = ventanasPara(horario);
      final entrada = ventanas[horario == TipoHorarioPersonal.asesor ? 0 : 2];
      final resumen = construirResumenJornadaTrabajador([
        marca(
          horario,
          entrada,
          horario == TipoHorarioPersonal.asesor ? h(8, 30) : h(15),
        ),
      ], h(0));
      expect(resumen.siguienteTipoMarcacionPara(h(18, 20)), isNull);
      expect(
        resumen.siguienteTipoMarcacionPara(
          h(18, 30).subtract(const Duration(seconds: 1)),
        ),
        isNull,
      );
      expect(
        resumen.siguienteTipoMarcacionPara(h(18, 30)),
        TipoMarcacion.salida,
      );
      expect(
        resumen.siguienteTipoMarcacionPara(
          h(19, 30).add(const Duration(seconds: 59)),
        ),
        TipoMarcacion.salida,
      );
      expect(resumen.siguienteTipoMarcacionPara(h(19, 31)), isNull);
      expect(
        resumen.rechazoMarcacionPara(TipoMarcacion.salida, h(18, 20)),
        isNotNull,
      );
    });
  }
  for (final horario in [
    TipoHorarioPersonal.asesor,
    TipoHorarioPersonal.plataforma,
  ]) {
    final ventanas = ventanasPara(horario);
    final horas = horario == TipoHorarioPersonal.asesor
        ? [h(8, 30), h(18, 30)]
        : [h(8, 30), h(13), h(15), h(18, 30)];
    for (var i = 0; i < ventanas.length; i++) {
      test('${horario.name} marca $i: extremos, duplicados y botón', () {
        final v = ventanas[i];
        final anteriores = [
          for (var j = 0; j < i; j++) marca(horario, ventanas[j], horas[j]),
        ];
        final resumen = construirResumenJornadaTrabajador(
          anteriores,
          h(0),
          tipoHorario: horario,
        );
        final inicio = h(v.inicioMinutos ~/ 60, v.inicioMinutos % 60);
        final fin = h(v.finMinutos ~/ 60, v.finMinutos % 60);
        expect(
          resumen.rechazoMarcacionPara(
            v.tipo,
            inicio.subtract(const Duration(microseconds: 1)),
          ),
          isNotNull,
        );
        expect(resumen.rechazoMarcacionPara(v.tipo, inicio), isNull);
        expect(resumen.siguienteEtiquetaAccionPara(inicio), v.etiqueta);
        expect(
          resumen.rechazoMarcacionPara(
            v.tipo,
            fin.subtract(const Duration(microseconds: 1)),
          ),
          isNull,
        );
        expect(resumen.rechazoMarcacionPara(v.tipo, fin), isNotNull);
        final registrado = construirResumenJornadaTrabajador(
          [...anteriores, marca(horario, v, inicio)],
          h(0),
          tipoHorario: horario,
        );
        expect(registrado.rechazoMarcacionPara(v.tipo, inicio), isNotNull);
      });
    }
  }

  test('Tardanza exacta sin tolerancia y salida anticipada', () {
    final horario = TipoHorarioPersonal.asesor;
    final v = ventanasPara(horario);
    for (final minutos in [0, 5, 40, 90]) {
      final resumen = construirResumenJornadaTrabajador([
        marca(horario, v[0], h(8, 30).add(Duration(minutes: minutos))),
        marca(horario, v[1], h(18, 20)),
      ], h(0));
      expect(resumen.tardanzaTotal, Duration(minutes: minutos));
      expect(resumen.manana.dentroDeTolerancia, minutos == 0);
      expect(resumen.salidaAnticipadaTotal, const Duration(minutes: 10));
      expect(resumen.tramos.length, 1);
    }
  });

  test(
    'Plataforma: 8 horas y dos horas de receso; excluye siempre 13 a 15',
    () {
      final horario = TipoHorarioPersonal.plataforma;
      final v = ventanasPara(horario);
      for (final tiempos in [
        [h(8, 30), h(13), h(15), h(18, 30)],
        [h(8, 30), h(14), h(14, 50), h(18, 30)],
      ]) {
        final resumen = construirResumenJornadaTrabajador([
          for (var i = 0; i < 4; i++) marca(horario, v[i], tiempos[i]),
        ], h(0));
        expect(resumen.tiempoLaborado, const Duration(hours: 8));
        expect(resumen.salidaAnticipadaTotal, Duration.zero);
      }
      for (final retraso in [0, 10, 30]) {
        final resumen = construirResumenJornadaTrabajador([
          marca(horario, v[2], h(15, retraso)),
        ], h(0));
        expect(resumen.tardanzaTotal, Duration(minutes: retraso));
      }
    },
  );

  test(
    'Cruces: salida a receso antes del regreso; sin entrada no hay salida',
    () {
      final horario = TipoHorarioPersonal.plataforma;
      final v = ventanasPara(horario);
      final manana = marca(horario, v[0], h(8, 30));
      var resumen = construirResumenJornadaTrabajador([manana], h(0));
      expect(
        resumen.siguienteEtiquetaAccionPara(h(14, 55)),
        'Registrar salida a receso',
      );
      expect(
        resumen.rechazoMarcacionPara(TipoMarcacion.entrada, h(14, 55)),
        isNotNull,
      );
      resumen = construirResumenJornadaTrabajador([
        manana,
        marca(horario, v[1], h(14, 55)),
      ], h(0));
      expect(
        resumen.siguienteEtiquetaAccionPara(h(14, 56)),
        'Registrar entrada tarde',
      );
      expect(
        resumen.rechazoMarcacionPara(TipoMarcacion.salida, h(18, 30)),
        isNotNull,
      );
      expect(
        mismoProcesoMarcacion(
          h(12, 59),
          h(14, 50),
          TipoMarcacion.entrada,
          horario,
        ),
        isFalse,
      );
      expect(
        mismoProcesoMarcacion(
          h(13, 59),
          h(14, 10),
          TipoMarcacion.salida,
          horario,
        ),
        isTrue,
      );
      expect(
        mismoProcesoMarcacion(
          h(12),
          h(16),
          TipoMarcacion.entrada,
          TipoHorarioPersonal.asesor,
        ),
        isTrue,
      );
    },
  );

  test(
    'Horario y bloque persisten; no se reclasifica receso tardío ni asesor tardío',
    () {
      for (final horario in [
        TipoHorarioPersonal.asesor,
        TipoHorarioPersonal.plataforma,
      ]) {
        final v = ventanasPara(horario);
        final original = marca(
          horario,
          v[horario == TipoHorarioPersonal.asesor ? 0 : 1],
          h(14, 30),
        );
        final modelo = ModeloAsistencia.desdeEntidad(original);
        final recuperada = ModeloAsistencia.desdeMapa(
          modelo.aMapa(),
          'id',
        ).aEntidad();
        expect(recuperada.bloqueJornada, 'manana');
        expect(recuperada.tipoHorario, horario.name);
        expect(
          idMarcacionPorBloque(recuperada),
          idMarcacionPorBloque(original),
        );
        final resumen = construirResumenJornadaTrabajador(
          [recuperada],
          h(0),
          tipoHorario: TipoHorarioPersonal.historico,
        );
        expect(resumen.tipoHorario, horario);
        expect(resumen.manana.tieneAlgo, isTrue);
        expect(resumen.tarde.tieneAlgo, isFalse);
      }
    },
  );

  test(
    'Asesor en historial e informe no tiene receso ni un segundo bloque',
    () {
      final horario = TipoHorarioPersonal.asesor;
      final v = ventanasPara(horario);
      final dias = agruparHistorialPorDia([
        marca(horario, v[0], h(8, 30)),
        marca(horario, v[1], h(18, 30)),
      ]);
      expect(dias.single.completo, isTrue);
      expect(dias.single.tiempoLaborado, const Duration(hours: 10));
      expect(dias.single.salidaReceso, isNull);
      expect(dias.single.salidaFinal?.fechaHora, h(18, 30));
      final fila = InformeHistorial(trabajador: 'Ana', dias: dias).filas.single;
      expect(fila[2], '06:30 PM');
      expect(fila[4], '10:00');
      expect(fila.length, 7);
      expect(fila.last, 'Asesor');
    },
  );

  test('Cargo desconocido no se convierte a un horario arbitrario', () {
    expect(horarioDesdeCargo(' Asesor '), TipoHorarioPersonal.asesor);
    expect(horarioDesdeCargo('PLATAFORMA'), TipoHorarioPersonal.plataforma);
    expect(horarioDesdeCargo('Trabajador'), isNull);
  });
}
