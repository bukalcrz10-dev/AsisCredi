import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../../asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import '../../../asistencias/dominio/entidades/asistencia.dart';
import '../../../asistencias/dominio/entidades/tipo_marcacion.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../../usuarios/dominio/entidades/rol_usuario.dart';
import '../../../usuarios/dominio/entidades/usuario.dart';

class ModuloDashboardAdmin extends StatefulWidget {
  const ModuloDashboardAdmin({super.key});

  @override
  State<ModuloDashboardAdmin> createState() => _ModuloDashboardAdminState();
}

class _ModuloDashboardAdminState extends State<ModuloDashboardAdmin> {
  late final RepositorioAsistenciasImpl _repositorioAsistencias;
  late final RepositorioUsuariosImpl _repositorioUsuarios;
  late Future<_DashboardAdminData> _cargaDashboard;

  @override
  void initState() {
    super.initState();
    _repositorioAsistencias = RepositorioAsistenciasImpl(
      FuenteDatosAsistenciasFirestore(),
    );
    _repositorioUsuarios = RepositorioUsuariosImpl(
      FuenteDatosUsuariosFirestore(),
    );
    _cargaDashboard = _cargarDashboard();
  }

  Future<_DashboardAdminData> _cargarDashboard() async {
    final usuarios = await _repositorioUsuarios.obtenerUsuarios();
    final asistencias = await _repositorioAsistencias.obtenerAsistencias();

    final usuariosPorId = <String, Usuario>{
      for (final usuario in usuarios) usuario.id: usuario,
    };

    final hoy = DateTime.now();
    final grupos = <String, _GrupoDashboardAdmin>{};

    for (final asistencia in asistencias) {
      final fechaClave = _formatearFecha(asistencia.fechaHora);
      final clave = '${asistencia.usuarioId}|$fechaClave';
      final usuario = usuariosPorId[asistencia.usuarioId];

      final grupo = grupos.putIfAbsent(
        clave,
        () => _GrupoDashboardAdmin(
          usuarioId: asistencia.usuarioId,
          fechaTexto: fechaClave,
          fechaOrden: DateTime(
            asistencia.fechaHora.year,
            asistencia.fechaHora.month,
            asistencia.fechaHora.day,
          ),
          trabajador: usuario?.nombreCompleto.trim().isNotEmpty == true
              ? usuario!.nombreCompleto
              : asistencia.nombreUsuario,
          correo: usuario?.correo ?? asistencia.correoNotificacion ?? '',
        ),
      );

      grupo.marcaciones.add(asistencia);
      if (asistencia.tipoMarcacion == TipoMarcacion.entrada) {
        if (grupo.entrada == null ||
            asistencia.fechaHora.isBefore(grupo.entrada!.fechaHora)) {
          grupo.entrada = asistencia;
        }
      } else {
        if (grupo.salida == null ||
            asistencia.fechaHora.isAfter(grupo.salida!.fechaHora)) {
          grupo.salida = asistencia;
        }
      }
    }

    final filas = grupos.values.map((grupo) => grupo.aFila()).toList()
      ..sort((a, b) => b.fechaEvento.compareTo(a.fechaEvento));

    final filasHoy = filas
        .where((fila) => _mismaFecha(fila.fechaOrden, hoy))
        .toList();
    final trabajadoresActivos = usuarios
        .where(
          (usuario) => usuario.activo && usuario.rol == RolUsuario.trabajador,
        )
        .length;

    final actividadReciente = filas.take(4).map(_crearActividad).toList();

    return _DashboardAdminData(
      trabajadoresActivos: trabajadoresActivos,
      asistenciasHoy: filasHoy.length,
      pendientesHoy: filasHoy
          .where((fila) => fila.estado == 'Pendiente')
          .length,
      observadasHoy: filasHoy
          .where((fila) => fila.estado == 'Observada')
          .length,
      actividadReciente: actividadReciente,
    );
  }

  _ActividadDashboard _crearActividad(_FilaDashboardAdmin fila) {
    if (fila.estado == 'Pendiente') {
      return _ActividadDashboard(
        titulo: '${fila.trabajador} mantiene salida pendiente',
        detalle:
            'El registro del dia continua abierto y requiere cierre de jornada.',
        etiqueta: 'Pendiente',
        colorAcento: ColoresPanel.turquesa,
      );
    }

    if (fila.estado == 'Observada') {
      return _ActividadDashboard(
        titulo: '${fila.trabajador} presenta observacion',
        detalle: fila.detalle,
        etiqueta: 'Observada',
        colorAcento: const Color(0xFFB66A18),
      );
    }

    final hora = fila.entrada != '--:--'
        ? fila.entrada
        : _formatearHora(fila.fechaEvento);
    return _ActividadDashboard(
      titulo: '${fila.trabajador} registro entrada',
      detalle: 'Entrada validada a las $hora en la sede principal.',
      etiqueta: hora,
      colorAcento: ColoresPanel.azul,
    );
  }

  void _recargarDashboard() {
    setState(() {
      _cargaDashboard = _cargarDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardAdminData>(
      future: _cargaDashboard,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _TarjetaDashboardAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indicadores principales',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No se pudieron cargar los datos reales del panel administrativo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresSistema.textoSecundario,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresSistema.rojoInstitucionalOscuro,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _recargarDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final datos = snapshot.data ?? const _DashboardAdminData.vacio();

        return _TarjetaDashboardAdmin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indicadores principales',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cifras generales y actividad reciente con datos reales del sistema.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresSistema.textoSecundario,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _IndicadorDashboardAdmin(
                    colorAcento: ColoresPanel.azul,
                    icono: Icons.groups_2_outlined,
                    etiqueta: 'Personal habilitado',
                    titulo: 'Trabajadores activos',
                    valor: '${datos.trabajadoresActivos}',
                  ),
                  _IndicadorDashboardAdmin(
                    colorAcento: ColoresPanel.verde,
                    icono: Icons.fact_check_outlined,
                    etiqueta: 'Registros del dia',
                    titulo: 'Asistencias de hoy',
                    valor: '${datos.asistenciasHoy}',
                  ),
                  _IndicadorDashboardAdmin(
                    colorAcento: const Color(0xFF8A5C2A),
                    icono: Icons.pending_actions_outlined,
                    etiqueta: 'Casos por cerrar',
                    titulo: 'Pendientes',
                    valor: _dosDigitos(datos.pendientesHoy),
                  ),
                  _IndicadorDashboardAdmin(
                    colorAcento: const Color(0xFFB66A18),
                    icono: Icons.warning_amber_outlined,
                    etiqueta: 'Requieren revision',
                    titulo: 'Observadas',
                    valor: _dosDigitos(datos.observadasHoy),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 1,
                color: ColoresSistema.divisor,
              ),
              const SizedBox(height: 20),
              Text(
                'Actividad reciente',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Movimientos recientes para seguimiento rapido del administrador.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresSistema.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              ...datos.actividadReciente.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FilaActividadDashboard(item: item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaDashboardAdmin extends StatelessWidget {
  const _TarjetaDashboardAdmin({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioTarjeta),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: child,
    );
  }
}

class _IndicadorDashboardAdmin extends StatelessWidget {
  const _IndicadorDashboardAdmin({
    required this.colorAcento,
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.valor,
  });

  final Color colorAcento;
  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorAcento.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: colorAcento, size: 20),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: ColoresSistema.fondoChip,
                borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
              ),
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColoresSistema.textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: ColoresSistema.textoTitulo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: ColoresSistema.textoTitulo,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaActividadDashboard extends StatelessWidget {
  const _FilaActividadDashboard({required this.item});

  final _ActividadDashboard item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresSistema.fondoTarjeta,
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 44,
            decoration: BoxDecoration(
              color: item.colorAcento,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColoresSistema.textoTitulo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.detalle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresSistema.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ColoresSistema.fondoChip,
              borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
            ),
            child: Text(
              item.etiqueta,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColoresSistema.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAdminData {
  const _DashboardAdminData({
    required this.trabajadoresActivos,
    required this.asistenciasHoy,
    required this.pendientesHoy,
    required this.observadasHoy,
    required this.actividadReciente,
  });

  const _DashboardAdminData.vacio()
    : trabajadoresActivos = 0,
      asistenciasHoy = 0,
      pendientesHoy = 0,
      observadasHoy = 0,
      actividadReciente = const [];

  final int trabajadoresActivos;
  final int asistenciasHoy;
  final int pendientesHoy;
  final int observadasHoy;
  final List<_ActividadDashboard> actividadReciente;
}

class _ActividadDashboard {
  const _ActividadDashboard({
    required this.titulo,
    required this.detalle,
    required this.etiqueta,
    required this.colorAcento,
  });

  final String titulo;
  final String detalle;
  final String etiqueta;
  final Color colorAcento;
}

class _GrupoDashboardAdmin {
  _GrupoDashboardAdmin({
    required this.usuarioId,
    required this.fechaTexto,
    required this.fechaOrden,
    required this.trabajador,
    required this.correo,
  });

  final String usuarioId;
  final String fechaTexto;
  final DateTime fechaOrden;
  final String trabajador;
  final String correo;
  final List<Asistencia> marcaciones = [];
  Asistencia? entrada;
  Asistencia? salida;

  _FilaDashboardAdmin aFila() {
    final validaciones = marcaciones;
    final todasDentroZona = validaciones.every((item) => item.dentroDeZona);
    final todasConRostro = validaciones.every((item) => item.rostroValidado);
    final completa = entrada != null && salida != null;
    final observaciones = validaciones
        .map((item) => item.observacion)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();

    final estado = !completa
        ? 'Pendiente'
        : (!todasDentroZona || !todasConRostro || observaciones.isNotEmpty)
        ? 'Observada'
        : 'Correcta';

    return _FilaDashboardAdmin(
      usuarioId: usuarioId,
      trabajador: trabajador.trim().isEmpty
          ? 'Trabajador sin nombre'
          : trabajador,
      correo: correo,
      fechaTexto: fechaTexto,
      fechaOrden: fechaOrden,
      entrada: entrada == null ? '--:--' : _formatearHora(entrada!.fechaHora),
      salida: salida == null ? '--:--' : _formatearHora(salida!.fechaHora),
      estado: estado,
      detalle: observaciones.isEmpty
          ? _detallePorEstado(estado)
          : observaciones.join(' | '),
      fechaEvento: salida?.fechaHora ?? entrada?.fechaHora ?? fechaOrden,
    );
  }

  String _detallePorEstado(String estado) {
    switch (estado) {
      case 'Correcta':
        return 'La jornada fue registrada con ubicacion y rostro validados.';
      case 'Observada':
        return 'La marcacion fue registrada con revision administrativa pendiente.';
      case 'Pendiente':
      default:
        return 'El registro del dia continua abierto y requiere cierre de jornada.';
    }
  }
}

class _FilaDashboardAdmin {
  const _FilaDashboardAdmin({
    required this.usuarioId,
    required this.trabajador,
    required this.correo,
    required this.fechaTexto,
    required this.fechaOrden,
    required this.entrada,
    required this.salida,
    required this.estado,
    required this.detalle,
    required this.fechaEvento,
  });

  final String usuarioId;
  final String trabajador;
  final String correo;
  final String fechaTexto;
  final DateTime fechaOrden;
  final String entrada;
  final String salida;
  final String estado;
  final String detalle;
  final DateTime fechaEvento;
}

String _formatearFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String _formatearHora(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}

bool _mismaFecha(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dosDigitos(int valor) => valor.toString().padLeft(2, '0');
