import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';
import '../controladores/controlador_asistencia.dart';

class ModuloPerfilTrabajador extends StatelessWidget {
  const ModuloPerfilTrabajador({
    super.key,
    required this.controlador,
    required this.correoSesion,
    required this.onCerrarSesion,
    this.onRostroCelular,
  });

  final ControladorAsistencia controlador;
  final String? correoSesion;
  final Future<void> Function()? onCerrarSesion;
  final Future<void> Function()? onRostroCelular;

  @override
  Widget build(BuildContext context) {
    final perfil = controlador.perfilActual;
    final nombreCompleto = perfil?.nombreCompleto ?? 'Trabajador';
    final rol = perfil?.rolOCargo ?? 'Personal institucional';
    final cargo = perfil?.cargo.isNotEmpty == true ? perfil!.cargo : rol;
    final area = perfil?.area.isNotEmpty == true
        ? perfil!.area
        : 'No registrada';
    final telefono = perfil?.telefono.isNotEmpty == true
        ? perfil!.telefono
        : 'No registrado';
    final sede = perfil?.nombreSede ?? 'Pendiente';
    final correoPerfil = perfil?.correoNotificacion;
    final correo = (correoPerfil != null && correoPerfil.isNotEmpty)
        ? correoPerfil
        : (correoSesion ?? 'Sin correo disponible');
    return ListView(
      padding: MedidasSistema.paddingPagina,
      children: [
        Card(
          color: ColoresSistema.fondoTarjeta,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(MedidasSistema.radioTarjeta),
                        topRight: Radius.circular(MedidasSistema.radioTarjeta),
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x80075576),
                                  Color(0x38075576),
                                  Color(0x00FBFDFD),
                                ],
                                stops: [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            top: -86,
                            child: Container(
                              width: 320,
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0x14075576),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -98,
                            child: Container(
                              width: 280,
                              height: 180,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColoresPanel.verde,
                                    ColoresPanel.turquesa,
                                    ColoresPanel.azul,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -18,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white,
                      child: Transform.scale(
                        scale: 1.12,
                        child: Image.asset(
                          'assets/imagenes/logo_crediasciende.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 42, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      nombreCompleto,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ColoresSistema.textoTitulo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rol,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: ColoresSistema.textoSecundario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Informacion institucional',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ColoresSistema.textoFuerte,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Datos principales de tu cuenta de trabajador.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: ColoresSistema.textoSuave,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilaPerfilSimple(
                      icono: Icons.location_city_outlined,
                      titulo: 'Sede asignada',
                      valor: sede,
                    ),
                    const SizedBox(height: 12),
                    _FilaPerfilSimple(
                      icono: Icons.apartment_outlined,
                      titulo: 'Area',
                      valor: area,
                    ),
                    const SizedBox(height: 12),
                    _FilaPerfilSimple(
                      icono: Icons.badge_outlined,
                      titulo: 'Cargo',
                      valor: cargo,
                    ),
                    const SizedBox(height: 12),
                    _FilaPerfilSimple(
                      icono: Icons.email_outlined,
                      titulo: 'Correo institucional',
                      valor: correo,
                    ),
                    const SizedBox(height: 12),
                    _FilaPerfilSimple(
                      icono: Icons.phone_outlined,
                      titulo: 'Telefono',
                      valor: telefono,
                    ),
                    const SizedBox(height: 12),
                    const _FilaPerfilSimple(
                      icono: Icons.verified_user_outlined,
                      titulo: 'Estado de cuenta',
                      valor: 'Activa',
                      colorIcono: ColoresPanel.verde,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onRostroCelular != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRostroCelular,
            icon: const Icon(Icons.face),
            label: const Text('Rostro y celular'),
          ),
        ],
        if (onCerrarSesion != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesion'),
          ),
        ],
      ],
    );
  }
}

class _FilaPerfilSimple extends StatelessWidget {
  const _FilaPerfilSimple({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: MedidasSistema.paddingBloque,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFDFD),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(color: ColoresSistema.bordeSuave),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: colorIcono ?? ColoresSistema.textoSuave),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: ColoresSistema.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ColoresSistema.textoFuerte,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
