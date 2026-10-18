import 'package:flutter/widgets.dart';

/// Altura útil del panel, descontando la barra superior y los márgenes.
class EspacioVisibleAdmin extends InheritedWidget {
  const EspacioVisibleAdmin({
    super.key,
    required this.altura,
    required super.child,
  });

  final double altura;

  static double alturaDe(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EspacioVisibleAdmin>()
          ?.altura ??
      0;

  @override
  bool updateShouldNotify(EspacioVisibleAdmin oldWidget) =>
      altura != oldWidget.altura;
}
