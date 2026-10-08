import 'package:flutter/material.dart';
import 'diseno_sistema.dart';

// Tema visual compartido por toda la aplicacion.
// Vive en app/ porque define la base grafica comun para todos los modulos.
ThemeData temaAplicacion() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: ColoresSistema.rojoInstitucional,
    brightness: Brightness.light,
    primary: ColoresSistema.rojoInstitucional,
    secondary: ColoresSistema.verdeInstitucional,
    surface: Colors.white,
  );
  final colorScheme = baseScheme.copyWith(
    primary: ColoresSistema.rojoInstitucional,
    onPrimary: Colors.white,
    secondary: ColoresSistema.verdeInstitucional,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE3F2F3),
    onSecondaryContainer: ColoresSistema.rojoInstitucionalOscuro,
    tertiary: ColoresSistema.verdeExito,
    surfaceContainerHighest: ColoresSistema.fondoSuaveAlt,
    outlineVariant: ColoresSistema.divisor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ColoresSistema.fondoApp,
    textTheme: ThemeData.light().textTheme.copyWith(
          headlineMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            color: ColoresSistema.textoTitulo,
          ),
          titleLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: ColoresSistema.textoFuerte,
          ),
          titleMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29424B),
          ),
          bodyLarge: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: ColoresSistema.textoBase,
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: ColoresSistema.textoSecundario,
          ),
          labelLarge: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ColoresSistema.textoSecundario,
          ),
        ),
    // El AppBar queda configurado aqui para que las pantallas nuevas
    // no repitan estilo una por una.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ColoresSistema.textoFuerte,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      titleTextStyle: const TextStyle(
        color: ColoresSistema.textoFuerte,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(
        color: ColoresSistema.iconoSuave,
      ),
    ),
    // Las tarjetas se usaran bastante en resumenes, estados y reportes,
    // por eso se deja una base visual consistente desde el arranque.
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
        side: const BorderSide(color: ColoresSistema.bordeSuave),
      ),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresSistema.rojoInstitucional,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
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
        foregroundColor: ColoresSistema.rojoInstitucionalOscuro,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColoresSistema.rojoInstitucionalOscuro,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: ColoresSistema.bordeChip),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColoresSistema.fondoSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        borderSide: const BorderSide(color: ColoresSistema.bordeCampo),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        borderSide: const BorderSide(color: ColoresSistema.bordeCampo),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        borderSide: const BorderSide(
          color: ColoresSistema.rojoInstitucional,
          width: 1.5,
        ),
      ),
      hintStyle: const TextStyle(
        color: ColoresSistema.textoSuave,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ColoresSistema.fondoSuave,
      selectedColor: ColoresSistema.rojoInstitucional.withValues(alpha: 0.1),
      side: const BorderSide(color: ColoresSistema.bordeCampo),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
      ),
      labelStyle: TextStyle(
        color: ColoresSistema.textoBase,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    dividerColor: ColoresSistema.divisor,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: ColoresSistema.rojoInstitucional.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected
              ? ColoresSistema.rojoInstitucional
              : ColoresSistema.textoSecundario,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? ColoresSistema.rojoInstitucional
              : const Color(0xFF647E86),
        );
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ColoresSistema.rojoInstitucional,
      linearTrackColor: ColoresSistema.bordeSuave,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        side: const BorderSide(color: ColoresSistema.bordeIntermedio),
      ),
      backgroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(
      color: ColoresSistema.iconoBase,
    ),
  );
}
