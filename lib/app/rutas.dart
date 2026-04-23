import 'package:flutter/material.dart';

import '../funcionalidades/admin/presentacion/paginas/pagina_inicio_sesion_admin.dart';
import '../funcionalidades/admin/presentacion/widgets/compuerta_admin.dart';
import '../funcionalidades/autenticacion/presentacion/paginas/pagina_inicio_sesion.dart';

// Este archivo centraliza los nombres de rutas de toda la aplicacion.
// Se mantiene en app/ porque su responsabilidad es global, no de un modulo.
abstract final class RutasAplicacion {
  static const inicioSesion = '/inicio-sesion';
  static const inicioSesionAdmin = '/inicio-sesion-admin';
  static const panelAdmin = '/panel-admin';
}

// Este mapa conecta cada ruta con su pantalla correspondiente.
// Cuando agreguemos nuevas pantallas formales, se iran registrando aqui.
final Map<String, WidgetBuilder> rutasAplicacion = {
  RutasAplicacion.inicioSesion: (_) => const PaginaInicioSesion(),
  RutasAplicacion.inicioSesionAdmin: (_) => const PaginaInicioSesionAdmin(),
  RutasAplicacion.panelAdmin: (_) => const CompuertaAdmin(),
};
