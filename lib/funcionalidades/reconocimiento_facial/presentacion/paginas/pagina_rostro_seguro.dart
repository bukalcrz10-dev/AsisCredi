import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../local/camara.dart';
import '../../local/comparacion.dart';
import '../../seguridad/servicio_seguridad_biometrica.dart';

class PaginaRostroSeguro extends StatefulWidget {
  const PaginaRostroSeguro({
    super.key,
    required this.servicio,
    this.registrarReferencia = false,
  });
  final ServicioSeguridadBiometrica servicio;
  final bool registrarReferencia;
  @override
  State<PaginaRostroSeguro> createState() => _PaginaRostroSeguroState();
}

class _PaginaRostroSeguroState extends State<PaginaRostroSeguro> {
  static const canal = MethodChannel('crediasciende/rostro');
  bool _ocupado = false, _consentimiento = false;
  String? _mensaje;
  String _etapa = 'Preparando captura…';
  @override
  void initState() {
    super.initState();
    canal.setMethodCallHandler((call) async {
      if (mounted && _ocupado && call.method == 'etapa') {
        setState(() => _etapa = call.arguments as String);
      }
    });
    if (!widget.registrarReferencia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _capturar();
      });
    }
  }

  Future<void> _capturar() async {
    if (_ocupado || (widget.registrarReferencia && !_consentimiento)) return;
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    Uint8List? bytes;
    List<double>? vector;
    try {
      if (widget.registrarReferencia) {
        await widget.servicio.permitirCapturaReferencia();
      } else {
        widget.servicio.limpiar();
        await widget.servicio.autorizado();
      }
      if (!mounted) return;
      final foto = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => const CamaraPrueba(titulo: 'Verificación del rostro'),
        ),
      );
      if (!mounted) return;
      if (foto == null) {
        if (!widget.registrarReferencia) Navigator.of(context).pop();
        return;
      }
      bytes = Uint8List.fromList(foto);
      setState(() => _etapa = 'Procesando el rostro…');
      final resultado = await canal
          .invokeMapMethod<String, dynamic>('extraer', {'imagen': bytes})
          .timeout(const Duration(seconds: 45));
      vector = (resultado?['vector'] as List)
          .map((v) => (v as num).toDouble())
          .toList();
      validarVector(vector);
      if (widget.registrarReferencia) {
        final codigo = await widget.servicio.enviarReferencia(vector);
        if (mounted) {
          setState(
            () => _mensaje =
                'Solicitud enviada. Código del celular: $codigo. Muéstralo al administrador para que verifique tu identidad y apruebe tu rostro y celular.',
          );
        }
      } else {
        final ticket = await widget.servicio.compararCaptura(vector);
        if (mounted) Navigator.of(context).pop(ticket);
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se pudo confirmar la operación a tiempo. Revisa la conexión y actualiza el estado antes de repetir. Si el motor facial sigue ocupado, cierra y abre la app.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _mensaje = error is ErrorBiometrico
              ? error.mensaje
              : error is PlatformException
              ? (error.message ?? 'No se pudo procesar el rostro.')
              : 'No se pudo completar la operación. Revisa tu conexión y la autorización del administrador.',
        );
      }
    } finally {
      try {
        bytes?.fillRange(0, bytes.length, 0);
        vector?.fillRange(0, vector.length, 0);
      } finally {
        if (mounted) setState(() => _ocupado = false);
      }
    }
  }

  @override
  void dispose() {
    canal.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_ocupado,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.registrarReferencia ? 'Rostro y celular' : 'Validar rostro',
        ),
      ),
      body: !widget.registrarReferencia && _mensaje == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_etapa, textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.registrarReferencia) ...[
                  const Text(
                    'El administrador debe habilitar el registro. La solicitud vincula tu rostro y esta instalación de la app; requiere aprobación antes de marcar.',
                  ),
                  CheckboxListTile(
                    value: _consentimiento,
                    onChanged: _ocupado
                        ? null
                        : (v) => setState(() => _consentimiento = v ?? false),
                    title: const Text(
                      'Acepto registrar mi rostro para verificar mi asistencia.',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_ocupado) ...[
                  const LinearProgressIndicator(),
                  Text(_etapa),
                ],
                if (_mensaje != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_mensaje!),
                  ),
                FilledButton.icon(
                  onPressed:
                      _ocupado ||
                          (widget.registrarReferencia && !_consentimiento)
                      ? null
                      : _capturar,
                  icon: const Icon(Icons.face),
                  label: Text(
                    widget.registrarReferencia
                        ? 'Solicitar registro de rostro y celular'
                        : 'Reintentar',
                  ),
                ),
                if (widget.registrarReferencia)
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () async {
                            setState(() {
                              _ocupado = true;
                              _etapa = 'Consultando aprobación…';
                            });
                            try {
                              final estado = await widget.servicio
                                  .consultarEstado();
                              if (mounted) {
                                setState(() => _mensaje = estado);
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(
                                  () => _mensaje = e is ErrorBiometrico
                                      ? e.mensaje
                                      : 'No se pudo consultar el estado. Revisa tu conexión.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _ocupado = false);
                            }
                          },
                    child: const Text('Consultar aprobación'),
                  ),
              ],
            ),
    ),
  );
}
