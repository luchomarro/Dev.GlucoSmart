import 'package:flutter/material.dart';
import '/estado_global.dart';

class RecomendacionesScreen extends StatelessWidget {
  const RecomendacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          final perfil = appState.perfil;
          final registros = appState.registros;

          int nivelRiesgo = 0;
          List<String> alertas = [];
          List<String> sugerencias = [];

          // Factor A: IMC
          if (perfil.imc > 25.0 && perfil.imc < 30.0) {
            nivelRiesgo += 1;
            alertas.add("Tendencia detectada: Sobrepeso (IMC: ${perfil.imc.toStringAsFixed(1)}).");
          } else if (perfil.imc >= 30.0) {
            nivelRiesgo += 2;
            alertas.add("Hallazgo clínico: Obesidad (IMC: ${perfil.imc.toStringAsFixed(1)}). El peso es un factor clave en la resistencia a la insulina.");
          }

          // Factor B: Condiciones genéticas y de estilo de vida
          if (perfil.condicionesMedicas.contains('Familiares con diabetes')) {
            nivelRiesgo += 1;
            alertas.add("Factor de riesgo: Antecedentes familiares incrementan la predisposición.");
          }
          if (perfil.condicionesMedicas.contains('Sedentarismo')) {
            nivelRiesgo += 1;
            sugerencias.add("Recomendación de IA: Inicia rutinas de caminata de 30 minutos diarios.");
          }

          // Factor C: Análisis de Historial de Glucosa
          var regGlucosa = registros.where((r) => r.tieneGlucosa);
          if (regGlucosa.isNotEmpty) {
            double promGlucosa = regGlucosa.map((r) => r.glucosa!).reduce((a, b) => a + b) / regGlucosa.length;
            if (promGlucosa >= 100 && promGlucosa < 125) {
              nivelRiesgo += 1;
              alertas.add("Alerta predictiva: Tu promedio reciente (${promGlucosa.toStringAsFixed(0)} mg/dL) sugiere posible Prediabetes.");
            } else if (promGlucosa >= 125) {
              nivelRiesgo += 2;
              alertas.add("Atención requerida: Promedio de glucosa alto (${promGlucosa.toStringAsFixed(0)} mg/dL). Consulta a un médico inmediatamente.");
            }
          }

          if (nivelRiesgo > 2) nivelRiesgo = 2;

          String tituloDiagnostico = "";
          Color colorDiagnostico = Colors.green;
          IconData iconoDiagnostico = Icons.check_circle;

          if (nivelRiesgo == 0) {
            tituloDiagnostico = "Riesgo Bajo Detectado";
            colorDiagnostico = const Color(0xFF1DB954);
            sugerencias.add("Sugerencia de bienestar: Mantén tu excelente estilo de vida y dieta balanceada.");
          } else if (nivelRiesgo == 1) {
            tituloDiagnostico = "Riesgo Moderado / Prediabetes";
            colorDiagnostico = const Color(0xFFF59E0B);
            iconoDiagnostico = Icons.warning_amber_rounded;
            sugerencias.add("Plan sugerido: Reduce el consumo de azúcares procesados.");
            sugerencias.add("Recomendación de IA: Aumenta tu actividad física semanal a 150 minutos.");
          } else {
            tituloDiagnostico = "Riesgo Alto Detectado";
            colorDiagnostico = const Color(0xFFFF3B30);
            iconoDiagnostico = Icons.error_outline;
            sugerencias.add("Plan sugerido: Se recomienda un examen HbA1c (Hemoglobina Glicosilada) de laboratorio.");
            sugerencias.add("Recomendación de IA: Consulta con un endocrinólogo esta misma semana.");
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF4F8FF),
            appBar: AppBar(
              title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF12305B))),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // <-- Como ahora es pestaña principal, quitamos la flecha de retroceso
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorDiagnostico, colorDiagnostico.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: colorDiagnostico.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Icon(iconoDiagnostico, color: Colors.white, size: 60),
                        const SizedBox(height: 16),
                        Text("Análisis de Machine Learning", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(tituloDiagnostico, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text("Alertas Recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF12305B))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)]),
                    child: alertas.isEmpty
                        ? const Text("No hay notificaciones ni tendencias de riesgo nuevas.", style: TextStyle(color: Color(0xFF6B7280)))
                        : Column(
                      children: alertas.map((alerta) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: Color(0xFF2F80ED), size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(alerta, style: const TextStyle(color: Color(0xFF12305B)))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("Recomendaciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF12305B))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFEAFBF4), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: sugerencias.map((sug) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Color(0xFF1DB954), size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(sug, style: const TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.w600))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 80), // Espacio para que no lo tape la barra de abajo
                ],
              ),
            ),
          );
        }
    );
  }
}
