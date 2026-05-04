import 'package:flutter/material.dart';

import '/servicios/auth_service.dart';

/// Banner amarillo que aparece en la parte superior cuando el email
/// del usuario aún no está verificado. Permite reenviar el correo.
///
/// Para usarlo, envuelve el contenido de tu pantalla principal:
///
///   Column(children: [
///     const BannerVerificacion(),
///     Expanded(child: tuContenido),
///   ])
class BannerVerificacion extends StatefulWidget {
  const BannerVerificacion({super.key});

  @override
  State<BannerVerificacion> createState() => _BannerVerificacionState();
}

class _BannerVerificacionState extends State<BannerVerificacion> {
  bool _verificado = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _verificado = user?['email_verificado'] == true);
  }

  Future<void> _reenviar() async {
    setState(() => _enviando = true);
    try {
      await AuthService.reenviarVerificacion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de verificación reenviado.'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _comprobar() async {
    try {
      await AuthService.refrescarUsuario();
      await _cargar();
    } catch (_) {
      /* silencio */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificado) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Verifica tu correo para acceder a todas las funcionalidades.',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _enviando ? null : _reenviar,
            child: _enviando
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reenviar',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    )),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFB45309), size: 20),
            tooltip: 'Ya verifiqué',
            onPressed: _comprobar,
          ),
        ],
      ),
    );
  }
}
