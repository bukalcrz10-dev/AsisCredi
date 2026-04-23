import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../modelos/item_menu_admin.dart';
import 'sidebar_admin.dart';
import 'topbar_admin.dart';

class LayoutAdmin extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final itemActual = items[indiceSeleccionado];

    return Scaffold(
      backgroundColor: ColoresSistema.fondoApp,
      body: SafeArea(
        child: Row(
          children: [
            SidebarAdmin(
              usuarioAdministrador: usuarioAdministrador,
              onCerrarSesion: onCerrarSesion,
              items: items,
              indiceSeleccionado: indiceSeleccionado,
              onSeleccionar: onSeleccionar,
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF7F2EF),
                      ColoresSistema.fondoApp,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Column(
                    children: [
                      TopbarAdmin(itemActual: itemActual),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
