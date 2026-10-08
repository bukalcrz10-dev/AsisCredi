import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../../../autenticacion/presentacion/controladores/controlador_inicio_sesion.dart';
import '../../../autenticacion/presentacion/controladores/fabrica_controlador_inicio_sesion.dart';

class PaginaInicioSesionAdmin extends StatefulWidget {
  const PaginaInicioSesionAdmin({
    super.key,
    this.mensajeInicial,
  });

  final String? mensajeInicial;

  @override
  State<PaginaInicioSesionAdmin> createState() =>
      _PaginaInicioSesionAdminState();
}

class _PaginaInicioSesionAdminState extends State<PaginaInicioSesionAdmin> {
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
        final mensajeVisible =
            _controlador.mensajeError ?? widget.mensajeInicial;

        return Scaffold(
          backgroundColor: ColoresSistema.fondoApp,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: ColoresSistema.fondoTarjeta,
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioTarjeta,
                    ),
                    border: Border.all(color: ColoresSistema.bordeSuave),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ColoresSistema.rojoInstitucional,
                              ColoresSistema.rojoInstitucionalOscuro,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Panel administrativo',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: ColoresSistema.textoTitulo,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acceso exclusivo para administradores institucionales de CREDIASCIENDE.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColoresSistema.textoSecundario,
                              height: 1.5,
                            ),
                      ),
                      if (mensajeVisible != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ColoresSistema.rojoInstitucional.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              MedidasSistema.radioCampo,
                            ),
                            border: Border.all(
                              color: ColoresSistema.bordeIntermedio,
                            ),
                          ),
                          child: Text(
                            mensajeVisible,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: ColoresSistema.rojoInstitucionalOscuro,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo institucional',
                          prefixIcon: Icon(Icons.alternate_email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contrasenaController,
                        obscureText: !_mostrarContrasena,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _mostrarContrasena = !_mostrarContrasena;
                              });
                            },
                            icon: Icon(
                              _mostrarContrasena
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
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
                                ? 'Validando acceso...'
                                : 'Ingresar al panel',
                          ),
                        ),
                      ),
                    ],
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
