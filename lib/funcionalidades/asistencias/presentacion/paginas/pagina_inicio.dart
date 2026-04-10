import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../datos/repositorios/repositorio_asistencias_impl.dart';
import '../../dominio/casos_de_uso/registrar_asistencia.dart';
import '../../dominio/entidades/asistencia.dart';
import '../../dominio/entidades/tipo_marcacion.dart';
import '../controladores/controlador_asistencia.dart';

// Pantalla principal del trabajador autenticado.
// Toma los datos basicos del usuario de Firebase Auth y los muestra
// junto con las acciones principales de marcacion.
class PaginaInicio extends StatefulWidget {
  const PaginaInicio({
    super.key,
    this.usuarioAutenticado,
    this.onCerrarSesion,
  });

  final User? usuarioAutenticado;
  final Future<void> Function()? onCerrarSesion;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late final ControladorAsistencia _controlador;

  @override
  void initState() {
    super.initState();

    final fuenteDatos = FuenteDatosAsistenciasFirestore();
    final repositorio = RepositorioAsistenciasImpl(fuenteDatos);
    final casoUso = RegistrarAsistencia(repositorio);
    final perfil = PerfilTrabajadorActual.desdeUsuarioAutenticado(
      usuarioId: widget.usuarioAutenticado?.uid ?? 'usuario_demo',
      nombreCompleto: widget.usuarioAutenticado?.displayName,
      correo: widget.usuarioAutenticado?.email,
    );

    _controlador = ControladorAsistencia(
      registrarAsistencia: casoUso,
      perfilActual: perfil,
    );
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        final perfil = _controlador.perfilActual;
        final ultimaMarcacion = _controlador.ultimaMarcacion;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Registro de asistencia'),
            actions: [
              if (widget.onCerrarSesion != null)
                IconButton(
                  tooltip: 'Cerrar sesion',
                  onPressed: widget.onCerrarSesion,
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Bienvenido, ${perfil.nombreCompleto}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ahora la entrada al flujo principal depende de autenticacion. '
                  'La siguiente mejora sera leer el perfil completo desde Firestore.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi informacion',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _FilaInformacion(
                          icono: Icons.person_outline,
                          etiqueta: 'Nombre completo',
                          valor: perfil.nombreCompleto,
                        ),
                        _FilaInformacion(
                          icono: Icons.badge_outlined,
                          etiqueta: 'Rol o cargo',
                          valor: perfil.rolOCargo,
                        ),
                        _FilaInformacion(
                          icono: Icons.location_city_outlined,
                          etiqueta: 'Sede asignada',
                          valor: perfil.nombreSede,
                        ),
                        _FilaInformacion(
                          icono: Icons.email_outlined,
                          etiqueta: 'Correo',
                          valor: perfil.correoNotificacion.isEmpty
                              ? 'Sin correo disponible'
                              : perfil.correoNotificacion,
                        ),
                        _FilaInformacion(
                          icono: Icons.calendar_month_outlined,
                          etiqueta: 'Fecha actual',
                          valor: _formatearFecha(_controlador.fechaHoraActual),
                        ),
                        _FilaInformacion(
                          icono: Icons.access_time_outlined,
                          etiqueta: 'Hora actual',
                          valor: _formatearHora(_controlador.fechaHoraActual),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de validaciones',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        _EstadoValidacion(
                          icono: Icons.my_location_outlined,
                          titulo: 'Estado de ubicacion',
                          estado: _controlador.dentroDeZona
                              ? 'Ubicacion valida'
                              : 'Fuera de zona',
                          color: _controlador.dentroDeZona
                              ? Colors.green
                              : Colors.red,
                          detalle:
                              'Por ahora es un estado simulado. Luego vendra del modulo de geolocalizacion.',
                        ),
                        const SizedBox(height: 12),
                        _EstadoValidacion(
                          icono: Icons.face_outlined,
                          titulo: 'Estado de validacion facial',
                          estado: _controlador.rostroValidado
                              ? 'Rostro validado'
                              : 'Rostro no validado',
                          color: _controlador.rostroValidado
                              ? Colors.green
                              : Colors.red,
                          detalle:
                              'Por ahora es un estado simulado. Luego vendra del modulo de reconocimiento facial.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrar asistencia',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _controlador.guardando
                                    ? null
                                    : () => _controlador.registrarMarcacion(
                                          TipoMarcacion.entrada,
                                        ),
                                icon: const Icon(Icons.login_outlined),
                                label: const Text('Marcar entrada'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _controlador.guardando
                                    ? null
                                    : () => _controlador.registrarMarcacion(
                                          TipoMarcacion.salida,
                                        ),
                                icon: const Icon(Icons.logout_outlined),
                                label: const Text('Marcar salida'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controlador.mensajeEstado ??
                              'Aun no se ha realizado ninguna marcacion.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_controlador.guardando) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ultima marcacion',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (ultimaMarcacion == null)
                          Text(
                            'Todavia no hay marcaciones registradas en esta sesion.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        else
                          _TarjetaMarcacion(
                            asistencia: ultimaMarcacion,
                          ),
                        const SizedBox(height: 16),
                        _FilaInformacion(
                          icono: Icons.login,
                          etiqueta: 'Ultima entrada',
                          valor: _controlador.ultimaEntrada == null
                              ? 'Sin registro'
                              : '${_formatearFecha(_controlador.ultimaEntrada!.fechaHora)} - ${_formatearHora(_controlador.ultimaEntrada!.fechaHora)}',
                        ),
                        _FilaInformacion(
                          icono: Icons.logout,
                          etiqueta: 'Ultima salida',
                          valor: _controlador.ultimaSalida == null
                              ? 'Sin registro'
                              : '${_formatearFecha(_controlador.ultimaSalida!.fechaHora)} - ${_formatearHora(_controlador.ultimaSalida!.fechaHora)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historial reciente',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (_controlador.historialReciente.isEmpty)
                          Text(
                            'Aqui veras las ultimas marcaciones registradas por el trabajador.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        else
                          ..._controlador.historialReciente.map(
                            (asistencia) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TarjetaMarcacion(
                                asistencia: asistencia,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_controlador.ultimoIdRegistrado != null) ...[
                  const SizedBox(height: 20),
                  SelectableText(
                    'Ultimo id registrado en Firebase: ${_controlador.ultimoIdRegistrado}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatearFecha(DateTime fechaHora) {
    final dia = fechaHora.day.toString().padLeft(2, '0');
    final mes = fechaHora.month.toString().padLeft(2, '0');
    final anio = fechaHora.year.toString();
    return '$dia/$mes/$anio';
  }

  String _formatearHora(DateTime fechaHora) {
    final hora = fechaHora.hour.toString().padLeft(2, '0');
    final minuto = fechaHora.minute.toString().padLeft(2, '0');
    final segundo = fechaHora.second.toString().padLeft(2, '0');
    return '$hora:$minuto:$segundo';
  }
}

class _FilaInformacion extends StatelessWidget {
  const _FilaInformacion({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icono, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoValidacion extends StatelessWidget {
  const _EstadoValidacion({
    required this.icono,
    required this.titulo,
    required this.estado,
    required this.color,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String estado;
  final Color color;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  estado,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMarcacion extends StatelessWidget {
  const _TarjetaMarcacion({
    required this.asistencia,
  });

  final Asistencia asistencia;

  @override
  Widget build(BuildContext context) {
    final esEntrada = asistencia.tipoMarcacion == TipoMarcacion.entrada;
    final color = esEntrada ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            esEntrada ? Icons.login_outlined : Icons.logout_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esEntrada ? 'Entrada registrada' : 'Salida registrada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatearFecha(asistencia.fechaHora)} - ${_formatearHora(asistencia.fechaHora)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fechaHora) {
    final dia = fechaHora.day.toString().padLeft(2, '0');
    final mes = fechaHora.month.toString().padLeft(2, '0');
    final anio = fechaHora.year.toString();
    return '$dia/$mes/$anio';
  }

  String _formatearHora(DateTime fechaHora) {
    final hora = fechaHora.hour.toString().padLeft(2, '0');
    final minuto = fechaHora.minute.toString().padLeft(2, '0');
    final segundo = fechaHora.second.toString().padLeft(2, '0');
    return '$hora:$minuto:$segundo';
  }
}
