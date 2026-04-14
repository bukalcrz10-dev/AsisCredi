import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Pantalla temporal dedicada a la captura facial.
// Vive aislada del modulo de asistencias para que despues podamos
// mejorar la experiencia de camara sin mezclarla con la pantalla principal.
class PaginaValidacionFacial extends StatefulWidget {
  const PaginaValidacionFacial({super.key});

  @override
  State<PaginaValidacionFacial> createState() => _PaginaValidacionFacialState();
}

class _PaginaValidacionFacialState extends State<PaginaValidacionFacial> {
  CameraController? _cameraController;
  bool _inicializandoCamara = true;
  bool _capturando = false;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async {
    try {
      final camarasDisponibles = await availableCameras();
      if (camarasDisponibles.isEmpty) {
        throw Exception('No hay camaras disponibles en el dispositivo.');
      }

      // Priorizamos la camara frontal porque el flujo esta pensado
      // para que el trabajador valide su propio rostro antes de marcar.
      final camaraSeleccionada = camarasDisponibles.firstWhere(
        (camara) => camara.lensDirection == CameraLensDirection.front,
        orElse: () => camarasDisponibles.first,
      );

      final controlador = CameraController(
        camaraSeleccionada,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controlador.initialize();

      if (!mounted) {
        await controlador.dispose();
        return;
      }

      setState(() {
        _cameraController = controlador;
        _inicializandoCamara = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeError =
            'No se pudo abrir la camara. Revisa permisos o disponibilidad del dispositivo.';
        _inicializandoCamara = false;
      });
    }
  }

  Future<void> _capturarImagen() async {
    final controlador = _cameraController;
    if (controlador == null || !controlador.value.isInitialized) {
      setState(() {
        _mensajeError =
            'La camara aun no esta lista. Intenta nuevamente en unos segundos.';
      });
      return;
    }

    setState(() {
      _capturando = true;
      _mensajeError = null;
    });

    try {
      final imagen = await controlador.takePicture();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(imagen.path);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _mensajeError =
            'No se pudo capturar la foto facial. Intenta nuevamente.';
        _capturando = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _cameraController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validacion facial'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Centra tu rostro y toma una foto antes de registrar la asistencia.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: Colors.black,
                    child: _inicializandoCamara
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : controlador != null && controlador.value.isInitialized
                            ? CameraPreview(controlador)
                            : Center(
                                child: Text(
                                  _mensajeError ??
                                      'No fue posible inicializar la vista de camara.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_mensajeError != null) ...[
                Text(
                  _mensajeError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _inicializandoCamara || _capturando
                    ? null
                    : _capturarImagen,
                icon: _capturando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _capturando ? 'Capturando rostro...' : 'Tomar foto facial',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _capturando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
