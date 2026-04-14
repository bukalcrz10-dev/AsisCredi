import 'package:flutter/material.dart';

// Tema visual compartido por toda la aplicacion.
// Vive en app/ porque define la base grafica comun para todos los modulos.
ThemeData temaAplicacion() {
  // La app adopta la identidad visual del login de UNACHU:
  // rojo institucional dominante y verde como acento secundario.
  const rojoInstitucional = Color(0xFFBC2027);
  const rojoOscuro = Color(0xFF8E131A);
  const verdeInstitucional = Color(0xFF184E2F);
  const fondoClaro = Color(0xFFF6F4F2);

  final baseScheme = ColorScheme.fromSeed(
    seedColor: rojoInstitucional,
    brightness: Brightness.light,
    primary: rojoInstitucional,
    secondary: verdeInstitucional,
    surface: Colors.white,
  );
  final colorScheme = baseScheme.copyWith(
    primary: rojoInstitucional,
    onPrimary: Colors.white,
    secondary: verdeInstitucional,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF6ECE9),
    onSecondaryContainer: rojoOscuro,
    tertiary: const Color(0xFF4EB267),
    surfaceContainerHighest: const Color(0xFFF4EEEB),
    outlineVariant: const Color(0xFFE0D5D1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: fondoClaro,
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineMedium: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: Color(0xFF221C1A),
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: Color(0xFF2B2321),
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF332B28),
          ),
          bodyLarge: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF4B423F),
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: const Color(0xFF6A605C),
          ),
          labelLarge: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6A605C),
          ),
        ),
    // El AppBar queda configurado aqui para que las pantallas nuevas
    // no repitan estilo una por una.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2B2321),
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.06),
      titleTextStyle: const TextStyle(
        color: Color(0xFF2B2321),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF5D4B47),
      ),
    ),
    // Las tarjetas se usaran bastante en resumenes, estados y reportes,
    // por eso se deja una base visual consistente desde el arranque.
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE8DEDA)),
      ),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: rojoInstitucional,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: rojoOscuro,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: rojoOscuro,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Color(0xFFD9C6C3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFDFCFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8CCC8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8CCC8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: rojoInstitucional, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9A8E89),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFDFCFB),
      selectedColor: rojoInstitucional.withOpacity(0.1),
      side: const BorderSide(color: Color(0xFFD8CCC8)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelStyle: TextStyle(
        color: const Color(0xFF4B423F),
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerColor: const Color(0xFFE0D5D1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: rojoInstitucional.withOpacity(0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? rojoInstitucional : const Color(0xFF6A605C),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? rojoInstitucional : const Color(0xFF7F6D69),
        );
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: rojoInstitucional,
      linearTrackColor: Color(0xFFE8DEDA),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE3D6D2)),
      ),
      backgroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF6A605C),
    ),
  );
}
