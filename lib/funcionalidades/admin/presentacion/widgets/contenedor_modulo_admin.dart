import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';

class ContenedorModuloAdmin extends StatelessWidget {
  const ContenedorModuloAdmin({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.child,
    this.expandirContenido = false,
    this.accionCabecera,
  });

  final String titulo;
  final String descripcion;
  final Widget child;
  final bool expandirContenido;
  final Widget? accionCabecera;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: expandirContenido ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final encabezado = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresSistema.textoSecundario,
                      ),
                    ),
                  ],
                ],
              );
              if (accionCabecera == null) return encabezado;
              if (constraints.maxWidth <
                  600 * MediaQuery.textScalerOf(context).scale(14) / 14) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    encabezado,
                    const SizedBox(height: 12),
                    accionCabecera!,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: encabezado),
                  const SizedBox(width: 16),
                  accionCabecera!,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (expandirContenido) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
