import 'package:flutter/material.dart';

// Tema visual compartido por toda la aplicacion.
// Vive en app/ porque define la base grafica comun para todos los modulos.
ThemeData temaAplicacion() {
  // Se usa un color semilla para mantener coherencia visual
  // y facilitar ajustes futuros sin reconfigurar cada widget.
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0A6EBD),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    // El AppBar queda configurado aqui para que las pantallas nuevas
    // no repitan estilo una por una.
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      elevation: 0,
    ),
    // Las tarjetas se usaran bastante en resumenes, estados y reportes,
    // por eso se deja una base visual consistente desde el arranque.
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
  );
}
