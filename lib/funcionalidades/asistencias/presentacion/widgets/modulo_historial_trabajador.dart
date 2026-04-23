import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../controladores/controlador_asistencia.dart';
import 'resumen_historial_trabajador.dart';
import 'soporte_panel_trabajador.dart';

class ModuloHistorialTrabajador extends StatelessWidget {
  const ModuloHistorialTrabajador({
    super.key,
    required this.controlador,
    required this.onSeleccionarRango,
  });

  final ControladorAsistencia controlador;
  final Future<void> Function() onSeleccionarRango;

  @override
  Widget build(BuildContext context) {
    final resumenes = agruparHistorialPorDia(controlador.historialFiltrado);
    final rangoActual = controlador.rangoHistorialSeleccionado;

    return ListView(
      padding: MedidasSistema.paddingPagina,
      children: [
        Text(
          'Informe de mis Asistencias',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consulta tus registros personales por rango de fechas.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: ColoresSistema.textoSuave,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Row(
                  children: [
                    const _BotonInforme(
                      icono: Icons.table_view,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const _BotonInforme(
                      icono: Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        valor: rangoActual == null
                            ? 'Inicio'
                            : formatearFechaPanel(rangoActual.start),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        valor: rangoActual == null
                            ? 'Fin'
                            : formatearFechaPanel(rangoActual.end),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: FilledButton.tonal(
                        onPressed:
                            controlador.cargandoHistorial ? null : onSeleccionarRango,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MedidasSistema.radioCampo,
                            ),
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFE8EEF2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  'Registros encontrados: ${resumenes.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF0D4876),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (controlador.cargandoHistorial)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (resumenes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: TarjetaMensajePanel(
                    mensaje: 'No hay marcaciones para el filtro seleccionado.',
                    color: ColoresSistema.rojoInstitucional,
                    icono: Icons.inbox_outlined,
                  ),
                )
              else
                _TablaInformeAsistencias(resumenes: resumenes),
            ],
          ),
        ),
      ],
    );
  }
}

class _TablaInformeAsistencias extends StatelessWidget {
  const _TablaInformeAsistencias({
    required this.resumenes,
  });

  final List<ResumenDiaHistorial> resumenes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 530),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FilaCabeceraInforme(),
            ...resumenes
                .map((resumen) => _FilaInformeAsistencia(resumen: resumen)),
          ],
        ),
      ),
    );
  }
}

class _FilaCabeceraInforme extends StatelessWidget {
  const _FilaCabeceraInforme();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EEF2),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Row(
        children: [
          _CeldaCabecera(texto: 'Fecha', ancho: 78),
          _CeldaCabecera(texto: 'H. Entrada', ancho: 96),
          _CeldaCabecera(texto: 'H. Salida', ancho: 96),
          _CeldaCabecera(texto: 'Tardanza', ancho: 68),
          _CeldaCabecera(texto: 'T. Laborado', ancho: 78),
          _CeldaCabecera(texto: 'Descanso', ancho: 68),
          _CeldaCabecera(texto: '', ancho: 46),
        ],
      ),
    );
  }
}

class _CeldaCabecera extends StatelessWidget {
  const _CeldaCabecera({
    required this.texto,
    required this.ancho,
  });

  final String texto;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 11,
                color: ColoresSistema.iconoSuave,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _FilaInformeAsistencia extends StatelessWidget {
  const _FilaInformeAsistencia({
    required this.resumen,
  });

  final ResumenDiaHistorial resumen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColoresSistema.divisor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _CeldaDato(
            texto: formatearFechaPanel(resumen.fecha),
            ancho: 78,
          ),
          _CeldaDatoConEstado(
            texto: resumen.entrada == null
                ? '--:--'
                : formatearHoraAmPmPanel(resumen.entrada!.fechaHora),
            ancho: 96,
            completado: resumen.entrada != null,
          ),
          _CeldaDatoConEstado(
            texto: resumen.salida == null
                ? '--:--'
                : formatearHoraAmPmPanel(resumen.salida!.fechaHora),
            ancho: 96,
            completado: resumen.salida != null,
          ),
          _CeldaDato(
            texto: resumen.tardanza == null
                ? '--:--'
                : formatearDuracionPanel(resumen.tardanza!),
            ancho: 68,
          ),
          _CeldaDato(
            texto: resumen.tiempoLaborado == null
                ? '--:--'
                : formatearDuracionPanel(resumen.tiempoLaborado!),
            ancho: 78,
          ),
          _CeldaDato(
            texto: resumen.descanso == null
                ? '--:--'
                : formatearDuracionPanel(resumen.descanso!),
            ancho: 68,
          ),
          const _CeldaAccionImprimir(ancho: 46),
        ],
      ),
    );
  }
}

class _CeldaDato extends StatelessWidget {
  const _CeldaDato({
    required this.texto,
    required this.ancho,
  });

  final String texto;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _CeldaDatoConEstado extends StatelessWidget {
  const _CeldaDatoConEstado({
    required this.texto,
    required this.ancho,
    required this.completado,
  });

  final String texto;
  final bool completado;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: completado
                  ? ColoresSistema.verdeExito
                  : ColoresSistema.rojoInstitucional,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              completado ? Icons.check : Icons.priority_high,
              color: Colors.white,
              size: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CeldaAccionImprimir extends StatelessWidget {
  const _CeldaAccionImprimir({
    required this.ancho,
  });

  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: ColoresSistema.fondoSuaveAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresSistema.bordeCampo),
          ),
          child: const Icon(Icons.print_outlined, size: 18),
        ),
      ),
    );
  }
}

class _BotonInforme extends StatelessWidget {
  const _BotonInforme({
    required this.icono,
    required this.color,
  });

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresSistema.bordeCampo),
      ),
      child: Icon(icono, color: color),
    );
  }
}

class _CampoFiltroFecha extends StatelessWidget {
  const _CampoFiltroFecha({
    required this.valor,
  });

  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresSistema.bordeCampo),
      ),
      alignment: Alignment.center,
      child: Text(
        valor,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
