import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/estado_global.dart';
import '/servicios/api_service.dart';
import '/pantallas/registro_medicion.dart';

// ── CORRECCIÓN: convertido a StatefulWidget para cargar desde la API ──
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  bool _cargando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  // ── NUEVO: obtiene el historial real desde el backend ──
  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final lista = await ApiService.obtenerHistorial();

      final registros = lista.map((item) {
        final m = item as Map<String, dynamic>;
        return RegistroSalud(
          id: m['id'].toString(),
          glucosa: m['glucosa'] != null ? (m['glucosa'] as num).toDouble() : null,
          presionSis: m['presion_sis'] as int?,
          presionDia: m['presion_dia'] as int?,
          fecha: DateTime.parse(m['fecha'] as String),
          notas: (m['notas'] as String?) ?? '',
        );
      }).toList();

      appState.setRegistros(registros);
    } on ApiException catch (e) {
      setState(() => _errorMensaje = e.message);
    } catch (e) {
      setState(() => _errorMensaje = 'Error al cargar historial: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarOpciones(BuildContext context, RegistroSalud reg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF12305B)),
                  title: const Text("Modificar registro",
                      style: TextStyle(
                          color: Color(0xFF12305B),
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RegistroMedicionScreen(registroAEditar: reg)),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF4F8FF)),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                  title: const Text("Eliminar",
                      style: TextStyle(
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  onTap: () {
                    appState.eliminarRegistro(reg.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Registro eliminado"),
                        backgroundColor: Color(0xFF12305B),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FF),
          appBar: AppBar(
            title: const Text("Historial",
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF12305B))),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              // ── Botón para refrescar manualmente ──
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF12305B)),
                onPressed: _cargando ? null : _cargarHistorial,
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2F80ED)),
      );
    }

    if (_errorMensaje != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 16),
            Text(_errorMensaje!,
                style: const TextStyle(color: Color(0xFF6B7280)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED)),
              onPressed: _cargarHistorial,
              child: const Text("Reintentar",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (appState.registros.isEmpty) {
      return const Center(
        child: Text("No hay registros aún",
            style: TextStyle(color: Color(0xFF6B7280))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appState.registros.length,
      itemBuilder: (context, index) {
        final reg = appState.registros[index];
        return GestureDetector(
          onTap: () => _mostrarOpciones(context, reg),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x05000000), blurRadius: 5)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: reg.tieneGlucosa && reg.tienePresion
                        ? const Color(0xFFEAF3FF)
                        : (reg.tieneGlucosa
                            ? const Color(0xFF00C7BE).withOpacity(0.1)
                            : const Color(0xFFFF3B30).withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reg.tieneGlucosa && reg.tienePresion
                        ? Icons.health_and_safety
                        : (reg.tieneGlucosa
                            ? Icons.water_drop_outlined
                            : Icons.favorite_border),
                    color: reg.tieneGlucosa && reg.tienePresion
                        ? const Color(0xFF2F80ED)
                        : (reg.tieneGlucosa
                            ? const Color(0xFF00C7BE)
                            : const Color(0xFFFF3B30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reg.tieneGlucosa && reg.tienePresion
                            ? "Glucosa y Presión"
                            : (reg.tieneGlucosa ? "Glucosa" : "Presión"),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF12305B)),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a').format(reg.fecha),
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (reg.tieneGlucosa)
                      Text("${reg.glucosa!.toInt()} mg/dL",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF00C7BE))),
                    if (reg.tienePresion)
                      Text("${reg.presionSis}/${reg.presionDia}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFFF3B30))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
