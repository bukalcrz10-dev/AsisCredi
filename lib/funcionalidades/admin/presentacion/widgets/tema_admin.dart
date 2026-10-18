import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';

/// Tipografía de escritorio, aplicada únicamente dentro del panel.
ThemeData temaPanelAdmin(
  ThemeData base, {
  bool compacto = true,
}) => base.copyWith(
  visualDensity: compacto ? VisualDensity.compact : VisualDensity.standard,
  iconTheme: base.iconTheme.copyWith(size: 20),
  textTheme: base.textTheme.copyWith(
    headlineMedium: const TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: ColoresSistema.textoTitulo,
    ),
    titleLarge: const TextStyle(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: ColoresSistema.textoTitulo,
    ),
    titleMedium: const TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: ColoresSistema.textoFuerte,
    ),
    bodyLarge: const TextStyle(
      fontSize: 14,
      height: 1.35,
      color: ColoresSistema.textoFuerte,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 1.3,
      color: ColoresSistema.textoBase,
    ),
    bodySmall: const TextStyle(
      fontSize: 13,
      height: 1.3,
      color: ColoresSistema.textoBase,
    ),
    labelLarge: const TextStyle(
      fontSize: 13,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: ColoresSistema.textoFuerte,
    ),
    labelMedium: const TextStyle(
      fontSize: 13,
      height: 1.3,
      color: ColoresSistema.textoBase,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: Size(0, compacto ? 36 : 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: Size(0, compacto ? 36 : 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: Size(0, compacto ? 36 : 44),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      iconSize: 20,
      minimumSize: Size.square(compacto ? 32 : 44),
      padding: const EdgeInsets.all(6),
      visualDensity: compacto ? VisualDensity.compact : VisualDensity.standard,
      foregroundColor: ColoresPanel.azul,
    ),
  ),
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    labelStyle: const TextStyle(fontSize: 13),
    hintStyle: const TextStyle(fontSize: 14, color: ColoresSistema.textoSuave),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ColoresSistema.bordeCampo),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: ColoresPanel.turquesa, width: 1.5),
    ),
  ),
  chipTheme: base.chipTheme.copyWith(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    labelStyle: const TextStyle(fontSize: 13, color: ColoresSistema.textoBase),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  listTileTheme: base.listTileTheme.copyWith(
    dense: compacto,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
  ),
  dialogTheme: base.dialogTheme.copyWith(
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ColoresSistema.textoTitulo,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      color: ColoresSistema.textoBase,
    ),
  ),
);
