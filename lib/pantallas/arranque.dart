import 'package:flutter/material.dart';

import '/navegacion_principal.dart';
import '/servicios/auth_service.dart';
import 'login.dart';

/// Pantalla de arranque que decide a dónde ir según haya sesión guardada.
///
/// - Si hay JWT válido en almacenamiento seguro -> NavegacionPrincipal
/// - Si no -> LoginScreen
///
/// Reemplaza la pantalla de "Bienvenida" original como punto de entrada
/// inicial de la app (ver main.dart).
class ArranqueScreen extends StatefulWidget {
  const ArranqueScreen({super.key});

  @override
  State<ArranqueScreen> createState() => _ArranqueScreenState();
}

class _ArranqueScreenState extends State<ArranqueScreen> {
  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    // Pequeño delay para mostrar el splash brevemente
    await Future.delayed(const Duration(milliseconds: 300));
    final tiene = await AuthService.tieneSesion();
    if (!mounted) return;

    if (tiene) {
      // Validar el token contra el servidor
      try {
        await AuthService.refrescarUsuario();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavegacionPrincipal()),
        );
        return;
      } catch (_) {
        // Token inválido -> a login
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Color(0xFF2F80ED), size: 80),
            SizedBox(height: 16),
            Text(
              'GlucoSmart',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12305B),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF2F80ED)),
          ],
        ),
      ),
    );
  }
}
