import 'package:flutter/material.dart';
import '../../../../app/diseno_sistema.dart';

class IndicadorDashboardAdmin extends StatelessWidget {
  const IndicadorDashboardAdmin({
    super.key,
    required this.colorAcento,
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.valor,
  });

  final Color colorAcento;
  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorAcento.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorAcento.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: colorAcento.withValues(alpha: 0.75)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorAcento.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icono, color: colorAcento, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        valor,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colorAcento,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Tooltip(
                  message: etiqueta,
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ColoresSistema.textoTitulo,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
