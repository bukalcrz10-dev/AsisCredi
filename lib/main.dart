import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app/aplicacion.dart';
import 'firebase_options.dart';

// Punto de entrada principal del proyecto.
// Este archivo solo debe encargarse de preparar servicios globales
// antes de cargar la interfaz definida dentro de la carpeta app/.
Future<void> main() async {
  // Flutter necesita esta inicializacion previa cuando el arranque
  // usa codigo asincrono antes de mostrar la primera pantalla.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase se inicia aqui porque luego sera compartido por
  // autenticacion, base de datos, alertas y futuras notificaciones.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // La clase Aplicacion concentra la configuracion visual y de rutas.
  runApp(const Aplicacion());
}
