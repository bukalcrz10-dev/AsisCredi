import 'package:flutter_test/flutter_test.dart';
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
  final aperturas = [hora(8, 0), hora(12, 50), hora(14, 30), hora(18, 30)];

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

  test('Mantiene la secuencia y rechaza marcaciones adicionales', () {
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
      isNotNull,
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
}
