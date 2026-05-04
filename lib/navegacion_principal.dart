import 'package:flutter/material.dart';
import '/pantallas/dashboard.dart';
import '/pantallas/historial.dart';
import '/pantallas/registro_medicion.dart';
import '/pantallas/recomendaciones.dart';
import '/pantallas/perfil.dart';
import '/widgets/banner_verificacion.dart';

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  // Lista de las 4 pantallas principales
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const HistorialScreen(),
    const RecomendacionesScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Banner de verificación de email arriba + contenido de la pestaña abajo
      body: Column(
        children: [
          const BannerVerificacion(),
          Expanded(child: _pantallas[_indiceActual]),
        ],
      ),

      // Botón flotante para agregar registros
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroMedicionScreen()));
        },
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Barra de navegación inferior con los 4 botones
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
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
