import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../modelos/item_menu_admin.dart';

class SidebarAdmin extends StatelessWidget {
  const SidebarAdmin({
    super.key,
    this.onCerrarSesion,
    required this.items,
    required this.indiceSeleccionado,
    required this.onSeleccionar,
  });

  final Future<void> Function()? onCerrarSesion;
  final List<ItemMenuAdmin> items;
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 216,
      decoration: const BoxDecoration(color: Color(0xFF123847)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MarcaAdmin(),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  for (var indice = 0; indice < items.length; indice++)
                    if (items[indice].grupoId == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child:
                            items.any(
                              (item) => item.grupoId == items[indice].id,
                            )
                            ? _GrupoSidebarAdmin(
                                item: items[indice],
                                expandido:
                                    items[indiceSeleccionado].grupoId ==
                                    items[indice].id,
                                children: [
                                  for (
                                    var hijo = 0;
                                    hijo < items.length;
                                    hijo++
                                  )
                                    if (items[hijo].grupoId == items[indice].id)
                                      _ItemSidebarAdmin(
                                        item: items[hijo],
                                        seleccionado:
                                            hijo == indiceSeleccionado,
                                        onTap: () => onSeleccionar(hijo),
                                      ),
                                ],
                              )
                            : _ItemSidebarAdmin(
                                item: items[indice],
                                seleccionado: indice == indiceSeleccionado,
                                onTap: () => onSeleccionar(indice),
                              ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCerrarSesion,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioCampo,
                    ),
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

class _GrupoSidebarAdmin extends StatelessWidget {
  const _GrupoSidebarAdmin({
    required this.item,
    required this.expandido,
    required this.children,
  });

  final ItemMenuAdmin item;
  final bool expandido;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('menu-${item.id}'),
    initiallyExpanded: expandido,
    tilePadding: const EdgeInsets.symmetric(horizontal: 10),
    childrenPadding: const EdgeInsets.only(left: 12),
    shape: const Border(),
    collapsedShape: const Border(),
    iconColor: Colors.white,
    collapsedIconColor: Colors.white,
    leading: Icon(item.icono, color: Colors.white, size: 20),
    title: Text(
      item.titulo,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
    children: children,
  );
}

class _MarcaAdmin extends StatelessWidget {
  const _MarcaAdmin();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CREDIASCIENDE',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Panel Administrativo',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ItemSidebarAdmin extends StatelessWidget {
  const _ItemSidebarAdmin({
    required this.item,
    required this.seleccionado,
    required this.onTap,
  });

  final ItemMenuAdmin item;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF007F8F) : Colors.transparent,
          borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
          border: Border.all(
            color: seleccionado
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: seleccionado
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icono, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
