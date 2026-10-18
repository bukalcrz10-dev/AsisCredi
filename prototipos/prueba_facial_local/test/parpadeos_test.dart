import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_facial_local/parpadeos.dart';

void main() {
  Map<String, dynamic> cara(double? ojos, {int id = 1, int caras = 1}) => {
    'caras': caras,
    'id': id,
    'izquierda': ojos,
    'derecha': ojos,
    'giro': 0,
    'inclinacion': 0,
    'anchoCara': .4,
  };
  test('requiere dos ciclos completos y apertura final', () {
    final p = PruebaParpadeos();
    p.recibir(cara(.9), 0);
    p.recibir(cara(.9), 100);
    p.recibir(cara(.1), 200);
    expect(p.cantidad, 0);
    p.recibir(cara(.9), 300);
    p.recibir(cara(.9), 400);
    expect(p.cantidad, 1);
    expect(p.esperandoCaptura, false);
    p.recibir(cara(.1), 500);
    expect(p.completada, false);
    expect(p.esperandoCaptura, false);
    p.recibir(cara(.9), 600);
    expect(p.esperandoCaptura, true);
    p.recibir(cara(.9), 700);
    expect(p.completada, true);
  });
  test('foto quieta y ojos cerrados no cuentan parpadeos', () {
    for (final ojos in [.9, .1]) {
      final p = PruebaParpadeos();
      for (var ms = 0; ms < 20000; ms += 100) {
        p.recibir(cara(ojos), ms);
      }
      p.comprobarTiempo(20100);
      expect(p.cantidad, 0);
      expect(p.error, isNotNull);
    }
  });
  test('pérdida, varias caras y cambio de seguimiento invalidan', () {
    for (final dato in [
      cara(.9, caras: 0),
      cara(.9, caras: 2),
      cara(.9, id: 2),
    ]) {
      final p = PruebaParpadeos()..recibir(cara(.9), 0);
      p.recibir(dato, 100);
      expect(p.error, isNotNull);
    }
  });
  test('sin probabilidades o con un guiño no cuenta', () {
    final p = PruebaParpadeos();
    p.recibir(cara(.9), 0);
    p.recibir(cara(.9), 100);
    p.recibir({...cara(.1), 'derecha': .9}, 200);
    p.recibir(cara(null), 300);
    p.recibir(cara(.9), 400);
    p.recibir(cara(.9), 500);
    expect(p.cantidad, 0);
  });
  test('pausa prolongada o fotograma repetido invalida', () {
    for (final ms in [0, 1900]) {
      final p = PruebaParpadeos()..recibir(cara(.9), 0);
      p.recibir(cara(.9), ms);
      expect(p.error, isNotNull);
    }
  });
  test('cierre prolongado no es un parpadeo', () {
    final p = PruebaParpadeos();
    p.recibir(cara(.9), 0);
    p.recibir(cara(.9), 100);
    for (var ms = 200; ms <= 1900; ms += 100) {
      p.recibir(cara(.1), ms);
    }
    p.recibir(cara(.9), 2000);
    p.recibir(cara(.9), 2100);
    expect(p.cantidad, 0);
  });
}
