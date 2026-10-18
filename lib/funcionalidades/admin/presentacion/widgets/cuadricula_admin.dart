import 'package:flutter/material.dart';

class CuadriculaAdmin extends StatelessWidget {
  const CuadriculaAdmin({
    super.key,
    required this.children,
    this.maximoColumnas = 5,
  });
  final List<Widget> children;
  final int maximoColumnas;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const espacio = 12.0;
      final escala = MediaQuery.textScalerOf(context).scale(15) / 15;
      final minimo = 180 * escala.clamp(1.0, 2.0);
      var columnas = ((constraints.maxWidth + espacio) / (minimo + espacio))
          .floor()
          .clamp(1, maximoColumnas);
      if (columnas > 2 && children.length % columnas == 1) columnas--;
      return Column(
        children: [
          for (var inicio = 0; inicio < children.length; inicio += columnas)
            Padding(
              padding: EdgeInsets.only(
                bottom: inicio + columnas < children.length ? espacio : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var columna = 0; columna < columnas; columna++) ...[
                      if (columna > 0) const SizedBox(width: espacio),
                      Expanded(
                        child: inicio + columna < children.length
                            ? children[inicio + columna]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
