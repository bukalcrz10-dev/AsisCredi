import 'package:flutter/material.dart';
import '../../../sedes/datos/fuentes_datos/fuente_datos_sedes_firestore.dart';
import '../../../sedes/datos/modelos/modelo_sede.dart';
import '../../../sedes/dominio/entidades/sede.dart';
import 'contenedor_modulo_admin.dart';
import 'formulario_sedes_admin.dart';

class ModuloSedesAdmin extends StatefulWidget {
  const ModuloSedesAdmin({super.key});

  @override
  State<ModuloSedesAdmin> createState() => _ModuloSedesAdminState();
}

class _ModuloSedesAdminState extends State<ModuloSedesAdmin> {
  late Future<List<Sede>> _carga;
  String? _sedeSeleccionada;

  @override
  void initState() {
    super.initState();
    _carga = _leerSedes();
  }

  Future<List<Sede>> _leerSedes() async {
    final documentos = await FuenteDatosSedesFirestore().obtenerSedes().timeout(
      const Duration(seconds: 20),
    );
    return documentos
        .map((e) => ModeloSede.desdeMapa(e.value, e.key).aEntidad())
        .toList();
  }

  void _actualizar() => setState(() => _carga = _leerSedes());

  @override
  Widget build(BuildContext context) => ContenedorModuloAdmin(
    titulo: 'Configuración de sedes',
    descripcion:
        'Administra la ubicación, el radio permitido y el estado de cada sede.',
    child: FutureBuilder<List<Sede>>(
      future: _carga,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No se pudieron cargar las sedes. Revisa tu conexión e intenta nuevamente.',
              ),
              TextButton(
                onPressed: _actualizar,
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        return FormularioSedesAdmin(
          sedes: snapshot.data ?? const [],
          sedeInicialId: _sedeSeleccionada,
          onGuardado: (id) {
            _sedeSeleccionada = id;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sede guardada correctamente.')),
            );
            _actualizar();
          },
        );
      },
    ),
  );
}
