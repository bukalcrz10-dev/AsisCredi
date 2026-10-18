import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../asistencias/presentacion/servicios/exportador_historial.dart';

class ExportacionAsistenciasTrabajadorAdmin extends StatefulWidget {
  const ExportacionAsistenciasTrabajadorAdmin({
    super.key,
    required this.informe,
  });
  final InformeHistorial informe;

  @override
  State<ExportacionAsistenciasTrabajadorAdmin> createState() =>
      _ExportacionAsistenciasTrabajadorAdminState();
}

class _ExportacionAsistenciasTrabajadorAdminState
    extends State<ExportacionAsistenciasTrabajadorAdmin> {
  bool _ocupado = false;

  Future<void> _exportar(bool excel) async {
    if (_ocupado || widget.informe.dias.isEmpty) return;
    final reporte = widget.informe;
    setState(() => _ocupado = true);
    try {
      final bytes = excel ? reporte.generarExcel() : await reporte.generarPdf();
      if (!mounted) return;
      final String? destino;
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
        destino = await FileSaver.instance.saveFile(
          name: reporte.nombreArchivo,
          bytes: bytes,
          fileExtension: excel ? 'xlsx' : 'pdf',
          mimeType: excel ? MimeType.microsoftExcel : MimeType.pdf,
        );
      } else {
        destino = await FileSaver.instance.saveAs(
          name: reporte.nombreArchivo,
          bytes: bytes,
          fileExtension: excel ? 'xlsx' : 'pdf',
          mimeType: excel ? MimeType.microsoftExcel : MimeType.pdf,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Descarga del reporte iniciada. Revisa las descargas de tu navegador.'
                : destino == null || destino.isEmpty
                ? 'Guardado cancelado.'
                : 'Reporte guardado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo completar la exportación. Revisa las descargas antes de reintentar.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = !_ocupado && widget.informe.dias.isNotEmpty;
    final color = habilitado
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    final colorContenido = habilitado ? Colors.white : color;
    return PopupMenuButton<bool>(
      enabled: habilitado,
      tooltip: 'Exportar asistencias mostradas',
      onSelected: _exportar,
      itemBuilder: (_) => const [
        PopupMenuItem(value: true, child: Text('Exportar Excel')),
        PopupMenuItem(value: false, child: Text('Exportar PDF')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: habilitado ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_ocupado)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.download_outlined, color: colorContenido, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _ocupado ? 'Generando reporte…' : 'Exportar',
                style: TextStyle(
                  color: colorContenido,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorContenido),
          ],
        ),
      ),
    );
  }
}
