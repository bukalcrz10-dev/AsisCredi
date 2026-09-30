import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../app/diseno_sistema.dart';
import '../controladores/controlador_asistencia.dart';
import '../servicios/exportador_historial.dart';
import 'resumen_historial_trabajador.dart';
import 'soporte_panel_trabajador.dart';

class ModuloHistorialTrabajador extends StatefulWidget {
  const ModuloHistorialTrabajador({
    super.key,
    required this.controlador,
    required this.onSeleccionarFechaInicio,
    required this.onSeleccionarFechaFin,
    required this.onBuscarRango,
  });

  final ControladorAsistencia controlador;
  final Future<void> Function() onSeleccionarFechaInicio;
  final Future<void> Function() onSeleccionarFechaFin;
  final Future<void> Function() onBuscarRango;

  @override
  State<ModuloHistorialTrabajador> createState() =>
      _ModuloHistorialTrabajadorState();
}

class _ModuloHistorialTrabajadorState extends State<ModuloHistorialTrabajador> {
  bool _exportando = false;
  ControladorAsistencia get controlador => widget.controlador;
  Future<void> Function() get onSeleccionarFechaInicio =>
      widget.onSeleccionarFechaInicio;
  Future<void> Function() get onSeleccionarFechaFin =>
      widget.onSeleccionarFechaFin;
  Future<void> Function() get onBuscarRango => widget.onBuscarRango;

  Future<void> _abrirUbicacion(String destino) async {
    try {
      await const MethodChannel(
        'asistencia/informes',
      ).invokeMethod<void>('abrirUbicacion', {'destino': destino});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos abrir la ubicación. Busca el informe en la carpeta que elegiste al guardar.',
          ),
        ),
      );
    }
  }

  Future<void> _exportar({bool excel = false, ResumenDiaHistorial? dia}) async {
    if (_exportando || controlador.cargandoHistorial) return;
    final dias = dia == null
        ? agruparHistorialPorDia(controlador.historialFiltrado)
        : [dia];
    if (dias.isEmpty) return;
    final informe = InformeHistorial(
      trabajador:
          controlador.perfilActual?.nombreCompleto ??
          dias.first.marcaciones.first.nombreUsuario,
      dias: dias,
    );
    setState(() => _exportando = true);
    try {
      if (dia != null) {
        await Printing.layoutPdf(
          name: informe.nombreArchivo,
          format: PdfPageFormat.a4.landscape,
          onLayout: (formato) => informe.generarPdf(formato: formato),
        );
      } else {
        final bytes = excel
            ? informe.generarExcel()
            : await informe.generarPdf();
        final extension = excel ? 'xlsx' : 'pdf';
        final mime = excel ? MimeType.microsoftExcel : MimeType.pdf;
        final String? destino;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
          destino = await FileSaver.instance.saveFile(
            name: informe.nombreArchivo,
            bytes: bytes,
            fileExtension: extension,
            mimeType: mime,
          );
        } else {
          destino = await FileSaver.instance.saveAs(
            name: informe.nombreArchivo,
            bytes: bytes,
            fileExtension: extension,
            mimeType: mime,
          );
        }
        if (mounted && destino != null) {
          final ubicacionGuardada = destino;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Informe guardado.'),
              duration: const Duration(seconds: 10),
              action: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                  ? SnackBarAction(
                      label: 'Ir a ubicación',
                      onPressed: () => _abrirUbicacion(ubicacionGuardada),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos generar o guardar el informe. Intenta nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumenes = agruparHistorialPorDia(controlador.historialFiltrado);

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
                    _BotonInforme(
                      icono: Icons.table_view,
                      color: Colors.green,
                      etiqueta: 'Exportar a Excel',
                      onPressed:
                          _exportando ||
                              controlador.cargandoHistorial ||
                              resumenes.isEmpty
                          ? null
                          : () => _exportar(excel: true),
                    ),
                    const SizedBox(width: 8),
                    _BotonInforme(
                      icono: Icons.picture_as_pdf_outlined,
                      color: Colors.red,
                      etiqueta: 'Exportar a PDF',
                      onPressed:
                          _exportando ||
                              controlador.cargandoHistorial ||
                              resumenes.isEmpty
                          ? null
                          : () => _exportar(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        etiqueta: 'Inicio',
                        valor:
                            controlador.fechaInicioHistorialSeleccionada == null
                            ? ''
                            : formatearFechaPanel(
                                controlador.fechaInicioHistorialSeleccionada!,
                              ),
                        onTap: controlador.cargandoHistorial
                            ? null
                            : onSeleccionarFechaInicio,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CampoFiltroFecha(
                        etiqueta: 'Fin',
                        valor: controlador.fechaFinHistorialSeleccionada == null
                            ? ''
                            : formatearFechaPanel(
                                controlador.fechaFinHistorialSeleccionada!,
                              ),
                        onTap: controlador.cargandoHistorial
                            ? null
                            : onSeleccionarFechaFin,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: FilledButton(
                        onPressed: controlador.cargandoHistorial
                            ? null
                            : onBuscarRango,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
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
              if (_exportando) const LinearProgressIndicator(),
              Container(
                width: double.infinity,
                color: const Color(0xFFE8EEF2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
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
                _TablaInformeAsistencias(
                  resumenes: resumenes,
                  onImprimir: _exportando ? null : (dia) => _exportar(dia: dia),
                ),
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
    required this.onImprimir,
  });

  final List<ResumenDiaHistorial> resumenes;
  final ValueChanged<ResumenDiaHistorial>? onImprimir;

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
            ...resumenes.map(
              (resumen) => _FilaInformeAsistencia(
                resumen: resumen,
                onImprimir: onImprimir == null
                    ? null
                    : () => onImprimir!(resumen),
              ),
            ),
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
          _CeldaCabecera(texto: 'Bloque', ancho: 68),
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
  const _CeldaCabecera({required this.texto, required this.ancho});

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
    required this.onImprimir,
  });

  final ResumenDiaHistorial resumen;
  final VoidCallback? onImprimir;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ColoresSistema.divisor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _CeldaDato(texto: formatearFechaPanel(resumen.fecha), ancho: 78),
          _CeldaDato(texto: _textoBloque(resumen), ancho: 68),
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
          _CeldaAccionImprimir(ancho: 46, onPressed: onImprimir),
        ],
      ),
    );
  }
}

String _textoBloque(ResumenDiaHistorial resumen) {
  final tieneManana =
      resumen.entradaManana != null || resumen.salidaManana != null;
  final tieneTarde =
      resumen.entradaTarde != null || resumen.salidaTarde != null;

  if (tieneManana && tieneTarde) {
    return '1 y 2';
  }

  if (tieneTarde) {
    return '2';
  }

  if (tieneManana) {
    return '1';
  }

  return '--';
}

class _CeldaDato extends StatelessWidget {
  const _CeldaDato({required this.texto, required this.ancho});

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
  const _CeldaAccionImprimir({required this.ancho, required this.onPressed});

  final double ancho;
  final VoidCallback? onPressed;

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
          child: IconButton(
            tooltip: 'Imprimir este día',
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: const Icon(Icons.print_outlined, size: 18),
          ),
        ),
      ),
    );
  }
}

class _BotonInforme extends StatelessWidget {
  const _BotonInforme({
    required this.icono,
    required this.color,
    required this.etiqueta,
    required this.onPressed,
  });

  final IconData icono;
  final Color color;
  final String etiqueta;
  final VoidCallback? onPressed;

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
      child: IconButton(
        tooltip: etiqueta,
        onPressed: onPressed,
        icon: Icon(icono),
        color: color,
      ),
    );
  }
}

class _CampoFiltroFecha extends StatelessWidget {
  const _CampoFiltroFecha({
    required this.etiqueta,
    required this.valor,
    this.onTap,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final estaVacio = valor.isEmpty;
    final child = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresSistema.bordeCampo),
      ),
      alignment: Alignment.center,
      child: Text(
        estaVacio ? etiqueta : valor,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: estaVacio ? ColoresSistema.textoSuave : null,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
  }
}
