import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';
import '../controladores/controlador_asistencia_auxiliares.dart';
import 'soporte_panel_trabajador.dart';

class ModuloAsistenciaTrabajador extends StatelessWidget {
  const ModuloAsistenciaTrabajador({
    super.key,
    required this.controlador,
    required this.onAbrirProcesoMarcacion,
  });

  final ControladorAsistencia controlador;
  final Future<void> Function(TipoMarcacion tipoMarcacion)
      onAbrirProcesoMarcacion;

  @override
  Widget build(BuildContext context) {
    final resumen = controlador.resumenJornadaHoy;
    final totalCompletados = resumen.totalBloquesCompletos;
    final progreso = totalCompletados / 2;
    final textoProgreso = '$totalCompletados/2';
    final siguienteTipo = resumen.siguienteTipoMarcacion;
    final siguienteEtiqueta = resumen.siguienteEtiquetaAccion;
    final mensajeBloqueo = resumen.mensajeBloqueoJornada;

    return ListView(
      padding: MedidasSistema.paddingPagina,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
            side: BorderSide(
              color: ColoresSistema.bordeCampo,
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Progreso del dia',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.1,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      textoProgreso,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 10,
                    backgroundColor: Colors.blueGrey.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ColoresSistema.verdeExito.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
                  ),
                  child: Text(
                    totalCompletados == 2
                        ? '2 completados'
                        : '$totalCompletados completados',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: ColoresSistema.verdeInstitucional,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'TUS HORARIOS DE HOY',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          letterSpacing: 1.1,
                          color: ColoresSistema.textoSuave,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                _TarjetaHorarioTramo(tramo: resumen.manana),
                const SizedBox(height: 12),
                _TarjetaHorarioTramo(tramo: resumen.tarde),
                const SizedBox(height: 14),
                if (mensajeBloqueo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TarjetaMensajePanel(
                      mensaje: mensajeBloqueo,
                      color: ColoresSistema.rojoInstitucional,
                      icono: Icons.block_outlined,
                    ),
                  ),
                if (siguienteTipo != null && siguienteEtiqueta != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => onAbrirProcesoMarcacion(siguienteTipo),
                      icon: Icon(
                        siguienteTipo == TipoMarcacion.entrada
                            ? Icons.login
                            : Icons.logout,
                      ),
                      label: Text(siguienteEtiqueta),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaHorarioTramo extends StatelessWidget {
  const _TarjetaHorarioTramo({
    required this.tramo,
  });

  final TramoJornadaLaboral tramo;

  @override
  Widget build(BuildContext context) {
    final colorBase = tramo.completo
        ? ColoresSistema.verdeExito
        : ColoresSistema.rojoInstitucional;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorBase.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: colorBase.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorBase,
            child: Text(
              '${tramo.orden}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                _FilaHorarioTramo(
                  etiqueta: 'ENTRADA',
                  horaProgramada: formatearHoraAmPmPanel(tramo.entradaProgramada),
                  completado: tramo.entradaMarcada != null,
                ),
                const SizedBox(height: 8),
                _FilaHorarioTramo(
                  etiqueta: 'SALIDA',
                  horaProgramada: formatearHoraAmPmPanel(tramo.salidaProgramada),
                  completado: tramo.salidaMarcada != null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colorBase.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
            ),
            child: Text(
              tramo.completo ? 'COMPLETO' : 'PENDIENTE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colorBase,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaHorarioTramo extends StatelessWidget {
  const _FilaHorarioTramo({
    required this.etiqueta,
    required this.horaProgramada,
    required this.completado,
  });

  final String etiqueta;
  final String horaProgramada;
  final bool completado;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            etiqueta,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: ColoresSistema.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            horaProgramada,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ColoresSistema.textoFuerte,
                ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          completado ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 15,
          color:
              completado ? ColoresSistema.verdeExito : ColoresSistema.textoSuave,
        ),
      ],
    );
  }
}
