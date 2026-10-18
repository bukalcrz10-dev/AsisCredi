import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../modelos/trabajador_admin.dart';
import 'contenedor_modulo_admin.dart';

class ListadoTrabajadoresAdmin extends StatefulWidget {
  const ListadoTrabajadoresAdmin({
    super.key,
    required this.trabajadores,
    required this.cargando,
    required this.onActualizar,
    required this.onSeleccionar,
    this.error,
  });
  final List<TrabajadorAdmin> trabajadores;
  final bool cargando;
  final String? error;
  final VoidCallback? onActualizar;
  final ValueChanged<TrabajadorAdmin> onSeleccionar;

  @override
  State<ListadoTrabajadoresAdmin> createState() =>
      _ListadoTrabajadoresAdminState();
}

class _ListadoTrabajadoresAdminState extends State<ListadoTrabajadoresAdmin> {
  final _scrollHorizontal = ScrollController();
  final _busqueda = TextEditingController();
  String _estado = 'vigentes';
  int _cantidad = 25, _pagina = 0;
  bool _ascendente = true;

  @override
  void dispose() {
    _scrollHorizontal.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.text.trim().toLowerCase();
    final filtrados =
        widget.trabajadores.where((t) {
          if (_estado == 'vigentes' && !t.estadoActivo) return false;
          if (_estado == 'inactivos' && t.estadoActivo) return false;
          return [
            t.nombreCompleto,
            t.correo,
            t.telefono,
            t.area,
            t.cargo,
            t.sede,
            t.rol,
            t.id,
          ].any((valor) => valor.toLowerCase().contains(consulta));
        }).toList()..sort(
          (a, b) => _ascendente
              ? a.nombreCompleto.toLowerCase().compareTo(
                  b.nombreCompleto.toLowerCase(),
                )
              : b.nombreCompleto.toLowerCase().compareTo(
                  a.nombreCompleto.toLowerCase(),
                ),
        );
    final paginas = math.max(1, (filtrados.length / _cantidad).ceil());
    final pagina = math.min(_pagina, paginas - 1);
    final inicio = pagina * _cantidad;
    final fin = math.min(inicio + _cantidad, filtrados.length);
    final escala = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      2.0,
    );

    Widget celda(String valor, double ancho) => SizedBox(
      width: ancho,
      child: Tooltip(
        message: valor,
        child: Text(
          valor.isEmpty ? 'Sin asignar' : valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    Widget encabezado(String texto) => Flexible(
      child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    return ContenedorModuloAdmin(
      titulo: 'Listado de trabajadores',
      descripcion:
          'Selecciona un trabajador para consultar su ficha y sus asistencias.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: math.min(145 * escala, constraints.maxWidth),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _cantidad,
                    decoration: const InputDecoration(
                      labelText: 'Mostrar registros',
                    ),
                    items: [
                      for (final n in [10, 25, 50])
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() {
                          _cantidad = valor;
                          _pagina = 0;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: math.min(165 * escala, constraints.maxWidth),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(
                        value: 'vigentes',
                        child: Text('Vigentes'),
                      ),
                      DropdownMenuItem(
                        value: 'inactivos',
                        child: Text('Inactivos'),
                      ),
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() {
                          _estado = valor;
                          _pagina = 0;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: math.min(420 * escala, constraints.maxWidth),
                  child: TextField(
                    controller: _busqueda,
                    decoration: const InputDecoration(
                      labelText: 'Buscar trabajador',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() => _pagina = 0),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar trabajadores',
                  onPressed: widget.onActualizar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.error != null) ...[
            Text(
              widget.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.cargando) const LinearProgressIndicator(),
          if (!widget.cargando && filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay trabajadores que coincidan con la búsqueda y el estado seleccionado.',
              ),
            ),
          if (filtrados.isNotEmpty)
            Scrollbar(
              controller: _scrollHorizontal,
              thumbVisibility: true,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final anchoTabla = math.max(
                    constraints.maxWidth,
                    1000 * escala,
                  );
                  // Reparte el espacio en las celdas, evitando que la tabla
                  // crezca solo por la separación entre columnas.
                  final anchoCeldas = anchoTabla - 106;
                  return SingleChildScrollView(
                    controller: _scrollHorizontal,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: anchoTabla,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDCE7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        horizontalMargin: 12,
                        columnSpacing: 20,
                        headingRowHeight: 44 * escala,
                        dataRowMinHeight: 56 * escala,
                        dataRowMaxHeight: 56 * escala,
                        headingTextStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF45616B),
                            ),
                        sortColumnIndex: 0,
                        sortAscending: _ascendente,
                        headingRowColor: const WidgetStatePropertyAll(
                          Color(0xFFF0F5F7),
                        ),
                        columns: [
                          DataColumn(
                            label: encabezado('Nombre'),
                            onSort: (_, ascendente) => setState(() {
                              _ascendente = ascendente;
                              _pagina = 0;
                            }),
                          ),
                          DataColumn(label: encabezado('Correo institucional')),
                          DataColumn(label: encabezado('Cargo')),
                          DataColumn(label: encabezado('Sede')),
                          DataColumn(label: encabezado('Estado')),
                        ],
                        rows: [
                          for (var i = inicio; i < fin; i++)
                            DataRow(
                              key: ValueKey(filtrados[i].id),
                              color: WidgetStateProperty.resolveWith(
                                (estados) =>
                                    estados.contains(WidgetState.hovered)
                                    ? const Color(0xFFE5F3F4)
                                    : i.isOdd
                                    ? const Color(0xFFF8FAFB)
                                    : Colors.white,
                              ),
                              onSelectChanged: (_) =>
                                  widget.onSeleccionar(filtrados[i]),
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: anchoCeldas * .25,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () =>
                                          widget.onSeleccionar(filtrados[i]),
                                      child: Text(
                                        filtrados[i].nombreCompleto,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  celda(filtrados[i].correo, anchoCeldas * .30),
                                ),
                                DataCell(
                                  celda(filtrados[i].cargo, anchoCeldas * .21),
                                ),
                                DataCell(
                                  celda(filtrados[i].sede, anchoCeldas * .14),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoCeldas * .10,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _EstadoTrabajador(
                                        activo: filtrados[i].estadoActivo,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Mostrando ${filtrados.isEmpty ? 0 : inicio + 1} al $fin de ${filtrados.length} registros · ${widget.trabajadores.length} cuentas registradas',
              ),
              OutlinedButton(
                onPressed: pagina > 0
                    ? () => setState(() => _pagina = pagina - 1)
                    : null,
                child: const Text('Anterior'),
              ),
              Text('Página ${pagina + 1} de $paginas'),
              OutlinedButton(
                onPressed: pagina + 1 < paginas
                    ? () => setState(() => _pagina = pagina + 1)
                    : null,
                child: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoTrabajador extends StatelessWidget {
  const _EstadoTrabajador({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: activo ? const Color(0xFFE7F4ED) : const Color(0xFFEDF0F2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      activo ? 'Vigente' : 'Inactivo',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: activo ? const Color(0xFF23734E) : const Color(0xFF596773),
      ),
    ),
  );
}
