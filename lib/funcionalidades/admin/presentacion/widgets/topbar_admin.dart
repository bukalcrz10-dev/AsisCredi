import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';

class TopbarAdmin extends StatefulWidget {
  const TopbarAdmin({
    super.key,
    this.usuarioAdministrador,
    this.onAbrirMenu,
    this.menuExpandido = false,
  });
  final Usuario? usuarioAdministrador;
  final VoidCallback? onAbrirMenu;
  final bool menuExpandido;

  @override
  State<TopbarAdmin> createState() => _TopbarAdminState();
}

class _TopbarAdminState extends State<TopbarAdmin> {
  DateTime _ahora = DateTime.now();
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.usuarioAdministrador?.nombreCompleto.trim();
    final nombreVisible = nombre == null || nombre.isEmpty
        ? 'Administrador'
        : nombre;
    final correo = widget.usuarioAdministrador?.correo.trim() ?? '';
    final fecha =
        '${_ahora.day.toString().padLeft(2, '0')}/${_ahora.month.toString().padLeft(2, '0')}/${_ahora.year}';
    final jornada = switch (_ahora.weekday) {
      DateTime.saturday => 'Sábado',
      DateTime.sunday => 'No laborable',
      _ => 'Día laborable',
    };
    final fechaWidget = Tooltip(
      message: 'Fecha actual · $jornada',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: ColoresPanel.azul,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fecha,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    final usuarioWidget = Tooltip(
      message: correo.isEmpty ? nombreVisible : '$nombreVisible\n$correo',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: ColoresPanel.azul,
            child: Icon(Icons.person_outline, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nombreVisible,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    final menu = widget.onAbrirMenu == null
        ? null
        : IconButton(
            tooltip: widget.menuExpandido ? 'Ocultar menú' : 'Abrir menú',
            onPressed: widget.onAbrirMenu,
            icon: const Icon(Icons.menu),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ColoresSistema.divisor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560 ||
              MediaQuery.textScalerOf(context).scale(14) > 21) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (menu != null) ...[menu, const SizedBox(width: 8)],
                    Flexible(child: fechaWidget),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(420, constraints.maxWidth),
                    ),
                    child: usuarioWidget,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              if (menu != null) ...[menu, const SizedBox(width: 8)],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: fechaWidget,
                ),
              ),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(420, constraints.maxWidth * .5),
                ),
                child: usuarioWidget,
              ),
            ],
          );
        },
      ),
    );
  }
}
