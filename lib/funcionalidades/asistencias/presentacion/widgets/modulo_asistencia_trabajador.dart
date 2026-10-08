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
    final progreso = resumen.tramos.isEmpty
        ? 0.0
        : totalCompletados / resumen.tramos.length;
    final textoProgreso = '$totalCompletados/${resumen.tramos.length}';
    final siguienteTipo = controlador.horarioAsignado == null
        ? null
        : resumen.siguienteTipoMarcacion;
    final mensajeBloqueo = controlador.horarioAsignado == null
        ? 'Tu cargo no tiene horario asignado. Solicita revisión al administrador.'
        : resumen.mensajeBloqueoJornada;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      children: [
        if (!resumen.esNoLaborable) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
              side: BorderSide(color: ColoresSistema.bordeCampo, width: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Progreso del dia',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(letterSpacing: 1.1),
                      ),
                      const Spacer(),
                      Text(
                        textoProgreso,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioChip,
                    ),
                    child: LinearProgressIndicator(
                      value: progreso,
                      color: ColoresPanel.verde,
                      minHeight: 6,
                      backgroundColor: Colors.blueGrey.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ColoresSistema.verdeExito.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        MedidasSistema.radioChip,
                      ),
                    ),
                    child: Text(
                      '$totalCompletados bloques completados',
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
          const SizedBox(height: 6),
        ],
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
                if (controlador.horarioAsignado != null)
                  for (final tramo in resumen.tramos) ...[
                    _TarjetaHorarioTramo(tramo: tramo),
                    const SizedBox(height: 6),
                  ],
                if (resumen.tardanzaTotal != null)
                  Text(
                    'Tardanza: ${formatearDuracionPanel(resumen.tardanzaTotal!)}',
                  ),
                if (resumen.salidaAnticipadaTotal > Duration.zero)
                  Text(
                    'Salida anticipada: ${formatearDuracionPanel(resumen.salidaAnticipadaTotal)}',
                  ),
                const SizedBox(height: 8),
                if (mensajeBloqueo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TarjetaMensajePanel(
                      mensaje: mensajeBloqueo,
                      color: resumen.esNoLaborable
                          ? ColoresSistema.textoSuave
                          : ColoresSistema.rojoInstitucional,
                      icono: resumen.esNoLaborable
                          ? Icons.event_available_outlined
                          : Icons.block_outlined,
                    ),
                  ),
                if (siguienteTipo != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: ColoresPanel.azul),
                      onPressed: () => onAbrirProcesoMarcacion(siguienteTipo),
                      icon: Icon(
                        siguienteTipo == TipoMarcacion.entrada
                            ? Icons.login
                            : Icons.logout,
                      ),
                      label: const Text('Registrarse'),
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
  const _TarjetaHorarioTramo({required this.tramo});

  final TramoJornadaLaboral tramo;

  @override
  Widget build(BuildContext context) {
    final colorBase = tramo.completo
        ? ColoresPanel.verde
        : ColoresPanel.azul;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: colorBase.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: colorBase.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorBase,
            child: Text(
              '${tramo.orden}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 150,
                child: Column(
                  children: [
                    _FilaHorarioTramo(
                      etiqueta: 'ENTRADA',
                      horaProgramada: formatearHoraAmPmPanel(
                        tramo.entradaProgramada,
                      ),
                      completado: tramo.entradaMarcada != null,
                    ),
                    const SizedBox(height: 10),
                    _FilaHorarioTramo(
                      etiqueta: 'SALIDA',
                      horaProgramada: formatearHoraAmPmPanel(
                        tramo.salidaProgramada,
                      ),
                      completado: tramo.salidaMarcada != null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: colorBase.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
            ),
            child: Text(
              tramo.completo ? 'COMPLETO' : 'PENDIENTE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colorBase,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
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
          width: 48,
          child: Text(
            etiqueta,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 9,
              letterSpacing: 0.8,
              color: ColoresSistema.textoSuave,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
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
        ),
        const SizedBox(width: 4),
        Icon(
          completado ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 15,
          color: completado
              ? ColoresSistema.verdeExito
              : ColoresSistema.textoSuave,
        ),
      ],
    );
  }
}
