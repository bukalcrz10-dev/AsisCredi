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
  });

  final String titulo;
  final String valor;
  final String detalle;
  final Color colorAcento;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorAcento.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: colorAcento, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: ColoresSistema.textoSuave,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
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
