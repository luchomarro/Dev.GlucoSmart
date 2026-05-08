import 'dart:async';

import 'package:flutter/material.dart';

import '/navegacion_principal.dart';
import '/servicios/auth_service.dart';
import '/servicios/google_sign_in_service.dart'; // ← dispatch condicional web/móvil
import 'recuperar_password.dart';
import 'registro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  bool _mostrarPassword = false;

  late StreamSubscription<String> _googleSub;

  @override
  void initState() {
    super.initState();
    // Inicializa el servicio (registra HtmlElementView en web, no-op en móvil)
    GoogleSignInService.init();
    // Escucha el id_token que llega cuando el usuario se autentica con Google
    _googleSub =
        GoogleSignInService.tokenStream.listen(_manejarCredencialGoogle);
  }

  @override
  void dispose() {
    _googleSub.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _manejarCredencialGoogle(String idToken) async {
    setState(() => _cargando = true);
    try {
      await AuthService.loginConGoogle(idToken);
      if (!mounted) return;
      _irAlHome();
    } on AuthException catch (e) {
      if (!mounted) return;
      _mostrarError(e.message);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error con Google Sign-In: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.login(
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      _irAlHome();
    } on AuthException catch (e) {
      if (!mounted) return;
      _mostrarError(e.message);
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo conectar al servidor.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irAlHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NavegacionPrincipal()),
      (_) => false,
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF3B30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.favorite,
                        color: Color(0xFF2F80ED), size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'GlucoSmart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF12305B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_cargando,
                      decoration: _decoration(
                          'Correo electrónico', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Ingresa tu correo';
                        if (!v.contains('@') || !v.contains('.'))
                          return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_mostrarPassword,
                      enabled: !_cargando,
                      decoration:
                          _decoration('Contraseña', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _mostrarPassword = !_mostrarPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Ingresa tu contraseña';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _cargando
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RecuperarPasswordScreen())),
                        child: const Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(color: Color(0xFF2F80ED))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80ED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _cargando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Iniciar sesión',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o',
                              style: TextStyle(color: Color(0xFF9CA3AF))),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // El servicio devuelve HtmlElementView (web) o OutlinedButton (móvil)
                    GoogleSignInService.buildButton(),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta? ',
                            style: TextStyle(color: Color(0xFF6B7280))),
                        TextButton(
                          onPressed: _cargando
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const RegistroScreen()),
                                  ),
                          child: const Text('Regístrate',
                              style: TextStyle(
                                  color: Color(0xFF2F80ED),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 2),
      ),
    );
  }
}
