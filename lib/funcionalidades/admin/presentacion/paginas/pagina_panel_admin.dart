import 'package:flutter/material.dart';

import '../../../usuarios/dominio/entidades/usuario.dart';
import '../modelos/item_menu_admin.dart';
import '../widgets/layout_admin.dart';
import '../widgets/modulo_dashboard_admin.dart';
import '../widgets/modulo_trabajadores_admin.dart';
import '../widgets/modulo_sedes_admin.dart';

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
  String? _trabajadorDashboardId;

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
      id: 'crear_trabajador',
      grupoId: 'trabajadores',
      titulo: 'Crear trabajador',
      descripcion: 'Registro de personal y acceso al sistema.',
      icono: Icons.person_add_alt_1_outlined,
    ),
    ItemMenuAdmin(
      id: 'trabajadores_vigentes',
      grupoId: 'trabajadores',
      titulo: 'Vigentes',
      descripcion: 'Consulta y gestión de los trabajadores vigentes.',
      icono: Icons.verified_user_outlined,
    ),
    ItemMenuAdmin(
      id: 'sedes',
      titulo: 'Sedes',
      descripcion: 'Configuración de ubicaciones y zonas de asistencia.',
      icono: Icons.location_on_outlined,
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
          _trabajadorDashboardId = null;
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
        return ModuloDashboardAdmin(
          onAbrirTrabajador: (id) => setState(() {
            _trabajadorDashboardId = id;
            _indiceSeleccionado = _items.indexWhere(
              (item) => item.id == 'trabajadores_vigentes',
            );
          }),
          onAbrirSedes: () => setState(() {
            _indiceSeleccionado = _items.indexWhere(
              (item) => item.id == 'sedes',
            );
          }),
        );
      case 'trabajadores':
      case 'trabajadores_vigentes':
        return ModuloTrabajadoresAdmin(
          vista: VistaTrabajadoresAdmin.vigentes,
          trabajadorInicialId: _trabajadorDashboardId,
        );
      case 'crear_trabajador':
        return const ModuloTrabajadoresAdmin(
          vista: VistaTrabajadoresAdmin.crear,
        );
      case 'sedes':
        return const ModuloSedesAdmin();
      default:
        return const SizedBox.shrink();
    }
  }
}
