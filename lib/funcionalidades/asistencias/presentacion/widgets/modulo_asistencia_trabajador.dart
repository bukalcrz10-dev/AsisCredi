import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';

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
    final entrada = controlador.ultimaEntrada;
    final salida = controlador.ultimaSalida;
    final totalCompletados = (entrada != null ? 1 : 0) + (salida != null ? 1 : 0);
    final progreso = totalCompletados / 2;
    final textoProgreso = '$totalCompletados/2';

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
                        ? 'Jornada completada'
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
                const SizedBox(height: 10),
                _TarjetaHorarioDia(
                  entrada: entrada == null
                      ? 'Pendiente'
                      : _formatearSoloHora(entrada.fechaHora),
                  salida: salida == null
                      ? 'Pendiente'
                      : _formatearSoloHora(salida.fechaHora),
                ),
                const SizedBox(height: 12),
                if (entrada == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          onAbrirProcesoMarcacion(TipoMarcacion.entrada),
                      icon: const Icon(Icons.login),
                      label: const Text('Registrar entrada'),
                    ),
                  )
                else if (salida == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          onAbrirProcesoMarcacion(TipoMarcacion.salida),
                      icon: const Icon(Icons.logout),
                      label: const Text('Registrar salida'),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaHorarioDia extends StatelessWidget {
  const _TarjetaHorarioDia({
    required this.entrada,
    required this.salida,
  });

  final String entrada;
  final String salida;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BloqueHorario(
          etiqueta: 'Entrada',
          valor: entrada,
          icono: Icons.login,
        ),
        const SizedBox(height: 10),
        _BloqueHorario(
          etiqueta: 'Salida',
          valor: salida,
          icono: Icons.logout,
        ),
      ],
    );
  }
}

class _BloqueHorario extends StatelessWidget {
  const _BloqueHorario({
    required this.etiqueta,
    required this.valor,
    required this.icono,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final pendiente = valor == 'Pendiente';
    final colorEstado = pendiente
        ? ColoresSistema.rojoInstitucional
        : ColoresSistema.verdeExito;

    return Container(
      width: double.infinity,
      padding: MedidasSistema.paddingBloque,
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: colorEstado.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorEstado.withValues(alpha: 0.14),
            foregroundColor: colorEstado,
            child: Icon(icono, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: ColoresSistema.textoSuave,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ColoresSistema.textoFuerte,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
            ),
            child: Text(
              pendiente ? 'PENDIENTE' : 'COMPLETADO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colorEstado,
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

String _formatearSoloHora(DateTime fechaHora) {
  final hora = fechaHora.hour.toString().padLeft(2, '0');
  final minuto = fechaHora.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}
