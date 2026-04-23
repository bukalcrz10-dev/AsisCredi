import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import 'contenedor_modulo_admin.dart';

class ModuloPlaceholderAdmin extends StatelessWidget {
  const ModuloPlaceholderAdmin({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.columnas,
  });

  final String titulo;
  final String descripcion;
  final List<String> columnas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContenedorModuloAdmin(
          titulo: titulo,
          descripcion: descripcion,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _FiltroVisualAdmin(
                      icono: Icons.search,
                      texto: 'Buscar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _FiltroVisualAdmin(
                      icono: Icons.calendar_today_outlined,
                      texto: 'Fecha',
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: FilledButton.tonalIcon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune),
                      label: const Text('Filtrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColoresSistema.fondoSuave,
            borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
            border: Border.all(color: ColoresSistema.bordeIntermedio),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EFF3),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(MedidasSistema.radioBloque),
                    topRight: Radius.circular(MedidasSistema.radioBloque),
                  ),
                ),
                child: Row(
                  children: columnas
                      .map(
                        (columna) => Expanded(
                          child: Text(
                            columna,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 12,
                                  color: ColoresSistema.iconoSuave,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              ...List.generate(4, (indice) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: ColoresSistema.divisor),
                    ),
                  ),
                  child: Row(
                    children: columnas
                        .map(
                          (columna) => Expanded(
                            child: Text(
                              'Vista ${indice + 1}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColoresSistema.textoBase,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FiltroVisualAdmin extends StatelessWidget {
  const _FiltroVisualAdmin({
    required this.icono,
    required this.texto,
  });

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeCampo),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18),
          const SizedBox(width: 10),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresSistema.textoSuave,
                ),
          ),
        ],
      ),
    );
  }
}
