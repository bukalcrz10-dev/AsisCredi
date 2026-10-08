import 'dart:async';
import 'package:flutter/material.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import '../../../sedes/dominio/entidades/sede.dart';

class DialogoSedesAdmin extends StatefulWidget {
  const DialogoSedesAdmin({super.key, required this.sedes});
  final List<Sede> sedes;
  @override
  State<DialogoSedesAdmin> createState() => _DialogoSedesAdminState();
}

class _DialogoSedesAdminState extends State<DialogoSedesAdmin> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _latitud = TextEditingController();
  final _longitud = TextEditingController();
  final _radio = TextEditingController();
  late final Map<String, String> _opciones;
  late String _id;
  bool _activa = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _opciones = {for (final sede in widget.sedes) sede.id: sede.nombre};
    for (final ciudad in ['Huancayo', 'Satipo']) {
      if (!widget.sedes.any(
        (s) => s.nombre.trim().toLowerCase() == ciudad.toLowerCase(),
      )) {
        _opciones.putIfAbsent('sede_${ciudad.toLowerCase()}', () => ciudad);
      }
    }
    _id = _opciones.keys.first;
    _cargar();
  }

  void _cargar() {
    final sede = widget.sedes.where((s) => s.id == _id).firstOrNull;
    _nombre.text = sede?.nombre ?? _opciones[_id]!;
    _latitud.text = sede?.latitud.toString() ?? '';
    _longitud.text = sede?.longitud.toString() ?? '';
    _radio.text = sede?.radioPermitidoMetros.toString() ?? '';
    _activa = sede?.activa ?? true;
    _error = null;
  }

  @override
  void dispose() {
    for (final campo in [_nombre, _latitud, _longitud, _radio]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final anterior = widget.sedes.where((s) => s.id == _id).firstOrNull;
      final modelo = ModeloSede(
        id: _id,
        nombre: _nombre.text.trim(),
        latitud: double.parse(_latitud.text.trim().replaceAll(',', '.')),
        longitud: double.parse(_longitud.text.trim().replaceAll(',', '.')),
        radioPermitidoMetros: double.parse(
          _radio.text.trim().replaceAll(',', '.'),
        ),
        activa: _activa,
        descripcion: anterior?.descripcion,
      );
      await FuenteDatosSedesFirestore()
          .guardarSede(id: _id, datos: modelo.aMapa())
          .timeout(const Duration(seconds: 20));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error =
              'No se pudo confirmar el guardado. Revisa la conexión, los permisos y la lista de sedes antes de reintentar.';
        });
      }
    }
  }

  Widget _numero(
    TextEditingController controller,
    String titulo,
    double min,
    double max,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_guardando,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(labelText: titulo),
      validator: (texto) => validarNumeroSede(texto, min, max),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_guardando,
    child: AlertDialog(
      title: const Text('Configurar sedes'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usa las coordenadas exactas de la oficina. El radio se expresa en metros.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sede a configurar',
                  ),
                  items: [
                    for (final e in _opciones.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: _guardando
                      ? null
                      : (id) {
                          if (id != null) {
                            setState(() {
                              _id = id;
                              _cargar();
                            });
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombre,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de sede',
                  ),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Ingresa el nombre.'
                      : null,
                ),
                _numero(_latitud, 'Latitud', -90, 90),
                _numero(_longitud, 'Longitud', -180, 180),
                _numero(
                  _radio,
                  'Radio permitido (metros)',
                  0.01,
                  double.infinity,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sede activa'),
                  value: _activa,
                  onChanged: _guardando
                      ? null
                      : (valor) => setState(() => _activa = valor),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_guardando) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar sede'),
        ),
      ],
    ),
  );
}

String? validarNumeroSede(String? texto, double minimo, double maximo) {
  final valor = double.tryParse((texto ?? '').trim().replaceAll(',', '.'));
  if (valor == null || !valor.isFinite || valor < minimo || valor > maximo) {
    return 'Ingresa un valor válido${maximo.isFinite ? ' entre $minimo y $maximo' : ' mayor que cero'}.';
  }
  return null;
}
