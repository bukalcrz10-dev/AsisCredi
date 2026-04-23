import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import 'contenedor_modulo_admin.dart';
import 'tarjeta_resumen_admin.dart';

class ModuloDashboardAdmin extends StatelessWidget {
  const ModuloDashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: const [
            TarjetaResumenAdmin(
              titulo: 'Trabajadores activos',
              valor: '128',
              detalle: 'Personal habilitado en el sistema institucional.',
              colorAcento: ColoresSistema.rojoInstitucional,
              icono: Icons.groups_2_outlined,
            ),
            TarjetaResumenAdmin(
              titulo: 'Marcaciones de hoy',
              valor: '245',
              detalle: 'Registros validados durante la jornada.',
              colorAcento: ColoresSistema.verdeInstitucional,
              icono: Icons.fact_check_outlined,
            ),
            TarjetaResumenAdmin(
              titulo: 'Incidencias abiertas',
              valor: '12',
              detalle: 'Eventos que requieren revision administrativa.',
              colorAcento: Color(0xFFB66A18),
              icono: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              flex: 7,
              child: _PanelActividadRecienteAdmin(),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _PanelAccionesAdmin(),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PanelActividadRecienteAdmin extends StatelessWidget {
  const _PanelActividadRecienteAdmin();

  @override
  Widget build(BuildContext context) {
    return ContenedorModuloAdmin(
      titulo: 'Actividad reciente',
      descripcion: 'Resumen institucional visible para control administrativo.',
      child: Column(
        children: const [
          _FilaActividadAdmin(
            titulo: 'Turno de manana consolidado',
            detalle: 'La mayoria del personal registro asistencia correctamente.',
            estado: '08:30 AM',
          ),
          SizedBox(height: 10),
          _FilaActividadAdmin(
            titulo: 'Incidencias pendientes',
            detalle: 'Se identificaron validaciones de rostro no completadas.',
            estado: '12 casos',
          ),
          SizedBox(height: 10),
          _FilaActividadAdmin(
            titulo: 'Control institucional activo',
            detalle: 'La validacion operativa se concentra en la sede principal del sistema.',
            estado: 'Sede principal',
          ),
        ],
      ),
    );
  }
}

class _FilaActividadAdmin extends StatelessWidget {
  const _FilaActividadAdmin({
    required this.titulo,
    required this.detalle,
    required this.estado,
  });

  final String titulo;
  final String detalle;
  final String estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoSuave,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 44,
            decoration: BoxDecoration(
              color: ColoresSistema.rojoInstitucional,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(detalle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ColoresSistema.fondoChip,
              borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
            ),
            child: Text(
              estado,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAccionesAdmin extends StatelessWidget {
  const _PanelAccionesAdmin();

  @override
  Widget build(BuildContext context) {
    return ContenedorModuloAdmin(
      titulo: 'Acciones rapidas',
      descripcion: 'Accesos visuales para la siguiente fase del panel admin.',
      child: Column(
        children: const [
          _AccionAdmin(
            icono: Icons.person_add_alt_1_outlined,
            titulo: 'Registrar trabajador',
          ),
          SizedBox(height: 10),
          _AccionAdmin(
            icono: Icons.groups_outlined,
            titulo: 'Gestionar trabajadores',
          ),
          SizedBox(height: 10),
          _AccionAdmin(
            icono: Icons.request_page_outlined,
            titulo: 'Emitir reporte',
          ),
        ],
      ),
    );
  }
}

class _AccionAdmin extends StatelessWidget {
  const _AccionAdmin({
    required this.icono,
    required this.titulo,
  });

  final IconData icono;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoSuave,
        borderRadius: BorderRadius.circular(MedidasSistema.radioCampo),
        border: Border.all(color: ColoresSistema.bordeIntermedio),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColoresSistema.fondoChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: ColoresSistema.rojoInstitucional),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }
}
