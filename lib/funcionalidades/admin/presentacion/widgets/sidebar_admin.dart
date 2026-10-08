import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';
import '../modelos/item_menu_admin.dart';

class SidebarAdmin extends StatelessWidget {
  const SidebarAdmin({
    super.key,
    this.usuarioAdministrador,
    this.onCerrarSesion,
    required this.items,
    required this.indiceSeleccionado,
    required this.onSeleccionar,
  });

  final Usuario? usuarioAdministrador;
  final Future<void> Function()? onCerrarSesion;
  final List<ItemMenuAdmin> items;
  final int indiceSeleccionado;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 284,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ColoresPanel.azul, ColoresPanel.turquesa],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MarcaAdmin(),
            const SizedBox(height: 22),
            _TarjetaSesionAdmin(usuarioAdministrador: usuarioAdministrador),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, indice) {
                  final item = items[indice];
                  final seleccionado = indice == indiceSeleccionado;

                  return _ItemSidebarAdmin(
                    item: item,
                    seleccionado: seleccionado,
                    onTap: () => onSeleccionar(indice),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCerrarSesion,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
            fontSize: 24,
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

class _TarjetaSesionAdmin extends StatelessWidget {
  const _TarjetaSesionAdmin({required this.usuarioAdministrador});

  final Usuario? usuarioAdministrador;

  @override
  Widget build(BuildContext context) {
    final nombre = usuarioAdministrador?.nombreCompleto.isNotEmpty == true
        ? usuarioAdministrador!.nombreCompleto
        : 'Administrador institucional';
    final correo = usuarioAdministrador?.correo ?? 'Sesion activa';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            correo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: ColoresPanel.verde,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sesion activa',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
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
              width: 38,
              height: 38,
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
                  const SizedBox(height: 2),
                  Text(
                    item.descripcion,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 11,
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
