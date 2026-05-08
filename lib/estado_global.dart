import 'package:flutter/material.dart';

// --- MODELO DE PERFIL ---
class PerfilUsuario {
  String nombre;
  DateTime? fechaNacimiento;
  double? peso;
  double? altura;
  String telefono;
  List<String> condicionesMedicas;
  bool notificacionesActivas;
  String? fotoPerfilPath; // ruta local (image_picker)
  String? fotoUrl;        // URL de red (Google Sign-In)

  PerfilUsuario({
    required this.nombre,
    this.fechaNacimiento,
    this.peso,
    this.altura,
    this.telefono = '',
    this.condicionesMedicas = const [],
    this.notificacionesActivas = true,
    this.fotoPerfilPath,
    this.fotoUrl,
  });

  double get imc {
    if (peso != null && altura != null && altura! > 0) {
      return peso! / (altura! * altura!);
    }
    return 0.0;
  }
}

// --- MODELO DE REGISTRO ---
class RegistroSalud {
  String id;
  double? glucosa;
  int? presionSis;
  int? presionDia;
  DateTime fecha;
  String notas;

  RegistroSalud({
    required this.id,
    this.glucosa,
    this.presionSis,
    this.presionDia,
    required this.fecha,
    this.notas = '',
  });

  bool get tieneGlucosa => glucosa != null;
  bool get tienePresion => presionSis != null && presionDia != null;
}

// --- EL CEREBRO ---
class AppState extends ChangeNotifier {
  static final AppState _instancia = AppState._interno();
  factory AppState() => _instancia;
  AppState._interno();

  // Perfil del usuario (se actualiza desde la API al hacer login)
  PerfilUsuario perfil = PerfilUsuario(nombre: "");

  // ── CORRECCIÓN: lista vacía; se llena desde la API ──
  List<RegistroSalud> registros = [];

  void actualizarPerfil(PerfilUsuario nuevoPerfil) {
    perfil = nuevoPerfil;
    notifyListeners();
  }

  // ── NUEVO: reemplaza toda la lista con los datos que devuelve la API ──
  void setRegistros(List<RegistroSalud> nuevos) {
    registros = nuevos;
    registros.sort((a, b) => b.fecha.compareTo(a.fecha));
    notifyListeners();
  }

  void agregarRegistro(RegistroSalud nuevo) {
    registros.insert(0, nuevo);
    registros.sort((a, b) => b.fecha.compareTo(a.fecha));
    notifyListeners();
  }

  void actualizarRegistro(RegistroSalud actualizado) {
    int index = registros.indexWhere((r) => r.id == actualizado.id);
    if (index != -1) {
      registros[index] = actualizado;
      registros.sort((a, b) => b.fecha.compareTo(a.fecha));
      notifyListeners();
    }
  }

  void eliminarRegistro(String id) {
    registros.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

final appState = AppState();
