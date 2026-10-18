import 'dart:async';
import 'package:flutter/material.dart';
import '../../datos/servicios/servicio_sedes_admin.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import '../../../sedes/dominio/entidades/sede.dart';

class FormularioSedesAdmin extends StatefulWidget {
  const FormularioSedesAdmin({
    super.key,
    required this.sedes,
    required this.onGuardado,
    this.sedeInicialId,
  });
  final List<Sede> sedes;
  final ValueChanged<String> onGuardado;
  final String? sedeInicialId;
  @override
  State<FormularioSedesAdmin> createState() => _FormularioSedesAdminState();
}

class _FormularioSedesAdminState extends State<FormularioSedesAdmin> {
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
    _id = _opciones.containsKey(widget.sedeInicialId)
        ? widget.sedeInicialId!
        : _opciones.keys.first;
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
      await guardarSedeAdministrativa(
        id: _id,
        datos: modelo.aMapa(),
      ).timeout(const Duration(seconds: 20));
      if (mounted) {
        setState(() => _guardando = false);
        widget.onGuardado(_id);
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

  Widget _campo(String etiqueta, Widget control) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        etiqueta,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF123847),
          letterSpacing: 0,
        ),
      ),
      const SizedBox(height: 7),
      control,
    ],
  );

  Widget _numero(
    TextEditingController controller,
    String titulo,
    double min,
    double max,
  ) => _campo(
    titulo,
    TextFormField(
      key: ValueKey(titulo),
      controller: controller,
      enabled: !_guardando,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: titulo == 'Radio permitido (metros)'
            ? 'Ej. 100'
            : 'Grados decimales',
        suffixText: titulo == 'Radio permitido (metros)' ? 'm' : null,
      ),
      validator: (texto) => validarNumeroSede(texto, min, max),
    ),
  );

  Widget _bloque(String titulo, IconData icono, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0EAEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icono,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_guardando,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final escala = (MediaQuery.textScalerOf(context).scale(14) / 14)
                  .clamp(1.0, 2.0);
              final ancho = constraints.maxWidth >= 900 * escala
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: ancho,
                    child: _bloque(
                      'Datos de la sede',
                      Icons.business_outlined,
                      [
                        _campo(
                          'Sede a configurar',
                          DropdownButtonFormField<String>(
                            key: const ValueKey('sede-configurar'),
                            initialValue: _id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              for (final e in _opciones.entries)
                                DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
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
                        ),
                        const SizedBox(height: 16),
                        _campo(
                          'Nombre de sede',
                          TextFormField(
                            key: const ValueKey('nombre-sede'),
                            controller: _nombre,
                            enabled: !_guardando,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Nombre de la oficina',
                            ),
                            validator: (valor) =>
                                valor == null || valor.trim().isEmpty
                                ? 'Ingresa el nombre.'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            title: const Text('Sede activa'),
                            value: _activa,
                            onChanged: _guardando
                                ? null
                                : (valor) => setState(() => _activa = valor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: ancho,
                    child: _bloque(
                      'Ubicación y cobertura',
                      Icons.location_on_outlined,
                      [
                        LayoutBuilder(
                          builder: (context, espacio) {
                            final dosColumnas =
                                espacio.maxWidth >= 440 * escala;
                            final anchoCoordenada = dosColumnas
                                ? (espacio.maxWidth - 16) / 2
                                : espacio.maxWidth;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: anchoCoordenada,
                                  child: _numero(_latitud, 'Latitud', -90, 90),
                                ),
                                SizedBox(
                                  width: anchoCoordenada,
                                  child: _numero(
                                    _longitud,
                                    'Longitud',
                                    -180,
                                    180,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _numero(
                          _radio,
                          'Radio permitido (metros)',
                          0.01,
                          double.infinity,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Usa las coordenadas exactas de la oficina y el radio en metros.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_guardando)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: _guardando ? null : () => setState(_cargar),
                  child: const Text('Restablecer campos'),
                ),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(_guardando ? 'Guardando…' : 'Guardar sede'),
                ),
              ],
            ),
          ),
        ],
      ),
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
