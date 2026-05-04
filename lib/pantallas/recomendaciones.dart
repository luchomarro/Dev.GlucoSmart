// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '/servicios/api_service.dart';

/// Pantalla "Notificaciones" que consulta al backend de Render con JWT.
///
/// Llama al endpoint `GET /api/notifications` (autenticado vía Bearer token):
///   1. El backend lee el perfil y mediciones del usuario en Postgres.
///   2. Predice el riesgo con Random Forest.
///   3. Pide a Gemini una recomendación personalizada.
class RecomendacionesScreen extends StatefulWidget {
  const RecomendacionesScreen({super.key});

  @override
  State<RecomendacionesScreen> createState() => _RecomendacionesScreenState();
}

class _RecomendacionesScreenState extends State<RecomendacionesScreen> {
  Map<String, dynamic>? _datos;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await ApiService.obtenerNotificaciones();
      if (!mounted) return;
      setState(() {
        _datos = datos;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "Notificaciones",
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
            onPressed: _cargando ? null : _cargarNotificaciones,
            tooltip: 'Recargar análisis',
          ),
        ],
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2F80ED)),
            SizedBox(height: 16),
            Text(
              'Analizando tus datos con IA...',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            SizedBox(height: 6),
            Text(
              '(la primera vez puede tardar 30s)',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _construirErrorView();
    }

    if (_datos == null) {
      return const Center(child: Text('Sin datos disponibles.'));
    }

    return _construirContenido(_datos!);
  }

  Widget _construirErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text(
              'No se pudo conectar con el servidor.',
              textAlign: TextAlign.center,
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
              onPressed: _cargarNotificaciones,
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

  Widget _construirContenido(Map<String, dynamic> datos) {
    final riskClass = datos['risk_class'] as int? ?? 0;
    final riskProb = (datos['risk_probability'] as num?)?.toDouble() ?? 0.0;
    final alertas = (datos['alertas'] as List?)?.cast<String>() ?? [];
    final recomendaciones =
        (datos['recomendaciones'] as List?)?.cast<String>() ?? [];

    Color color;
    IconData icono;
    String titulo;

    if (riskClass == 0) {
      color = const Color(0xFF1DB954);
      icono = Icons.check_circle;
      titulo = 'Riesgo Bajo Detectado';
    } else if (riskClass == 1) {
      color = const Color(0xFFF59E0B);
      icono = Icons.warning_amber_rounded;
      titulo = 'Riesgo Moderado / Prediabetes';
    } else {
      color = const Color(0xFFFF3B30);
      icono = Icons.error_outline;
      titulo = 'Riesgo Alto Detectado';
    }

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal con el resultado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icono, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Análisis con Random Forest + Gemini',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confianza del modelo: ${(riskProb * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Alertas
            const Text(
              'Alertas Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF12305B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10),
                ],
              ),
              child: alertas.isEmpty
                  ? const Text(
                      'No hay tendencias de riesgo detectadas.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    )
                  : Column(
                      children: alertas
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.notifications_active_outlined,
                                      color: Color(0xFF2F80ED),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        a,
                                        style: const TextStyle(
                                          color: Color(0xFF12305B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // Recomendaciones
            Row(
              children: const [
                Text(
                  'Recomendación personalizada ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF12305B),
                  ),
                ),
                Icon(Icons.auto_awesome, color: Color(0xFF1DB954), size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: recomendaciones
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF1DB954),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
