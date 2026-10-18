import 'package:flutter_test/flutter_test.dart';
import 'package:prueba_facial_local/comparacion.dart';
import 'package:prueba_facial_local/main.dart';
import 'package:flutter/material.dart';

void main() {
  List<double> eje(int posicion, [double escala = 1]) =>
      List.generate(128, (i) => i == posicion ? escala : 0);
  test('comparación normalizada: mismo vector y distinta magnitud', () {
    expect(comparar(eje(0), eje(0, 3)).similitud, closeTo(1, 1e-12));
    expect(comparar(eje(0), eje(0, 3)).coincide, isTrue);
  });
  test('vectores ortogonales u opuestos no coinciden', () {
    expect(comparar(eje(0), eje(1)).coincide, isFalse);
    expect(comparar(eje(0), eje(0, -1)).similitud, closeTo(-1, 1e-12));
  });
  test('datos incompletos o no finitos no producen coincidencia', () {
    for (final invalido in [
      <double>[],
      List.filled(128, 0.0),
      List.filled(128, double.nan),
      List.filled(128, double.infinity),
      [1.0],
    ]) {
      expect(() => comparar(eje(0), invalido), throwsFormatException);
    }
  });
  testWidgets('consentimiento y referencia obligatorios antes de comparar', (
    tester,
  ) async {
    await tester.pumpWidget(const PruebaFacialApp());
    FilledButton boton(String texto) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, texto));
    expect(boton('1. Tomar referencia').onPressed, isNull);
    expect(boton('2. Tomar foto y comparar').onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(boton('1. Tomar referencia').onPressed, isNotNull);
    expect(boton('2. Tomar foto y comparar').onPressed, isNull);
    expect(
      find.textContaining('Pide dos parpadeos antes de comparar'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
