import 'package:flutter/material.dart';

import '../../datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../dominio/casos_de_uso/iniciar_sesion.dart';
import '../controladores/controlador_inicio_sesion.dart';

// Pantalla inicial para acceder al sistema.
// El trabajador o administrador entra con correo y contrasena
// antes de poder ver su flujo correspondiente.
class PaginaInicioSesion extends StatefulWidget {
  const PaginaInicioSesion({super.key});

  @override
  State<PaginaInicioSesion> createState() => _PaginaInicioSesionState();
}

class _PaginaInicioSesionState extends State<PaginaInicioSesion> {
  late final TextEditingController _correoController;
  late final TextEditingController _contrasenaController;
  late final ControladorInicioSesion _controlador;

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController();
    _contrasenaController = TextEditingController();

    final fuenteDatos = FuenteDatosAutenticacionFirebase();
    final repositorio = RepositorioAutenticacionImpl(fuenteDatos);
    final casoUso = IniciarSesion(repositorio);

    _controlador = ControladorInicioSesion(
      iniciarSesion: casoUso,
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Iniciar sesion',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Esta pantalla conecta la app con Firebase Auth. '
                            'Cuando la sesion se abre correctamente, el sistema entra al flujo del trabajador.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _correoController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _contrasenaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contrasena',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _controlador.cargando
                                  ? null
                                  : () => _controlador.iniciarSesion(
                                        correo: _correoController.text,
                                        contrasena: _contrasenaController.text,
                                      ),
                              icon: _controlador.cargando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_outlined),
                              label: Text(
                                _controlador.cargando
                                    ? 'Ingresando...'
                                    : 'Entrar al sistema',
                              ),
                            ),
                          ),
                          if (_controlador.mensajeError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _controlador.mensajeError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
