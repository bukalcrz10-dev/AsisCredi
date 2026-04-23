import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuarios.dart';
import '../fuentes_datos/fuente_datos_usuarios_firestore.dart';
import '../modelos/modelo_usuario.dart';

// Implementacion del repositorio de usuarios usando Firestore.
class RepositorioUsuariosImpl implements RepositorioUsuarios {
  RepositorioUsuariosImpl(this._fuenteDatos);

  final FuenteDatosUsuariosFirestore _fuenteDatos;

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

  @override
  Future<void> guardarUsuario(Usuario usuario) {
    final modelo = ModeloUsuario.desdeEntidad(usuario);
    return _fuenteDatos.guardarUsuario(
      id: usuario.id,
      datos: modelo.aMapa(),
    );
  }
}
