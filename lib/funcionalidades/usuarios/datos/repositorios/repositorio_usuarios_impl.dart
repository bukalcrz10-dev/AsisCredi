import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuarios.dart';
import '../fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../modelos/modelo_usuario.dart';

// Implementacion del repositorio de usuarios usando Firestore.
class RepositorioUsuariosImpl implements RepositorioUsuarios {
  RepositorioUsuariosImpl(this._fuenteDatos);

  final FuenteDatosUsuariosFirestore _fuenteDatos;

  Future<void> actualizarDatosLaborales({
    required String id,
    required String nombreCompleto,
    required String telefono,
    required String area,
    required String cargo,
    String? sedeAsignadaId,
  }) => _fuenteDatos.actualizarDatosLaborales(
    id: id,
    nombreCompleto: nombreCompleto,
    telefono: telefono,
    area: area,
    cargo: cargo,
    sedeAsignadaId: sedeAsignadaId,
  );

  @override
  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    final mapa = await _fuenteDatos.obtenerUsuarioPorId(id);
    if (mapa == null) {
      return null;
    }

    return ModeloUsuario.desdeMapa(mapa, id).aEntidad();
  }

  @override
  Future<List<Usuario>> obtenerUsuarios() async {
    final documentos = await _fuenteDatos.obtenerUsuarios();
    return documentos
        .map((entrada) => ModeloUsuario.desdeMapa(entrada.value, entrada.key))
        .map((modelo) => modelo.aEntidad())
        .toList();
  }

  Future<PaginaUsuarios> obtenerPaginaUsuarios({
    int limite = 30,
    QueryDocumentSnapshot<Map<String, dynamic>>? despuesDe,
  }) async {
    final pagina = await _fuenteDatos.obtenerPaginaUsuarios(
      limite: limite,
      despuesDe: despuesDe,
    );
    return PaginaUsuarios(
      usuarios: pagina.documentos
          .map(
            (documento) => ModeloUsuario.desdeMapa(
              documento.data(),
              documento.id,
            ).aEntidad(),
          )
          .toList(),
      ultimoDocumento: pagina.ultimoDocumento,
      hayMas: pagina.hayMas,
    );
  }

  @override
  Future<void> guardarUsuario(Usuario usuario) {
    final modelo = ModeloUsuario.desdeEntidad(usuario);
    return _fuenteDatos.guardarUsuario(id: usuario.id, datos: modelo.aMapa());
  }
}

class PaginaUsuarios {
  const PaginaUsuarios({
    required this.usuarios,
    required this.ultimoDocumento,
    required this.hayMas,
  });

  final List<Usuario> usuarios;
  final QueryDocumentSnapshot<Map<String, dynamic>>? ultimoDocumento;
  final bool hayMas;
}
