import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../reconocimiento_facial/seguridad/servicio_biometria_admin.dart';
import 'panel_biometria_admin.dart';

class DialogoBiometriaAdmin extends StatefulWidget {
  const DialogoBiometriaAdmin({
    super.key,
    required this.uid,
    required this.nombre,
    this.integrado = false,
  });
  final String uid, nombre;
  final bool integrado;
  @override
  State<DialogoBiometriaAdmin> createState() => _DialogoBiometriaAdminState();
}

class _DialogoBiometriaAdminState extends State<DialogoBiometriaAdmin> {
  final _servicio = ServicioBiometriaAdmin();
  bool _ocupado = false;
  String? _solicitudVerificada;
  String? _mensaje;
  late Future<List<Object?>> _datos;
  @override
  void initState() {
    super.initState();
    _datos = _cargar();
  }

  Future<List<Object?>> _cargar() => Future.wait([
    _servicio.db
        .collection('configuracionBiometrica')
        .doc(widget.uid)
        .get(const GetOptions(source: Source.server)),
    _servicio.db
        .collection('credencialesBiometricas')
        .where('usuarioId', isEqualTo: widget.uid)
        .get(const GetOptions(source: Source.server)),
  ]).timeout(const Duration(seconds: 20));
  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() {
      _ocupado = true;
      _mensaje = null;
    });
    try {
      await accion().timeout(const Duration(seconds: 30));
      if (mounted) {
        setState(() {
          _datos = _cargar();
          _mensaje = 'Cambio confirmado.';
          _solicitudVerificada = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _mensaje =
              'No se confirmó el cambio. Actualiza antes de repetir; revisa permisos y conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenido = SizedBox(
      width: widget.integrado ? double.infinity : 560,
      child: FutureBuilder<List<Object?>>(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No se pudo consultar la configuración biométrica. Revisa las reglas publicadas y tu conexión.',
                ),
                if (widget.integrado) ...[
                  const SizedBox(height: 12),
                  _botonActualizar(),
                ],
              ],
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final cfg =
              (snapshot.data![0] as DocumentSnapshot<Map<String, dynamic>>)
                  .data() ??
              {};
          final solicitudes =
              (snapshot.data![1] as QuerySnapshot<Map<String, dynamic>>).docs
                  .where((d) => d.data()['version'] == cfg['version'])
                  .toList();
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.integrado) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: _botonActualizar(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_mensaje != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_mensaje!),
                  ),
                if (_ocupado) const LinearProgressIndicator(),
                SeccionesBiometriaAdmin(
                  registroActivo: cfg['estado'] == 'activo',
                  registro: EstadoBiometriaAdmin(
                    estado: cfg['estado'] as String? ?? '',
                    registroHabilitado: cfg['permitirEnrolamiento'] == true,
                    solicitudPendiente: solicitudes.any(
                      (d) => d.data()['estado'] == 'pendiente',
                    ),
                    accion:
                        cfg['estado'] != 'activo' &&
                            cfg['permitirEnrolamiento'] != true
                        ? FilledButton.icon(
                            onPressed: _ocupado
                                ? null
                                : () => _ejecutar(
                                    () => _servicio.habilitar(widget.uid),
                                  ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Permitir registro'),
                          )
                        : null,
                  ),
                  dispositivos: [
                    for (final doc in solicitudes)
                      TarjetaDispositivoBiometriaAdmin(
                        modelo:
                            doc.data()['modeloCelular']?.toString() ??
                            'Celular sin identificar',
                        codigo:
                            doc.data()['codigo']?.toString() ?? 'Sin código',
                        estado:
                            doc.data()['estado']?.toString() ?? 'Sin estado',
                        aprobacion: doc.data()['estado'] == 'pendiente'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _solicitudVerificada == doc.id,
                                    onChanged: _ocupado
                                        ? null
                                        : (v) => setState(
                                            () => _solicitudVerificada =
                                                v == true ? doc.id : null,
                                          ),
                                    title: const Text(
                                      'Verifiqué la identidad y el código con el trabajador presente.',
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed:
                                        _ocupado ||
                                            _solicitudVerificada != doc.id
                                        ? null
                                        : () => _ejecutar(
                                            () => _servicio.aprobar(
                                              widget.uid,
                                              doc.id,
                                            ),
                                          ),
                                    child: const Text(
                                      'Aprobar este rostro y celular',
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                ),
                if (cfg.isNotEmpty && cfg['estado'] != 'revocado') ...[
                  const SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Text(
                        'Cambiar o retirar el registro',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.phonelink_erase_outlined,
                          size: 18,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFAC3B39),
                        ),
                        onPressed: _ocupado
                            ? null
                            : () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Retirar autorización'),
                                    content: const Text(
                                      'Se eliminará la referencia facial y se bloquearán nuevas marcaciones desde el celular. Para registrar otro, habilita un nuevo registro. Las asistencias guardadas se conservan.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text(
                                          'Retirar y eliminar referencia',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmar == true) {
                                  await _ejecutar(
                                    () =>
                                        _servicio.revocarYEliminar(widget.uid),
                                  );
                                }
                              },
                        label: const Text('Retirar autorización'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
    final acciones = <Widget>[
      _botonActualizar(),
      if (!widget.integrado)
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
    ];
    if (widget.integrado) {
      return contenido;
    }
    return AlertDialog(
      title: Text('Rostro y celular · ${widget.nombre}'),
      content: contenido,
      actions: acciones,
    );
  }

  Widget _botonActualizar() => OutlinedButton.icon(
    onPressed: _ocupado
        ? null
        : () => setState(() {
            _solicitudVerificada = null;
            _datos = _cargar();
          }),
    icon: const Icon(Icons.refresh, size: 18),
    label: const Text('Actualizar'),
  );
}
