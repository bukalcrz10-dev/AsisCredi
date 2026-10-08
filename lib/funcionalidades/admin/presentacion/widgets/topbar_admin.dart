import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../modelos/item_menu_admin.dart';

class TopbarAdmin extends StatelessWidget {
  const TopbarAdmin({super.key, required this.itemActual});

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 18),
          const _FranjaTopbarAdmin(),
        ],
      ),
    );
  }
}

class _FranjaTopbarAdmin extends StatelessWidget {
  const _FranjaTopbarAdmin();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children: const [
          _ItemFranjaTopbarAdmin(
            icono: Icons.today_outlined,
            titulo: 'Fecha actual',
            valor: '24/04/2026',
          ),
          _SeparadorFranjaTopbarAdmin(),
          _ItemFranjaTopbarAdmin(
            icono: Icons.approval_outlined,
            titulo: 'Estado',
            valor: 'Operativo',
          ),
          _SeparadorFranjaTopbarAdmin(),
          _ItemFranjaTopbarAdmin(
            icono: Icons.domain_verification_outlined,
            titulo: 'Jornada',
            valor: 'Dia laborable',
          ),
        ],
      ),
    );
  }
}

class _ItemFranjaTopbarAdmin extends StatelessWidget {
  const _ItemFranjaTopbarAdmin({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: ColoresPanel.turquesa),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ColoresSistema.textoSuave,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeparadorFranjaTopbarAdmin extends StatelessWidget {
  const _SeparadorFranjaTopbarAdmin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: ColoresSistema.bordeIntermedio,
    );
  }
}
