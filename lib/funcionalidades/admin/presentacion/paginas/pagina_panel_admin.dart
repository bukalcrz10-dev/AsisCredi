import 'package:flutter/material.dart';

import '../../../usuarios/dominio/entidades/usuario.dart';
import '../modelos/item_menu_admin.dart';
import '../widgets/layout_admin.dart';
import '../widgets/modulo_asistencias_admin.dart';
import '../widgets/modulo_dashboard_admin.dart';
import '../widgets/modulo_trabajadores_admin.dart';

class PaginaPanelAdmin extends StatefulWidget {
  const PaginaPanelAdmin({
    super.key,
    this.usuarioAdministrador,
    this.onCerrarSesion,
  });

  final Usuario? usuarioAdministrador;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<PaginaPanelAdmin> createState() => _PaginaPanelAdminState();
}

class _PaginaPanelAdminState extends State<PaginaPanelAdmin> {
  int _indiceSeleccionado = 0;

  static const _items = <ItemMenuAdmin>[
    ItemMenuAdmin(
      id: 'dashboard',
      titulo: 'Dashboard',
      descripcion: 'Resumen general del sistema institucional.',
      icono: Icons.dashboard_outlined,
    ),
    ItemMenuAdmin(
      id: 'trabajadores',
      titulo: 'Trabajadores',
      descripcion: 'Gestion del personal institucional y su estado.',
      icono: Icons.groups_outlined,
    ),
    ItemMenuAdmin(
      id: 'asistencias',
      titulo: 'Asistencias',
      descripcion: 'Consulta administrativa de marcaciones y validaciones.',
      icono: Icons.fact_check_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutAdmin(
      usuarioAdministrador: widget.usuarioAdministrador,
      onCerrarSesion: widget.onCerrarSesion,
      items: _items,
      indiceSeleccionado: _indiceSeleccionado,
      onSeleccionar: (indice) {
        setState(() {
          _indiceSeleccionado = indice;
        });
      },
      child: KeyedSubtree(
        key: ValueKey(_items[_indiceSeleccionado].id),
        child: _crearModuloActual(),
      ),
    );
  }

  Widget _crearModuloActual() {
    switch (_items[_indiceSeleccionado].id) {
      case 'dashboard':
        return const ModuloDashboardAdmin();
      case 'trabajadores':
        return const ModuloTrabajadoresAdmin();
      case 'asistencias':
        return const ModuloAsistenciasAdmin();
      default:
        return const SizedBox.shrink();
    }
  }
}
