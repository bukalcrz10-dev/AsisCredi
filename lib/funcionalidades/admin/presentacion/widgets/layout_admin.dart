import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../modelos/item_menu_admin.dart';
import 'sidebar_admin.dart';
import 'topbar_admin.dart';
import 'tema_admin.dart';
import 'espacio_visible_admin.dart';

class LayoutAdmin extends StatefulWidget {
  const LayoutAdmin({
    super.key,
    this.usuarioAdministrador,
    this.onCerrarSesion,
    required this.items,
    required this.indiceSeleccionado,
    required this.onSeleccionar,
    required this.child,
  });
  final Usuario? usuarioAdministrador;
  final Future<void> Function()? onCerrarSesion;
  final List<ItemMenuAdmin> items;
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;
  final Widget child;

  @override
  State<LayoutAdmin> createState() => _LayoutAdminState();
}

class _LayoutAdminState extends State<LayoutAdmin> {
  bool _menuVisible = true;

  @override
  Widget build(BuildContext context) => Theme(
    data: temaPanelAdmin(
      Theme.of(context),
      compacto: MediaQuery.sizeOf(context).width >= 600,
    ),
    child: Scaffold(
      backgroundColor: ColoresSistema.fondoApp,
      drawer: Drawer(
        width: 280,
        child: SafeArea(
          child: SidebarAdmin(
            onCerrarSesion: widget.onCerrarSesion,
            items: widget.items,
            indiceSeleccionado: widget.indiceSeleccionado,
            onSeleccionar: (indice) {
              Navigator.of(context).pop();
              widget.onSeleccionar(indice);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final escritorio = constraints.maxWidth >= 1200;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopbarAdmin(
                  usuarioAdministrador: widget.usuarioAdministrador,
                  menuExpandido: escritorio && _menuVisible,
                  onAbrirMenu: () {
                    if (escritorio) {
                      setState(() => _menuVisible = !_menuVisible);
                    } else {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (escritorio && _menuVisible)
                        SidebarAdmin(
                          onCerrarSesion: widget.onCerrarSesion,
                          items: widget.items,
                          indiceSeleccionado: widget.indiceSeleccionado,
                          onSeleccionar: widget.onSeleccionar,
                        ),
                      Expanded(
                        key: const ValueKey('contenido-admin'),
                        child: _ContenidoAdmin(child: widget.child),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ContenidoAdmin extends StatefulWidget {
  const _ContenidoAdmin({required this.child});
  final Widget child;

  @override
  State<_ContenidoAdmin> createState() => _ContenidoAdminState();
}

class _ContenidoAdminState extends State<_ContenidoAdmin> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final margen = MediaQuery.sizeOf(context).width < 600 ? 12.0 : 16.0;
      final altura = constraints.hasBoundedHeight
          ? (constraints.maxHeight - margen * 2).clamp(0.0, double.infinity)
          : 0.0;
      return Container(
        color: const Color(0xFFF3F6F8),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1760),
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.all(margen),
                child: SizedBox(
                  width: double.infinity,
                  child: EspacioVisibleAdmin(
                    altura: altura,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
