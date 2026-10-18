// Nombres centralizados de las colecciones principales en Firebase.
// Vive en nucleo/constantes porque varios modulos consultaran estas
// referencias y conviene evitar errores por texto repetido.
abstract final class ColeccionesFirebase {
  static const usuarios = 'usuarios';
  static const sedes = 'sedes';
  static const asistencias = 'asistencias';
}
