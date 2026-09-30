import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/tipo_marcacion.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_auxiliares.dart';
import 'package:asistencia_app/funcionalidades/asistencias/presentacion/controladores/controlador_asistencia_marcacion_auxiliares.dart';

DateTime hora(int h, int m) => DateTime(2026, 9, 25, h, m);

Asistencia marca(TipoMarcacion tipo, int h, int m) => Asistencia(
  id: '$h:$m',
  usuarioId: 'trabajador',
  nombreUsuario: 'Prueba',
  sedeId: 'sede_principal',
  tipoMarcacion: tipo,
  fechaHora: hora(h, m),
  latitud: 0,
  longitud: 0,
  dentroDeZona: true,
  rostroValidado: true,
);

void main() {
  final jornada = [
    marca(TipoMarcacion.entrada, 8, 30),
    marca(TipoMarcacion.salida, 13, 0),
    marca(TipoMarcacion.entrada, 15, 0),
    marca(TipoMarcacion.salida, 19, 0),
  ];
  final aperturas = [hora(8, 0), hora(13, 0), hora(14, 30), hora(18, 30)];

  for (var paso = 0; paso < jornada.length; paso++) {
    test(
      'Marcacion ${paso + 1}: bloquea antes y permite desde la apertura',
      () {
        final anteriores = jornada.take(paso).toList();
        final apertura = aperturas[paso];
        expect(
          construirResumenJornadaTrabajador(
            anteriores,
            hora(0, 0),
          ).proximaHoraHabilitada,
          apertura,
        );
        expect(
          obtenerRechazoReglaDiariaMarcacion(
            marcacionesHoy: anteriores,
            tipoMarcacion: jornada[paso].tipoMarcacion,
            ahora: apertura.subtract(const Duration(seconds: 1)),
          ),
          isNotNull,
        );
        for (final instante in [apertura, jornada[paso].fechaHora]) {
          expect(
            obtenerRechazoReglaDiariaMarcacion(
              marcacionesHoy: anteriores,
              tipoMarcacion: jornada[paso].tipoMarcacion,
              ahora: instante,
            ),
            isNull,
          );
        }
      },
    );
  }

  test('Horario y duracion de la jornada completa', () {
    final resumen = construirResumenJornadaTrabajador(jornada, hora(0, 0));
    expect(resumen.manana.entradaProgramada, hora(8, 30));
    expect(resumen.manana.salidaProgramada, hora(13, 0));
    expect(resumen.tarde.entradaProgramada, hora(15, 0));
    expect(resumen.tarde.salidaProgramada, hora(19, 0));
    expect(resumen.tiempoLaborado, const Duration(hours: 8, minutes: 30));
    expect(resumen.descanso, const Duration(hours: 2));
  });

  test('Tolerancia de diez minutos desde las nuevas entradas', () {
    final resumen = construirResumenJornadaTrabajador([
      marca(TipoMarcacion.entrada, 8, 40),
      marca(TipoMarcacion.entrada, 15, 11),
    ], hora(0, 0));
    expect(resumen.manana.dentroDeTolerancia, isTrue);
    expect(resumen.manana.tardanza, const Duration(minutes: 10));
    expect(resumen.tarde.dentroDeTolerancia, isFalse);
    expect(resumen.tarde.tardanza, const Duration(minutes: 11));
  });

  test('Cada turno requiere su entrada y rechaza marcaciones adicionales', () {
    expect(
      obtenerRechazoReglaDiariaMarcacion(
        marcacionesHoy: [],
        tipoMarcacion: TipoMarcacion.salida,
        ahora: hora(13, 0),
      ),
      isNotNull,
    );
    expect(
      obtenerRechazoReglaDiariaMarcacion(
        marcacionesHoy: [jornada.first],
        tipoMarcacion: TipoMarcacion.entrada,
        ahora: hora(15, 0),
      ),
      isNull,
    );
    for (final tipo in TipoMarcacion.values) {
      expect(
        obtenerRechazoReglaDiariaMarcacion(
          marcacionesHoy: jornada,
          tipoMarcacion: tipo,
          ahora: hora(19, 30),
        ),
        isNotNull,
      );
    }
  });
  final cierres = [hora(12, 50), hora(13, 31), hora(18, 21), hora(19, 31)];
  final etiquetas = [
    'Registrar entrada mañana',
    'Registrar salida mañana',
    'Registrar entrada tarde',
    'Registrar salida tarde',
  ];
  for (var paso = 0; paso < 4; paso++) {
    test(
      'Ventana $paso: boton y validacion coinciden en ambos extremos',
      () {
        final anteriores = jornada.take(paso).toList();
        final resumen = construirResumenJornadaTrabajador(
          anteriores,
          hora(0, 0),
        );
        for (final instante in [
          aperturas[paso],
          cierres[paso].subtract(const Duration(microseconds: 1)),
        ]) {
          expect(
            resumen.siguienteTipoMarcacionPara(instante),
            jornada[paso].tipoMarcacion,
          );
          expect(
            resumen.siguienteEtiquetaAccionPara(instante),
            etiquetas[paso],
          );
          expect(
            obtenerRechazoReglaDiariaMarcacion(
              marcacionesHoy: anteriores,
              tipoMarcacion: jornada[paso].tipoMarcacion,
              ahora: instante,
            ),
            isNull,
          );
        }
        for (final instante in [
          aperturas[paso].subtract(const Duration(microseconds: 1)),
          cierres[paso],
        ]) {
          expect(resumen.siguienteTipoMarcacionPara(instante), isNull);
          expect(resumen.siguienteEtiquetaAccionPara(instante), isNull);
          expect(
            obtenerRechazoReglaDiariaMarcacion(
              marcacionesHoy: anteriores,
              tipoMarcacion: jornada[paso].tipoMarcacion,
              ahora: instante,
            ),
            isNotNull,
          );
        }
        final registrada = [...anteriores, jornada[paso]];
        expect(
          construirResumenJornadaTrabajador(
            registrada,
            hora(0, 0),
          ).siguienteTipoMarcacionPara(jornada[paso].fechaHora),
          isNull,
        );
        expect(
          obtenerRechazoReglaDiariaMarcacion(
            marcacionesHoy: registrada,
            tipoMarcacion: jornada[paso].tipoMarcacion,
            ahora: jornada[paso].fechaHora,
          ),
          isNotNull,
        );
      },
    );
  }

  test(
    'Salida matutina espera a las 13:00 y no acepta entrada de otro bloque',
    () {
      expect(
        obtenerRechazoReglaDiariaMarcacion(
          marcacionesHoy: [jornada.first],
          tipoMarcacion: TipoMarcacion.salida,
          ahora: hora(12, 55),
        ),
        isNotNull,
      );
      expect(
        obtenerRechazoReglaDiariaMarcacion(
          marcacionesHoy: [jornada.first],
          tipoMarcacion: TipoMarcacion.salida,
          ahora: hora(19, 0),
        ),
        isNotNull,
      );
    },
  );

  test('Un turno de tarde independiente conserva pendientes de la manana', () {
    final resumen = construirResumenJornadaTrabajador([], hora(0, 0));
    expect(
      resumen.siguienteEtiquetaAccionPara(hora(14, 30)),
      'Registrar entrada tarde',
    );
    final tarde = construirResumenJornadaTrabajador([jornada[2]], hora(0, 0));
    expect(tarde.siguienteTipoMarcacionPara(hora(19, 0)), TipoMarcacion.salida);
    expect(tarde.manana.completo, false);
  });

  test('Identificador unico por trabajador, dia, bloque y tipo', () {
    final id = idMarcacionPorBloque(jornada.first);
    expect(idMarcacionPorBloque(marca(TipoMarcacion.entrada, 9, 0)), id);
    expect(jornada.map(idMarcacionPorBloque).toSet(), hasLength(4));
    final otro = Asistencia(
      id: '',
      usuarioId: 'otro',
      nombreUsuario: 'Otro',
      sedeId: 'sede',
      tipoMarcacion: TipoMarcacion.entrada,
      fechaHora: hora(8, 30),
      latitud: 0,
      longitud: 0,
      dentroDeZona: true,
      rostroValidado: true,
    );
    expect(idMarcacionPorBloque(otro), isNot(id));
  });

  test('Una hoja antigua no se reutiliza en otro turno ni otro dia', () {
    expect(mismoTurnoMarcacion(hora(8, 0), hora(12, 49)), true);
    expect(mismoTurnoMarcacion(hora(8, 0), hora(14, 30)), false);
    expect(
      mismoTurnoMarcacion(hora(8, 0), hora(8, 0).add(const Duration(days: 1))),
      false,
    );
  });
}
