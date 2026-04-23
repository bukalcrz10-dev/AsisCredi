import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';
import 'soporte_panel_trabajador.dart';

class HojaProcesoMarcacion extends StatelessWidget {
  const HojaProcesoMarcacion({
    super.key,
    required this.controlador,
    required this.tipoMarcacion,
    required this.onValidarRostro,
  });

  final ControladorAsistencia controlador;
  final TipoMarcacion tipoMarcacion;
  final Future<void> Function() onValidarRostro;

  @override
  Widget build(BuildContext context) {
    final esEntrada = tipoMarcacion == TipoMarcacion.entrada;
    final color = esEntrada ? Colors.green : Colors.orange;
    final titulo = esEntrada ? 'Registrar entrada' : 'Registrar salida';

    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) {
        final resultadoUbicacion = controlador.resultadoUbicacion;
        final gpsApagado = resultadoUbicacion?.servicioHabilitado == false;
        final puedeConfirmar = controlador.tienePerfilCargado &&
            !controlador.guardando &&
            !controlador.validandoUbicacion &&
            !controlador.validandoRostro &&
            controlador.dentroDeZona &&
            controlador.rostroValidado;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            foregroundColor: color,
                            child: Icon(esEntrada ? Icons.login : Icons.logout),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  formatearFechaHoraPanel(
                                    controlador.fechaHoraActual,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EtiquetaPanelTrabajador(
                        titulo: 'Ubicacion',
                        contenido: resultadoUbicacion?.mensajeEstado ??
                            'Todavia no se consulto la ubicacion.',
                        accion: SizedBox(
                          height: 52,
                          width: 52,
                          child: FilledButton.tonal(
                            onPressed: controlador.validandoUbicacion
                                ? null
                                : () async {
                                    if (gpsApagado) {
                                      await Geolocator.openLocationSettings();
                                    } else {
                                      await controlador.validarUbicacion();
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: controlador.validandoUbicacion
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    gpsApagado
                                        ? Icons.settings_outlined
                                        : Icons.refresh,
                                  ),
                          ),
                        ),
                      ),
                      if (resultadoUbicacion != null &&
                          (!resultadoUbicacion.servicioHabilitado ||
                              !resultadoUbicacion.permisoConcedido ||
                              !resultadoUbicacion.dentroDeZona)) ...[
                        const SizedBox(height: 8),
                        TarjetaMensajePanel(
                          mensaje: resultadoUbicacion.mensajeEstado,
                          color: Colors.red,
                          icono: Icons.location_off_outlined,
                        ),
                      ],
                      const SizedBox(height: 12),
                      EtiquetaPanelTrabajador(
                        titulo: 'Consideracion',
                        contenido: controlador.dentroDeZona
                            ? 'La ubicacion esta dentro del radio permitido.'
                            : 'La ubicacion aun no cumple la validacion requerida.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed:
                            controlador.validandoRostro ? null : onValidarRostro,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Validar rostro'),
                      ),
                      const SizedBox(height: 12),
                      if (controlador.resultadoFacial != null &&
                          !controlador.rostroValidado)
                        TarjetaMensajePanel(
                          mensaje: controlador.resultadoFacial!.mensajeEstado,
                          color: Colors.orange,
                          icono: Icons.face_retouching_off_outlined,
                        )
                      else if (controlador.rostroValidado &&
                          controlador.resultadoFacial?.rutaImagenCapturada != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evidencia facial lista',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'La foto ya fue capturada y esta preparada para la siguiente marcacion.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      else if (controlador.resultadoFacial == null)
                        const TarjetaMensajePanel(
                          mensaje:
                              'Aun no hay una evidencia facial capturada para esta accion.',
                          color: Colors.orange,
                          icono: Icons.camera_alt_outlined,
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: puedeConfirmar
                              ? () async {
                                  await controlador.registrarMarcacion(
                                    tipoMarcacion,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                          icon: Icon(esEntrada ? Icons.login : Icons.logout),
                          label: Text(titulo),
                        ),
                      ),
                      if (controlador.mensajeEstado != null &&
                          !puedeConfirmar &&
                          !mensajePerteneceABloquePanel(
                            controlador.mensajeEstado!,
                            'ubicacion',
                          ) &&
                          !mensajePerteneceABloquePanel(
                            controlador.mensajeEstado!,
                            'rostro',
                          )) ...[
                        const SizedBox(height: 8),
                        TarjetaMensajePanel(
                          mensaje: controlador.mensajeEstado!,
                          color: colorMensajePanel(controlador.mensajeEstado!),
                          icono: iconoMensajePanel(controlador.mensajeEstado!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
