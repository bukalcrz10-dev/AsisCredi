import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';

class ContenedorModuloAdmin extends StatelessWidget {
  const ContenedorModuloAdmin({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.child,
    this.expandirContenido = false,
  });

  final String titulo;
  final String descripcion;
  final Widget child;
  final bool expandirContenido;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: expandirContenido ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresSistema.textoSecundario,
                ),
          ),
          const SizedBox(height: 22),
          if (expandirContenido) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
