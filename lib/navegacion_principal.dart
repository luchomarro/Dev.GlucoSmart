import 'package:flutter/material.dart';
import '/estado_global.dart';
import '/pantallas/dashboard.dart';
import '/pantallas/historial.dart';
import '/pantallas/registro_medicion.dart';
import '/pantallas/recomendaciones.dart';
import '/pantallas/perfil.dart';
import '/servicios/api_service.dart';
import '/servicios/auth_service.dart';
import '/widgets/banner_verificacion.dart';

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;
  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      DashboardScreen(onIrAPerfil: () => setState(() => _indiceActual = 3)),
      const HistorialScreen(),
      const RecomendacionesScreen(),
      const PerfilScreen(),
    ];

    // ── CORRECCIÓN: cargamos perfil e historial en paralelo al arrancar,
    //    sin esperar a que el usuario visite cada tab individualmente ──
    _inicializar();
  }

  /// Carga perfil e historial en paralelo. Los errores son silenciosos
  /// para no romper la navegación si hay fallo de red.
  Future<void> _inicializar() async {
    await Future.wait([
      _cargarPerfil(),
      _cargarRegistros(),
    ]);
  }

  /// Toma el usuario cacheado por AuthService (ya fue obtenido en ArranqueScreen)
  /// y lo escribe en appState.perfil para que el Dashboard muestre el nombre.
  Future<void> _cargarPerfil() async {
    try {
      // Siempre pedimos datos frescos al backend para tener la foto actualizada
      Map<String, dynamic>? user = await ApiService.obtenerMiPerfil();

      // Fallback a caché local si falla la red
      user ??= await AuthService.getUser();

      if (user == null) return;

      final fnStr = user['fecha_nacimiento'] as String?;
      DateTime? fechaNac;
      if (fnStr != null && fnStr.isNotEmpty) {
        try { fechaNac = DateTime.parse(fnStr); } catch (_) {}
      }

      appState.actualizarPerfil(PerfilUsuario(
        nombre: (user['nombre'] as String?) ?? '',
        fechaNacimiento: fechaNac,
        peso: (user['peso'] as num?)?.toDouble(),
        altura: (user['altura'] as num?)?.toDouble(),
        telefono: (user['telefono'] as String?) ?? '',
        condicionesMedicas:
            ((user['condiciones_medicas'] as List?)?.cast<String>() ?? []),
        fotoUrl: user['foto_path'] as String?,
      ));
    } catch (_) {
      // Si falla, el nombre queda vacío — no bloqueamos la navegación
    }
  }

  /// Carga el historial de lecturas desde el backend y puebla appState.
  /// Así el Dashboard ya tiene datos sin necesitar visitar el tab Historial.
  Future<void> _cargarRegistros() async {
    try {
      final lista = await ApiService.obtenerHistorial();
      final registros = lista.map((item) {
        final m = item as Map<String, dynamic>;
        return RegistroSalud(
          id: m['id'].toString(),
          glucosa: m['glucosa'] != null
              ? (m['glucosa'] as num).toDouble()
              : null,
          presionSis: m['presion_sis'] as int?,
          presionDia: m['presion_dia'] as int?,
          fecha: DateTime.parse(m['fecha'] as String),
          notas: (m['notas'] as String?) ?? '',
        );
      }).toList();

      appState.setRegistros(registros);
    } catch (_) {
      // Si falla la red, el historial aparece vacío — sin crash
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BannerVerificacion(),
          Expanded(child: _pantallas[_indiceActual]),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroMedicionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual,
        onTap: (index) => setState(() => _indiceActual = index),
        selectedItemColor: const Color(0xFF2F80ED),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Historial",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notificaciones",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
