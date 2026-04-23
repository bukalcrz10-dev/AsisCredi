import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../modelos/item_menu_admin.dart';

class TopbarAdmin extends StatelessWidget {
  const TopbarAdmin({
    super.key,
    required this.itemActual,
  });

  final ItemMenuAdmin itemActual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
        border: Border.all(color: ColoresSistema.bordeSuave),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemActual.titulo,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ColoresSistema.textoTitulo,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  itemActual.descripcion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoSecundario,
                      ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              _ChipTopbarAdmin(
                icono: Icons.calendar_today_outlined,
                texto: '20/04/2026',
              ),
              _ChipTopbarAdmin(
                icono: Icons.account_balance_outlined,
                texto: 'UNACHU',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipTopbarAdmin extends StatelessWidget {
  const _ChipTopbarAdmin({
    required this.icono,
    required this.texto,
  });

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoChip,
        borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: ColoresSistema.iconoSuave),
          const SizedBox(width: 8),
          Text(
            texto,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
