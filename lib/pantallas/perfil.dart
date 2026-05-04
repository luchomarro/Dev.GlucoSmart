import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/pantallas/login.dart';
import '/servicios/api_service.dart';
import '/servicios/auth_service.dart';

/// Pantalla de perfil del usuario, conectada al backend.
///
/// Lee los datos desde GET /api/users/me y permite editarlos.
/// Incluye botón de cerrar sesión al final.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _usuario;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final perfil = await ApiService.obtenerMiPerfil();
      if (!mounted) return;
      setState(() {
        _usuario = perfil;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _abrirEditor() async {
    if (_usuario == null) return;
    final actualizado = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _EditorPerfil(usuario: _usuario!),
      ),
    );
    if (actualizado != null && mounted) {
      setState(() => _usuario = actualizado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF12305B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF12305B)),
            onPressed: _cargando ? null : _cargarPerfil,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F80ED)))
          : _error != null
              ? _construirError()
              : _construirContenido(),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el perfil.',
              style: TextStyle(fontSize: 16, color: Color(0xFF12305B)),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido() {
    final u = _usuario!;
    final nombre = (u['nombre'] as String?) ?? 'Sin nombre';
    final email = u['email'] as String? ?? '';
    final peso = (u['peso'] as num?)?.toDouble() ?? 0.0;
    final altura = (u['altura'] as num?)?.toDouble() ?? 0.0;
    final telefono = u['telefono'] as String? ?? '';
    final condiciones = (u['condiciones_medicas'] as List?)?.cast<String>() ?? [];
    final emailVerificado = u['email_verificado'] == true;

    final fechaNacStr = u['fecha_nacimiento'] as String?;
    DateTime? fechaNac;
    int edad = 0;
    if (fechaNacStr != null && fechaNacStr.isNotEmpty) {
      try {
        fechaNac = DateTime.parse(fechaNacStr);
        final hoy = DateTime.now();
        edad = hoy.year - fechaNac.year;
        if (hoy.month < fechaNac.month ||
            (hoy.month == fechaNac.month && hoy.day < fechaNac.day)) {
          edad--;
        }
      } catch (_) {}
    }

    final imc = (peso > 0 && altura > 0) ? peso / (altura * altura) : 0.0;

    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + nombre + email
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF2F80ED),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12305B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        emailVerificado
                            ? Icons.verified
                            : Icons.error_outline,
                        size: 16,
                        color: emailVerificado
                            ? const Color(0xFF1DB954)
                            : const Color(0xFFB45309),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card con datos personales
            _Card(
              titulo: 'Datos personales',
              children: [
                _FilaDato(label: 'Edad', valor: edad > 0 ? '$edad años' : 'No definida'),
                _FilaDato(label: 'Peso', valor: peso > 0 ? '${peso.toStringAsFixed(1)} kg' : 'No definido'),
                _FilaDato(label: 'Altura', valor: altura > 0 ? '${altura.toStringAsFixed(2)} m' : 'No definida'),
                _FilaDato(
                  label: 'IMC',
                  valor: imc > 0 ? imc.toStringAsFixed(1) : '—',
                  destacar: imc >= 25,
                ),
                _FilaDato(label: 'Teléfono', valor: telefono.isEmpty ? '—' : telefono),
              ],
            ),
            const SizedBox(height: 16),

            // Card con condiciones médicas
            _Card(
              titulo: 'Condiciones médicas',
              children: [
                if (condiciones.isEmpty)
                  const Text(
                    'Sin condiciones registradas.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: condiciones
                        .map((c) => Chip(
                              label: Text(c),
                              backgroundColor: const Color(0xFFEAF3FF),
                              labelStyle: const TextStyle(
                                color: Color(0xFF12305B),
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Botón Editar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _abrirEditor,
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Editar perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Cerrar sesión
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout, color: Color(0xFFFF3B30)),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF3B30)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80), // espacio para que no lo tape la barra
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// Card visual reutilizable
// ====================================================================
class _Card extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  const _Card({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF12305B),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacar;
  const _FilaDato({required this.label, required this.valor, this.destacar = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: destacar ? const Color(0xFFFF3B30) : const Color(0xFF12305B),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// Pantalla de edición del perfil
// ====================================================================
class _EditorPerfil extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const _EditorPerfil({required this.usuario});

  @override
  State<_EditorPerfil> createState() => _EditorPerfilState();
}

class _EditorPerfilState extends State<_EditorPerfil> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _pesoCtrl;
  late TextEditingController _alturaCtrl;
  late TextEditingController _telefonoCtrl;
  DateTime? _fechaNacimiento;
  late List<String> _condiciones;
  bool _guardando = false;

  static const List<String> _condicionesDisponibles = [
    'Familiares con diabetes',
    'Sedentarismo',
    'Hipertensión',
    'Sobrepeso',
    'Tabaquismo',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u['nombre']?.toString() ?? '');
    _pesoCtrl = TextEditingController(
      text: (u['peso'] as num?)?.toStringAsFixed(1) ?? '',
    );
    _alturaCtrl = TextEditingController(
      text: (u['altura'] as num?)?.toStringAsFixed(2) ?? '',
    );
    _telefonoCtrl = TextEditingController(text: u['telefono']?.toString() ?? '');
    _condiciones = ((u['condiciones_medicas'] as List?)?.cast<String>() ?? []).toList();
    final fnStr = u['fecha_nacimiento'] as String?;
    if (fnStr != null && fnStr.isNotEmpty) {
      try {
        _fechaNacimiento = DateTime.parse(fnStr);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 30),
      firstDate: DateTime(1920),
      lastDate: hoy,
    );
    if (fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final actualizado = await ApiService.actualizarMiPerfil(
        nombre: _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
        peso: double.tryParse(_pesoCtrl.text.replaceAll(',', '.')),
        altura: double.tryParse(_alturaCtrl.text.replaceAll(',', '.')),
        telefono: _telefonoCtrl.text.trim(),
        condicionesMedicas: _condiciones,
        fechaNacimiento: _fechaNacimiento,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
      Navigator.of(context).pop(actualizado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF12305B)),
        title: const Text(
          'Editar perfil',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF12305B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _campo('Nombre', _nombreCtrl, Icons.person_outline),
            const SizedBox(height: 16),

            // Fecha de nacimiento
            InkWell(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: Color(0xFF6B7280)),
                    const SizedBox(width: 12),
                    Text(
                      _fechaNacimiento == null
                          ? 'Fecha de nacimiento'
                          : DateFormat('d MMMM y', 'es').format(_fechaNacimiento!),
                      style: TextStyle(
                        color: _fechaNacimiento == null
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF12305B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _campo('Peso (kg)', _pesoCtrl, Icons.monitor_weight_outlined,
                tipo: TextInputType.number),
            const SizedBox(height: 16),
            _campo('Altura (m)', _alturaCtrl, Icons.height,
                tipo: TextInputType.number),
            const SizedBox(height: 16),
            _campo('Teléfono', _telefonoCtrl, Icons.phone_outlined,
                tipo: TextInputType.phone),
            const SizedBox(height: 24),

            const Text(
              'Condiciones médicas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12305B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _condicionesDisponibles.map((c) {
                final activo = _condiciones.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: activo,
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _condiciones.add(c);
                      } else {
                        _condiciones.remove(c);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF2F80ED),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: activo ? Colors.white : const Color(0xFF12305B),
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? tipo,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      enabled: !_guardando,
      decoration: InputDecoration(
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
      ),
    );
  }
}
