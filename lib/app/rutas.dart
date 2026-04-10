import 'package:flutter/material.dart';

import '../funcionalidades/autenticacion/presentacion/paginas/pagina_inicio_sesion.dart';
import '../funcionalidades/asistencias/presentacion/paginas/pagina_inicio.dart';

// Este archivo centraliza los nombres de rutas de toda la aplicacion.
// Se mantiene en app/ porque su responsabilidad es global, no de un modulo.
abstract final class RutasAplicacion {
  static const inicioSesion = '/inicio-sesion';
}

// Este mapa conecta cada ruta con su pantalla correspondiente.
// Cuando agreguemos autenticacion, historial o panel, se iran registrando aqui.
final Map<String, WidgetBuilder> rutasAplicacion = {
  RutasAplicacion.inicioSesion: (_) => const PaginaInicioSesion(),
  // Esta ruta directa se deja solo como apoyo de desarrollo.
  // El flujo real entra por la compuerta de autenticacion.
  '/panel-trabajador': (_) => const PaginaInicio(),
};
