import 'package:flutter/material.dart';

import '../../datos/fuentes_datos/fuente_datos_autenticacion_firebase.dart';
import '../../datos/repositorios/repositorio_autenticacion_impl.dart';
import '../../dominio/casos_de_uso/iniciar_sesion.dart';
import '../controladores/controlador_inicio_sesion.dart';

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
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                const _FondoInicioSesion(),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Column(
                        children: [
                          const _CabeceraUnachu(),
                          Transform.translate(
                            offset: const Offset(0, -12),
                            child: Card(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 24, 22, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB12025),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFB12025)
                                                  .withOpacity(0.22),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.verified_user_outlined,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'ACCESO INSTITUCIONAL',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(text: 'Iniciar '),
                                            TextSpan(
                                              text: 'sesion',
                                              style: const TextStyle(
                                                color: Color(0xFFB12025),
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    Color(0xFFB12025),
                                                decorationThickness: 3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF1B2533),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Text(
                                        'Ingresa tus credenciales para continuar al sistema de control de asistencia.',
                                        textAlign: TextAlign.center,
                                        style:
                                            Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Correo institucional',
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _correoController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Ingresa tu correo institucional',
                                        prefixIcon: Icon(Icons.email_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Contrasena',
                                      style:
                                          Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _contrasenaController,
                                      obscureText: !_mostrarContrasena,
                                      decoration: InputDecoration(
                                        hintText: 'Ingresa tu contrasena',
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _mostrarContrasena =
                                                  !_mostrarContrasena;
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
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F7FF),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFD3E3F9),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Color(0xFF1F5FBF),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Si los permisos de camara y ubicacion aun no estan habilitados, se solicitaran al ingresar.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        const Color(0xFF35506D),
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _controlador.cargando
                                            ? null
                                            : () => _controlador.iniciarSesion(
                                                  correo:
                                                      _correoController.text,
                                                  contrasena:
                                                      _contrasenaController.text,
                                                ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0E4A92),
                                          minimumSize:
                                              const Size.fromHeight(60),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                        icon: _controlador.cargando
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.login_outlined),
                                        label: Text(
                                          _controlador.cargando
                                              ? 'Ingresando...'
                                              : 'INGRESAR AL SISTEMA',
                                        ),
                                      ),
                                    ),
                                    if (_controlador.mensajeError != null) ...[
                                      const SizedBox(height: 16),
                                      _TarjetaErrorInicioSesion(
                                        mensaje: _controlador.mensajeError!,
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    const Divider(height: 1),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.lock_outline,
                                          size: 18,
                                          color: Color(0xFF7A8798),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Conexion segura - Acceso exclusivo para personal autorizado',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: Text(
                              '(c) 2026 UNACHU - Sistema de Control de Asistencia',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 13,
                                  ),
                            ),
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

class _FondoInicioSesion extends StatelessWidget {
  const _FondoInicioSesion();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8E131A),
                  Color(0xFFB12025),
                  Color(0xFF184E2F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  left: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  bottom: -20,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFFF3F6FB),
          ),
        ),
      ],
    );
  }
}

class _CabeceraUnachu extends StatelessWidget {
  const _CabeceraUnachu();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 26),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/imagenes/logo_unachu.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'UNACHU',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de Control de Asistencia',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  fontSize: 11.5,
                ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _TarjetaErrorInicioSesion extends StatelessWidget {
  const _TarjetaErrorInicioSesion({
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF2C7C5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFB12025),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6F1E22),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
