import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';

class TarjetaResumenAdmin extends StatelessWidget {
  const TarjetaResumenAdmin({
    super.key,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.colorAcento,
    required this.icono,
    this.compacta = false,
  });

  final String titulo;
  final String valor;
  final String detalle;
  final Color colorAcento;
  final IconData icono;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    if (compacta) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorAcento.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorAcento.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colorAcento.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icono, size: 19, color: colorAcento),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valor,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ColoresSistema.textoBase,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: ColoresSistema.textoBase,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detalle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresSistema.textoSecundario,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colorAcento.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: colorAcento, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 14,
              color: ColoresSistema.textoBase,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColoresSistema.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}
