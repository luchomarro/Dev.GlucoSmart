// Implementación MÓVIL del servicio de Google Sign-In (Versión 7.0.0+)
// Usa el paquete google_sign_in para Android e iOS.
// Este archivo SOLO se compila en Android/iOS.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '/configuracion.dart';

final _ctrl = StreamController<String>.broadcast();

// 1. En la versión 7, GoogleSignIn es un singleton
final _googleSignIn = GoogleSignIn.instance;
bool _inicializado = false;

class GoogleSignInService {
  /// Stream que emite el id_token de Google cuando el login tiene éxito.
  static Stream<String> get tokenStream => _ctrl.stream;

  /// Inicializamos la configuración de Google (Obligatorio en v7+)
  static Future<void> init() async {
    if (!_inicializado) {
      // 2. Ya no se usan 'scopes' en la inicialización.
      // Solo necesitamos el serverClientId para que nos devuelva el idToken.
      await _googleSignIn.initialize(
        serverClientId: Config.googleWebClientId,
      );
      _inicializado = true;
    }
  }

  /// Devuelve el botón nativo de Flutter para Android/iOS.
  /// Al pulsarlo lanza el picker de cuentas de Google.
  static Widget buildButton() {
    return _GoogleMobileButton(ctrl: _ctrl);
  }
}

class _GoogleMobileButton extends StatefulWidget {
  final StreamController<String> ctrl;
  const _GoogleMobileButton({required this.ctrl});

  @override
  State<_GoogleMobileButton> createState() => _GoogleMobileButtonState();
}

class _GoogleMobileButtonState extends State<_GoogleMobileButton> {
  bool _cargando = false;

  Future<void> _signIn() async {
    setState(() => _cargando = true);
    try {
      // Aseguramos que esté inicializado antes de autenticar
      if (!_inicializado) {
        await GoogleSignInService.init();
      }

      // 3. Utilizamos authenticate() que lanza el Credential Manager en Android
      final account = await _googleSignIn.authenticate();
      if (account == null) return; // Usuario canceló

      // 4. Obtenemos la autenticación (contiene el idToken para Python)
      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        _mostrarError('Google no devolvió un token. Intenta de nuevo.');
        return;
      }

      widget.ctrl.add(idToken);
    } catch (e) {
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        return;
      }
      _mostrarError('Error con Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _cargando ? null : _signIn,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF12305B),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: _cargando
            ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.account_circle, color: Color(0xFFEA4335)),
        label: const Text(
          'Continuar con Google',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
