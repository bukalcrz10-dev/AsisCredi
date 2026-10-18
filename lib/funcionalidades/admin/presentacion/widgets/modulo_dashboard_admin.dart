import 'package:flutter/material.dart';

import '../../../asistencias/datos/fuentes_datos/fuente_datos_asistencias_firestore.dart';
import '../../../asistencias/datos/repositorios/repositorio_asistencias_impl.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import '../../../usuarios/datos/fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../../../usuarios/datos/repositorios/repositorio_usuarios_impl.dart';
import '../../datos/servicios/servicio_dashboard_admin.dart';
import '../modelos/resumen_dashboard_admin.dart';
import 'cuadricula_admin.dart';
import 'indicador_dashboard_admin.dart';

const _tinta = Color(0xFF153B49);
const _teal = Color(0xFF008499);
const _verde = Color(0xFF16805D);
const _ambar = Color(0xFFAB641A);

class ModuloDashboardAdmin extends StatefulWidget {
  const ModuloDashboardAdmin({
    super.key,
    this.cargarDatos,
    this.onAbrirTrabajador,
    this.onAbrirSedes,
  });
  final Future<ResumenDashboardAdmin> Function()? cargarDatos;
  final ValueChanged<String>? onAbrirTrabajador;
  final VoidCallback? onAbrirSedes;

  @override
  State<ModuloDashboardAdmin> createState() => _ModuloDashboardAdminState();
}

enum _Filtro { incompletas, observadas, sinMarcas, configuracion }

class _ModuloDashboardAdminState extends State<ModuloDashboardAdmin> {
  late Future<ResumenDashboardAdmin> _carga;
  _Filtro _filtro = _Filtro.incompletas;
  int _limite = 6;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<ResumenDashboardAdmin> _cargar() async {
    if (widget.cargarDatos != null) return widget.cargarDatos!();
    final ahora = DateTime.now();
    final (usuarios, marcas, documentosSedes) = await (
      RepositorioUsuariosImpl(FuenteDatosUsuariosFirestore()).obtenerUsuarios(),
      cargarMarcacionesDashboard(
        RepositorioAsistenciasImpl(FuenteDatosAsistenciasFirestore()),
        ahora,
      ),
      FuenteDatosSedesFirestore().obtenerSedes(),
    ).wait;
    return ResumenDashboardAdmin(
      actualizadoEn: ahora,
      usuarios: usuarios,
      marcaciones: marcas,
      sedes: documentosSedes
          .map((s) => ModeloSede.desdeMapa(s.value, s.key).aEntidad())
          .toList(),
    );
  }

  void _actualizar() => setState(() {
    _carga = _cargar();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<ResumenDashboardAdmin>(
    future: _carga,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _Tarjeta(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando Dashboard',
              ),
            ),
          ),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Titulo('No se pudo cargar el Dashboard'),
              const SizedBox(height: 8),
              const Text('Comprueba tu conexión y vuelve a intentarlo.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _actualizar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      final datos = snapshot.requireData;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: _Titulo('Indicadores de hoy')),
              IconButton(
                tooltip: 'Actualizar Dashboard',
                onPressed: _actualizar,
                icon: const Icon(Icons.refresh, color: _teal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CuadriculaAdmin(
            maximoColumnas: 4,
            children: [
              IndicadorDashboardAdmin(
                colorAcento: _teal,
                icono: Icons.how_to_reg_outlined,
                titulo: 'Con marcaciones hoy',
                valor: '${datos.conMarcaciones}',
                etiqueta:
                    'Trabajadores activos que ya iniciaron labores y tienen al menos una marca hoy.',
              ),
              IndicadorDashboardAdmin(
                colorAcento: const Color(0xFF537184),
                icono: Icons.person_search_outlined,
                titulo: 'Sin marcaciones hoy',
                valor: datos.esDomingo
                    ? 'No aplica'
                    : '${datos.sinMarcaciones.length}',
                etiqueta:
                    'No equivale a una falta. Excluye altas con inicio de labores futuro. Los domingos no aplica.',
              ),
              IndicadorDashboardAdmin(
                colorAcento: _ambar,
                icono: Icons.pending_actions_outlined,
                titulo: 'Jornadas incompletas',
                valor: '${datos.incompletas.length}',
                etiqueta:
                    'Jornadas de hoy a las que aún les faltan marcaciones. Pueden estar en curso.',
              ),
              IndicadorDashboardAdmin(
                colorAcento: const Color(0xFFC06136),
                icono: Icons.rule_outlined,
                titulo: 'Jornadas observadas',
                valor: '${datos.observadas.length}',
                etiqueta:
                    'Jornadas completas de hoy con incidencias de horario, ubicación o rostro.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, medidas) {
              final revision = _revision(context, datos);
              final sedes = _sedes(context, datos);
              if (medidas.maxWidth < 1080 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [revision, const SizedBox(height: 16), sedes],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: revision),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: sedes),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Titulo(
                  'Últimas jornadas',
                  subtitulo:
                      'Historial reciente · última marcación de cada jornada',
                ),
                const SizedBox(height: 12),
                if (datos.jornadas.isEmpty)
                  const _Vacio(
                    icono: Icons.history_rounded,
                    texto: 'Todavía no hay jornadas registradas.',
                  )
                else
                  for (final jornada in datos.jornadas.take(4))
                    _Fila(
                      nombre: jornada.nombre,
                      detalle:
                          '${_fecha(jornada.ultimaMarca)} · ${_hora(jornada.ultimaMarca)} · ${jornada.sede}',
                      estado: jornada.estado,
                      color: jornada.estado == 'Correcta'
                          ? _verde
                          : jornada.estado == 'Observada'
                          ? _ambar
                          : _teal,
                      onAbrir: jornada.usuarioDisponible
                          ? _abrir(jornada.usuarioId)
                          : null,
                    ),
              ],
            ),
          ),
        ],
      );
    },
  );

  VoidCallback? _abrir(String id) => widget.onAbrirTrabajador == null
      ? null
      : () => widget.onAbrirTrabajador!(id);

  Widget _revision(BuildContext context, ResumenDashboardAdmin datos) {
    final cantidades = <_Filtro, int>{
      _Filtro.incompletas: datos.incompletas.length,
      _Filtro.observadas: datos.observadas.length,
      _Filtro.sinMarcas: datos.sinMarcaciones.length,
      _Filtro.configuracion: datos.configuracion.length,
    };
    final etiquetas = <_Filtro, String>{
      _Filtro.incompletas: 'Incompletas',
      _Filtro.observadas: 'Observadas',
      _Filtro.sinMarcas: 'Sin marcaciones',
      _Filtro.configuracion: 'Configuración',
    };
    final filas = <Widget>[];
    switch (_filtro) {
      case _Filtro.incompletas:
      case _Filtro.observadas:
        for (final j
            in (_filtro == _Filtro.incompletas
                    ? datos.incompletas
                    : datos.observadas)
                .take(_limite)) {
          filas.add(
            _Fila(
              nombre: j.nombre,
              detalle: '${j.sede} · Última marca ${_hora(j.ultimaMarca)}',
              explicacion: _filtro == _Filtro.observadas
                  ? j.evaluacion.incidencias.join(' ')
                  : null,
              color: _ambar,
              onAbrir: j.usuarioDisponible ? _abrir(j.usuarioId) : null,
            ),
          );
        }
      case _Filtro.sinMarcas:
        for (final u in datos.sinMarcaciones.take(_limite)) {
          filas.add(
            _Fila(
              nombre: u.nombreCompleto,
              detalle: u.correo,
              color: _teal,
              onAbrir: _abrir(u.id),
            ),
          );
        }
      case _Filtro.configuracion:
        for (final c in datos.configuracion.take(_limite)) {
          filas.add(
            _Fila(
              nombre: c.usuario.nombreCompleto,
              detalle: c.motivo,
              color: _ambar,
              onAbrir: _abrir(c.usuario.id),
            ),
          );
        }
    }
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titulo(
            'Seguimiento de hoy',
            subtitulo: 'Revisa las marcaciones y los datos del personal',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filtro in _Filtro.values)
                ChoiceChip(
                  label: Text('${etiquetas[filtro]} · ${cantidades[filtro]}'),
                  selected: _filtro == filtro,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _filtro = filtro;
                    _limite = 6;
                  }),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _filtro == filtro ? _teal : const Color(0xFF586E77),
                  ),
                  selectedColor: const Color(0xFFE6F3F5),
                  backgroundColor: const Color(0xFFF7FAFB),
                  side: BorderSide(
                    color: _filtro == filtro
                        ? const Color(0xFF9BCDD5)
                        : const Color(0xFFE0EAEE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (filas.isEmpty)
            _Vacio(
              icono: Icons.task_alt_rounded,
              texto: switch (_filtro) {
                _Filtro.incompletas => 'No hay jornadas incompletas hoy.',
                _Filtro.observadas => 'No hay jornadas observadas hoy.',
                _Filtro.sinMarcas =>
                  datos.esDomingo
                      ? 'Este seguimiento no aplica los domingos.'
                      : 'No hay trabajadores sin marcaciones hoy.',
                _Filtro.configuracion =>
                  'No se detectaron cargos ni sedes por revisar.',
              },
            )
          else
            ...filas,
          if (cantidades[_filtro]! > _limite)
            TextButton(
              onPressed: () => setState(() => _limite += 6),
              child: Text('Mostrar más (${cantidades[_filtro]! - _limite})'),
            ),
          const SizedBox(height: 10),
          Text(switch (_filtro) {
            _Filtro.incompletas =>
              'Una jornada en curso puede tener marcaciones pendientes.',
            _Filtro.observadas =>
              'Las observaciones consideran horario, ubicación y rostro.',
            _Filtro.sinMarcas =>
              'Sin marcaciones no equivale a una falta. Revisa permisos y justificaciones.',
            _Filtro.configuracion =>
              'Se revisan los cargos y las sedes del personal activo.',
          }, style: const TextStyle(fontSize: 12, color: Color(0xFF647E88))),
        ],
      ),
    );
  }

  Widget _sedes(BuildContext context, ResumenDashboardAdmin datos) => _Tarjeta(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _Titulo(
                'Cobertura por sede',
                subtitulo: 'Personal asignado con alguna marcación hoy',
              ),
            ),
            if (widget.onAbrirSedes != null)
              IconButton(
                tooltip: 'Configurar sedes',
                onPressed: widget.onAbrirSedes,
                icon: const Icon(Icons.tune_rounded, color: _teal, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (datos.coberturaSedes.isEmpty)
          const _Vacio(
            icono: Icons.location_off_outlined,
            texto: 'Todavía no hay sedes registradas.',
          )
        else
          for (final sede in datos.coberturaSedes)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: _teal,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          sede.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _tinta,
                          ),
                        ),
                      ),
                      if (!sede.activa)
                        const _Etiqueta(
                          texto: 'Inactiva',
                          color: Color(0xFF647E88),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: sede.asignados == 0
                        ? 0
                        : sede.conMarcaciones / sede.asignados,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(9),
                    color: _teal,
                    backgroundColor: const Color(0xFFEAF1F3),
                    semanticsLabel:
                        '${sede.nombre}: ${sede.conMarcaciones} de ${sede.asignados} trabajadores con marcaciones',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${sede.conMarcaciones} de ${sede.asignados} trabajadores',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF647E88),
                    ),
                  ),
                ],
              ),
            ),
        Text(
          datos.esDomingo
              ? 'Domingo no laborable. No se calcula ausencia.'
              : 'Incluye personal activo que ya inició labores. No mide jornadas completas.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF647E88)),
        ),
      ],
    ),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCBDDE3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10123847),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {this.subtitulo});
  final String texto;
  final String? subtitulo;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        texto,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _tinta,
          letterSpacing: -.2,
        ),
      ),
      if (subtitulo != null) ...[
        const SizedBox(height: 5),
        Text(
          subtitulo!,
          style: const TextStyle(fontSize: 12, color: Color(0xFF647E88)),
        ),
      ],
    ],
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto});
  final IconData icono;
  final String texto;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Column(
      children: [
        Icon(icono, size: 30, color: const Color(0xFF8CA8B1)),
        const SizedBox(height: 10),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF647E88), fontSize: 13),
        ),
      ],
    ),
  );
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.nombre,
    required this.detalle,
    required this.color,
    this.explicacion,
    this.estado,
    this.onAbrir,
  });
  final String nombre, detalle;
  final String? explicacion, estado;
  final Color color;
  final VoidCallback? onAbrir;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFEBF1F3))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.trim().isEmpty ? 'Trabajador sin nombre' : nombre,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _tinta,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                detalle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF647E88)),
              ),
              if (explicacion != null && explicacion!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    explicacion!,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
              if (estado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _Etiqueta(texto: estado!, color: color),
                ),
            ],
          ),
        ),
        if (onAbrir != null)
          IconButton(
            tooltip: 'Abrir ficha de $nombre',
            onPressed: onAbrir,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: _teal,
              size: 19,
            ),
          ),
      ],
    ),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color});
  final String texto;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
