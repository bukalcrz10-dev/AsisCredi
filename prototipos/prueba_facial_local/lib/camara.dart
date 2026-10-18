import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'parpadeos.dart';
import 'formato_camara.dart';

class CamaraPrueba extends StatefulWidget {
  const CamaraPrueba({super.key, required this.titulo});
  final String titulo;
  @override
  State<CamaraPrueba> createState() => _CamaraPruebaState();
}

class _CamaraPruebaState extends State<CamaraPrueba>
    with WidgetsBindingObserver {
  static const _canal = MethodChannel('crediasciende/prueba_facial');
  CameraController? _camara;
  PruebaParpadeos? _prueba;
  final _reloj = Stopwatch();
  Timer? _timer;
  bool _analizando = false, _saliendo = false;
  int _generacion = 0, _intento = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _abrir();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _prueba != null && !_saliendo) {
        setState(() => _prueba!.comprobarTiempo(_reloj.elapsedMilliseconds));
      }
    });
  }

  Future<void> _abrir() async {
    final generacion = ++_generacion;
    CameraController? nueva;
    try {
      final camaras = await availableCameras();
      if (!mounted || generacion != _generacion) return;
      final frontal = camaras.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (frontal.isEmpty) throw StateError('Sin cámara frontal');
      nueva = CameraController(
        frontal.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await nueva.initialize();
      if (!mounted || generacion != _generacion) {
        await nueva.dispose();
        return;
      }
      setState(() {
        _camara = nueva;
        _error = null;
      });
      await nueva.startImageStream(_fotograma);
      if (mounted && generacion == _generacion) _iniciar();
    } catch (_) {
      await nueva?.dispose();
      if (mounted && generacion == _generacion) {
        setState(() {
          _camara = null;
          _error =
              'No se pudo abrir la cámara frontal. Revisa el permiso de cámara.';
        });
      }
    }
  }

  void _iniciar() {
    _intento++;
    _reloj
      ..reset()
      ..start();

    setState(() {
      _prueba = PruebaParpadeos();
      _error = null;
    });
  }

  Future<void> _fotograma(CameraImage imagen) async {
    final camara = _camara;
    final prueba = _prueba;
    if (!mounted ||
        _saliendo ||
        _analizando ||
        camara == null ||
        prueba == null ||
        prueba.error != null ||
        prueba.completada) {
      return;
    }
    final ms = _reloj.elapsedMilliseconds;

    _analizando = true;
    final intento = _intento;
    try {
      final Uint8List nv21;
      if (imagen.planes.length == 3 &&
          imagen.format.group == ImageFormatGroup.yuv420) {
        nv21 = convertirYuv420(imagen.width, imagen.height, [
          for (final plano in imagen.planes)
            PlanoYuv(plano.bytes, plano.bytesPerRow, plano.bytesPerPixel ?? 1),
        ]);
      } else if (imagen.planes.length == 1 &&
          imagen.format.group == ImageFormatGroup.nv21 &&
          imagen.planes.single.bytes.length ==
              imagen.width * imagen.height * 3 ~/ 2) {
        nv21 = imagen.planes.single.bytes;
      } else {
        throw FormatException(
          'Formato no admitido: ${imagen.format.group.name}, '
          '${imagen.planes.length} planos, ${imagen.width}×${imagen.height}.',
        );
      }
      final grados = switch (camara.value.deviceOrientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeLeft => 90,
        DeviceOrientation.portraitDown => 180,
        DeviceOrientation.landscapeRight => 270,
      };
      final datos = await _canal
          .invokeMapMethod<String, dynamic>('parpadeos', {
            'imagen': nv21,
            'ancho': imagen.width,
            'alto': imagen.height,
            'rotacion': (camara.description.sensorOrientation + grados) % 360,
            'foto': prueba.esperandoCaptura,
          })
          .timeout(const Duration(seconds: 3));
      if (!mounted || intento != _intento || _saliendo) return;
      if (datos == null || _reloj.elapsedMilliseconds - ms > 1500) {
        prueba.fallar('La imagen llegó tarde. Repite con buena luz.');
      } else {
        prueba.recibir(datos, ms);
        final recibida = datos['imagen'];
        final foto = recibida is Uint8List
            ? Uint8List.fromList(recibida)
            : null;
        if (prueba.completada) {
          if (foto is! Uint8List || foto.isEmpty) {
            throw const FormatException('Sin captura final');
          }
          _saliendo = true;
          await camara.stopImageStream();
          if (mounted && intento == _intento) {
            Navigator.of(context).pop(foto);
          } else {
            foto.fillRange(0, foto.length, 0);
          }
          return;
        }
        if (foto is Uint8List) foto.fillRange(0, foto.length, 0);
      }
      setState(() {});
    } catch (error) {
      if (mounted && intento == _intento) {
        setState(() {
          _saliendo = false;
          prueba.fallar(
            error is PlatformException
                ? (error.message ?? 'Error del detector: ${error.code}')
                : error is FormatException
                ? error.message
                : 'No se pudo completar la prueba. Intenta nuevamente.',
          );
        });
      }
    } finally {
      _analizando = false;
      if (mounted && !_saliendo) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _generacion++;
      _intento++;
      _saliendo = false;
      _prueba?.fallar('La prueba se interrumpió. Vuelve a iniciarla.');
      final anterior = _camara;
      _camara = null;
      anterior?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _camara == null) {
      _abrir();
    }
  }

  @override
  void dispose() {
    _generacion++;
    _intento++;
    _timer?.cancel();
    _reloj.stop();
    WidgetsBinding.instance.removeObserver(this);
    _camara?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.titulo)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _prueba?.error ??
                  (_prueba == null
                      ? 'Mira de frente con buena luz. Pulsa Iniciar.'
                      : _prueba!.instruccion),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Parpadeos: ${_prueba?.cantidad ?? 0}/2',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _prueba?.lectura ?? 'Preparando cámara',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: _camara != null
                    ? CameraPreview(_camara!)
                    : _error != null
                    ? Text(_error!)
                    : const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  _camara == null ||
                      _analizando ||
                      _saliendo ||
                      (_prueba != null && _prueba!.error == null)
                  ? null
                  : _iniciar,
              icon: const Icon(Icons.visibility),
              label: Text(_prueba == null ? 'Iniciar' : 'Reintentar'),
            ),
            TextButton(
              onPressed: _saliendo ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}
