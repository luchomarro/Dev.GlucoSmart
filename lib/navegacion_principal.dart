import 'package:flutter/material.dart';
import '/pantallas/dashboard.dart';
import '/pantallas/historial.dart';
import '/pantallas/registro_medicion.dart';
import '/pantallas/perfil.dart';

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  // Lista de las 3 pantallas principales
  final List<Widget> _pantallas = [
    const DashboardScreen(),
    const HistorialScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],

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
      // Lo colocamos a la derecha para que no estorbe a los 3 botones de abajo
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Barra de navegación inferior con los 3 botones
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
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
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
