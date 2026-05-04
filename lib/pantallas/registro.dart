import 'package:flutter/material.dart';

import '/navegacion_principal.dart';
import '/servicios/auth_service.dart';
import 'login.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _cargando = false;
  bool _mostrarPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.registrar(
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passCtrl.text,
        nombre: _nombreCtrl.text.trim(),
      );
      if (!mounted) return;
      _mostrarMensaje(
        '¡Cuenta creada! Te enviamos un email para verificar tu correo. '
        'Puedes empezar a usar la app de inmediato.',
        Colors.green,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavegacionPrincipal()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.message, const Color(0xFFFF3B30));
    } catch (_) {
      if (!mounted) return;
      _mostrarMensaje('No se pudo conectar al servidor.', const Color(0xFFFF3B30));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF12305B)),
      ),
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
                    const Text('Crear cuenta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF12305B),
                        )),
                    const SizedBox(height: 4),
                    const Text('Es rápido y gratis',
                        style: TextStyle(color: Color(0xFF6B7280))),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nombreCtrl,
                      enabled: !_cargando,
                      decoration: _dec('Nombre', Icons.person_outline),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_cargando,
                      decoration: _dec('Correo electrónico', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_mostrarPass,
                      enabled: !_cargando,
                      decoration: _dec('Contraseña', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarPass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _mostrarPass = !_mostrarPass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                        if (v.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passConfirmCtrl,
                      obscureText: !_mostrarPass,
                      enabled: !_cargando,
                      decoration: _dec('Confirmar contraseña', Icons.lock_outline),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                        if (v != _passCtrl.text) return 'No coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _registrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80ED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _cargando
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Crear cuenta',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿Ya tienes cuenta? ',
                            style: TextStyle(color: Color(0xFF6B7280))),
                        TextButton(
                          onPressed: _cargando ? null : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text('Iniciar sesión',
                              style: TextStyle(
                                color: Color(0xFF2F80ED),
                                fontWeight: FontWeight.w600,
                              )),
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

  InputDecoration _dec(String label, IconData icon) {
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
