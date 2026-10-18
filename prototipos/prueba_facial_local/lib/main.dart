import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camara.dart';
import 'comparacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final nombre in [
      'face_detection_yunet',
      'face_recognition_sface',
      'opencv',
    ]) {
      yield LicenseEntryWithLineBreaks([
        nombre,
      ], await rootBundle.loadString('licencias/$nombre.txt'));
    }
  });
  runApp(const PruebaFacialApp());
}

class PruebaFacialApp extends StatelessWidget {
  const PruebaFacialApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Prueba facial local',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF007F8B),
      useMaterial3: true,
    ),
    home: const PruebaFacial(),
  );
}

class PruebaFacial extends StatefulWidget {
  const PruebaFacial({super.key});
  @override
  State<PruebaFacial> createState() => _PruebaFacialState();
}

class _PruebaFacialState extends State<PruebaFacial> {
  static const canal = MethodChannel('crediasciende/prueba_facial');
  List<double>? _referencia;
  bool _ocupado = false;
  bool _consentimiento = false;
  String? _mensaje;
  ResultadoComparacion? _resultado;
  int? _milisegundos;
  String _etapa = 'Procesando en el celular…';
  bool _procesando = false;
  Timer? _contador;
  int _segundos = 0;

  @override
  void initState() {
    super.initState();
    canal.setMethodCallHandler((call) async {
      if (call.method == 'etapa' && mounted && _procesando) {
        setState(() => _etapa = call.arguments as String);
      }
    });
  }

  Future<void> _capturar({required bool referencia}) async {
    if (_ocupado || !_consentimiento) return;
    setState(() {
      _ocupado = true;
      _mensaje = null;
      _resultado = null;
    });
    Uint8List? bytes;
    try {
      final captura = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => CamaraPrueba(
            titulo: referencia ? 'Foto de referencia' : 'Foto para comparar',
          ),
        ),
      );
      if (captura == null || !mounted) return;
      // El canal de Android puede devolver bytes de solo lectura.
      // Limpiar únicamente una copia de nuestra propiedad.
      bytes = Uint8List.fromList(captura);
      setState(() {
        _procesando = true;
        _segundos = 0;
        _etapa = 'Preparando el reconocimiento…';
      });
      _contador = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _procesando) setState(() => _segundos++);
      });
      final datos = await canal
          .invokeMapMethod<String, dynamic>('extraer', {'imagen': bytes})
          .timeout(const Duration(seconds: 45));
      if (datos == null) throw const FormatException('Sin resultado');
      final vector = (datos['vector'] as List)
          .map((v) => (v as num).toDouble())
          .toList();
      validarVector(vector);
      if (!mounted) return;
      setState(() {
        _milisegundos = datos['milisegundos'] as int;
        if (referencia) {
          _borrarReferencia();
          _referencia = vector;
          _mensaje =
              'Referencia lista. Toma otra foto de la misma persona; después prueba con otra persona que acepte participar.';
        } else {
          _resultado = comparar(_referencia!, vector);
          vector.fillRange(0, vector.length, 0);
        }
      });
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _mensaje =
              'El procesamiento superó 45 segundos. No se completó esta captura. '
              'Cierra completamente la app y vuelve a abrirla. '
              'Último paso: $_etapa',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _mensaje = error.message ?? 'No se pudo procesar la cara.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se pudo completar la prueba. Vuelve a tomar la foto.',
        );
      }
    } finally {
      _contador?.cancel();
      _contador = null;
      _procesando = false;
      try {
        bytes?.fillRange(0, bytes.length, 0);
      } finally {
        if (mounted) setState(() => _ocupado = false);
      }
    }
  }

  void _borrarReferencia() {
    _referencia?.fillRange(0, _referencia!.length, 0);
    _referencia = null;
  }

  @override
  void dispose() {
    _contador?.cancel();
    canal.setMethodCallHandler(null);
    _borrarReferencia();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prueba facial · 0.3.6'),
      actions: [
        IconButton(
          tooltip: 'Licencias',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Prueba facial local',
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_procesando)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text('Procesando: $_segundos s / máximo 45 s'),
                    Text(_etapa),
                  ],
                ),
              ),
            ),
          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_mensaje!),
            ),
          const Text(
            'CREDIASCIENDE · SOLO PRUEBA',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Compara dos capturas en este celular. Funciona en modo avión; no usa Firebase ni registra asistencia.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Pide dos parpadeos antes de comparar. Es una prueba experimental; no garantiza bloquear fotografías manipuladas o videos. Un resultado favorable no autoriza una asistencia.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Acepto participar en esta prueba con mi rostro.',
            ),
            subtitle: const Text(
              'Las capturas y la referencia se procesan en memoria, sin guardar fotos. Puedes borrar la referencia en cualquier momento.',
            ),
            value: _consentimiento,
            onChanged: _ocupado
                ? null
                : (valor) => setState(() {
                    _consentimiento = valor ?? false;
                    if (!_consentimiento) {
                      _borrarReferencia();
                      _resultado = null;
                      _mensaje = null;
                    }
                  }),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: !_consentimiento || _ocupado
                ? null
                : () => _capturar(referencia: true),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
              _referencia == null
                  ? '1. Tomar referencia'
                  : 'Reemplazar referencia',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: !_consentimiento || _ocupado || _referencia == null
                ? null
                : () => _capturar(referencia: false),
            icon: const Icon(Icons.compare),
            label: const Text('2. Tomar foto y comparar'),
          ),
          TextButton(
            onPressed: _ocupado || _referencia == null
                ? null
                : () => setState(() {
                    _borrarReferencia();
                    _resultado = null;
                    _milisegundos = null;
                    _mensaje = 'Referencia borrada.';
                  }),
            child: const Text('Borrar referencia'),
          ),
          if (_resultado != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resultado!.coincide
                          ? 'Coincidencia según el umbral de prueba'
                          : 'No alcanza el umbral de prueba',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Similitud: ${_resultado!.similitud.toStringAsFixed(3)} · Umbral: $umbralPrueba',
                    ),
                    const Text(
                      'Este valor no es un porcentaje de certeza. El umbral es provisional y debe evaluarse con capturas reales.',
                    ),
                  ],
                ),
              ),
            ),
          if (_milisegundos != null) Text('Procesamiento: $_milisegundos ms'),
          const SizedBox(height: 20),
          const Text(
            'Prueba con luz frontal, sin filtros y una sola cara. Realiza varias capturas de la misma persona y de personas diferentes que acepten participar. Anota aciertos, errores y tiempo.',
          ),
        ],
      ),
    ),
  );
}
