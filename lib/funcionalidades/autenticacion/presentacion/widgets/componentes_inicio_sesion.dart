import 'package:flutter/material.dart';

import '../../../../app/diseno_sistema.dart';

class FondoInicioSesion extends StatelessWidget {
  const FondoInicioSesion({super.key});

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
                  ColoresSistema.rojoInstitucionalOscuro,
                  ColoresSistema.rojoInstitucionalMedio,
                  ColoresSistema.verdeInstitucional,
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
                      color: Colors.white.withValues(alpha: 0.06),
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
                      color: Colors.white.withValues(alpha: 0.05),
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
            color: ColoresSistema.fondoApp,
          ),
        ),
      ],
    );
  }
}

class CabeceraUnachu extends StatelessWidget {
  const CabeceraUnachu({super.key});

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
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/imagenes/logo_crediasciende.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'CREDIASCIENDE',
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

class InsigniaAccesoInstitucional extends StatelessWidget {
  const InsigniaAccesoInstitucional({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ColoresSistema.rojoInstitucionalMedio,
        borderRadius: BorderRadius.circular(MedidasSistema.radioChip),
        boxShadow: [
          BoxShadow(
            color: ColoresSistema.rojoInstitucionalMedio.withValues(alpha: 0.22),
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
    );
  }
}

class TarjetaErrorInicioSesion extends StatelessWidget {
  const TarjetaErrorInicioSesion({
    super.key,
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MedidasSistema.paddingBloque,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(MedidasSistema.radioBloque),
        border: Border.all(
          color: const Color(0xFFF2C7C5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: ColoresSistema.rojoInstitucionalMedio,
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

class PieInicioSesion extends StatelessWidget {
  const PieInicioSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '(c) 2026 CREDIASCIENDE - Sistema de Control de Asistencia',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
          ),
    );
  }
}
