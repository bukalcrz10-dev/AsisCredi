import 'package:flutter/material.dart';

import '../funcionalidades/autenticacion/presentacion/widgets/compuerta_autenticacion.dart';
import 'rutas.dart';
import 'tema.dart';

// Esta clase representa la aplicacion raiz.
// Vive en app/ porque conecta tema, rutas y pantalla inicial,
// sin mezclar reglas de negocio de ningun modulo especifico.
class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia App',
      debugShowCheckedModeBanner: false,
      // El tema se centraliza en app/tema.dart para que todos los modulos
      // compartan una misma identidad visual desde el inicio.
      theme: temaAplicacion(),
      // Las rutas se concentran en un solo archivo para evitar nombres
      // repetidos o dispersos cuando el proyecto crezca.
      routes: rutasAplicacion,
      // La compuerta de autenticacion decide si el usuario debe ver el login
      // o si ya puede entrar a la pantalla principal del trabajador.
      home: const CompuertaAutenticacion(),
    );
  }
}
