import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../controladores/controlador_inicio_sesion.dart';
import 'componentes_inicio_sesion.dart';

class FormularioInicioSesion extends StatelessWidget {
  const FormularioInicioSesion({
    super.key,
    required this.controlador,
    required this.correoController,
    required this.contrasenaController,
    required this.mostrarContrasena,
    required this.onAlternarContrasena,
    required this.onIngresar,
  });

  final ControladorInicioSesion controlador;
  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final bool mostrarContrasena;
  final VoidCallback onAlternarContrasena;
  final VoidCallback onIngresar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: const InsigniaAccesoInstitucional(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Iniciar '),
                    const TextSpan(
                      text: 'sesion',
                      style: TextStyle(
                        color: ColoresSistema.rojoInstitucionalMedio,
                        decoration: TextDecoration.underline,
                        decorationColor: ColoresSistema.rojoInstitucionalMedio,
                        decorationThickness: 3,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: ColoresSistema.textoTitulo,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Ingresa tus credenciales para continuar al sistema de control de asistencia.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Correo institucional',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Ingresa tu correo institucional',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Contrasena',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contrasenaController,
              obscureText: !mostrarContrasena,
              decoration: InputDecoration(
                hintText: 'Ingresa tu contrasena',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onAlternarContrasena,
                  icon: Icon(
                    mostrarContrasena
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controlador.cargando ? null : onIngresar,
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresSistema.rojoInstitucional,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MedidasSistema.radioBloque,
                    ),
                  ),
                ),
                icon: controlador.cargando
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
                  controlador.cargando
                      ? 'Ingresando...'
                      : 'INGRESAR AL SISTEMA',
                ),
              ),
            ),
            if (controlador.mensajeError != null) ...[
              const SizedBox(height: 16),
              TarjetaErrorInicioSesion(
                mensaje: controlador.mensajeError!,
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
                  color: ColoresSistema.textoSuave,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Conexion segura - Acceso exclusivo para personal autorizado',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
