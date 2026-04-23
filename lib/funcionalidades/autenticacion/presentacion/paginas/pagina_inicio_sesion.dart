import 'package:flutter/material.dart';

import '../controladores/controlador_inicio_sesion.dart';
import '../controladores/fabrica_controlador_inicio_sesion.dart';
import '../widgets/componentes_inicio_sesion.dart';
import '../widgets/formulario_inicio_sesion.dart';

// Pantalla de acceso institucional con identidad visual de UNACHU.
// Mantiene la autenticacion actual por correo y contrasena,
// pero la presenta con una estructura mas institucional y clara en movil.
class PaginaInicioSesion extends StatefulWidget {
  const PaginaInicioSesion({super.key});

  @override
  State<PaginaInicioSesion> createState() => _PaginaInicioSesionState();
}

class _PaginaInicioSesionState extends State<PaginaInicioSesion> {
  late final TextEditingController _correoController;
  late final TextEditingController _contrasenaController;
  late final ControladorInicioSesion _controlador;
  bool _mostrarContrasena = false;

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController();
    _contrasenaController = TextEditingController();
    _controlador = crearControladorInicioSesion();
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
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                const FondoInicioSesion(),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Column(
                        children: [
                          const CabeceraUnachu(),
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: FormularioInicioSesion(
                              controlador: _controlador,
                              correoController: _correoController,
                              contrasenaController: _contrasenaController,
                              mostrarContrasena: _mostrarContrasena,
                              onAlternarContrasena: () {
                                setState(() {
                                  _mostrarContrasena = !_mostrarContrasena;
                                });
                              },
                              onIngresar: () => _controlador.iniciarSesion(
                                correo: _correoController.text,
                                contrasena: _contrasenaController.text,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: const PieInicioSesion(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
