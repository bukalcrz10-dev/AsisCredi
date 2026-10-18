import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:asistencia_app/funcionalidades/asistencias/datos/modelos/modelo_asistencia.dart';
import 'package:asistencia_app/funcionalidades/asistencias/dominio/entidades/fecha_asistencia_invalida.dart';

void main() {
  for (final valor in [null, '2026-10-11', 123, DateTime(2026, 10, 11), {}]) {
    test('rechaza fecha no Timestamp: $valor sin inventar fecha', () {
      final datos = <String, dynamic>{'fechaHora': valor};
      expect(
        () => ModeloAsistencia.desdeMapa(datos, 'documento-original'),
        throwsA(
          isA<FechaAsistenciaInvalida>().having(
            (error) => error.documentoId,
            'documentoId',
            'documento-original',
          ),
        ),
      );
      expect(datos['fechaHora'], valor);
    });
  }
  test('rechaza campo ausente', () {
    expect(
      () => ModeloAsistencia.desdeMapa({}, 'sin-fecha'),
      throwsA(isA<FechaAsistenciaInvalida>()),
    );
  });
  test('conserva instante válido y metadatos históricos', () {
    final fecha = DateTime.utc(2020, 3, 10, 13, 35);
    final modelo = ModeloAsistencia.desdeMapa({
      'fechaHora': Timestamp.fromDate(fecha),
      'tipoHorario': 'plataforma',
      'bloqueJornada': 'manana',
      'tipoMarcacion': 'entrada',
    }, 'original');
    expect(modelo.fechaHora.isAtSameMomentAs(fecha), isTrue);
    expect(modelo.aEntidad().tipoHorario, 'plataforma');
    expect(modelo.aEntidad().bloqueJornada, 'manana');
    expect(
      (modelo.aMapa()['fechaHora'] as Timestamp).toDate().isAtSameMomentAs(
        fecha,
      ),
      isTrue,
    );
  });
}
