import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '/configuracion.dart';

/// Servicio de autenticación.
///
/// Guarda el JWT y los datos del usuario en almacenamiento seguro
/// (Keychain en iOS, EncryptedSharedPreferences en Android).
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _kToken = 'glucosmart_jwt';
  static const _kUser = 'glucosmart_user';

  // Cache en memoria del usuario actual
  static Map<String, dynamic>? _currentUser;
  static String? _currentToken;

  // ----------------- Estado actual -----------------

  static Future<bool> tieneSesion() async {
    final token = await _storage.read(key: _kToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    _currentToken ??= await _storage.read(key: _kToken);
    return _currentToken;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    if (_currentUser != null) return _currentUser;
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    _currentUser = json.decode(raw) as Map<String, dynamic>;
    return _currentUser;
  }

  static Future<void> _guardarSesion(String token, Map<String, dynamic> user) async {
    _currentToken = token;
    _currentUser = user;
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUser, value: json.encode(user));
  }

  static Future<void> logout() async {
    _currentToken = null;
    _currentUser = null;
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }

  // ----------------- Endpoints -----------------

  /// Registra una cuenta nueva. Devuelve el usuario o lanza excepción.
  static Future<Map<String, dynamic>> registrar({
    required String email,
    required String password,
    String? nombre,
  }) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/api/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        if (nombre != null) 'nombre': nombre,
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      await _guardarSesion(data['access_token'] as String, data['user'] as Map<String, dynamic>);
      return data['user'] as Map<String, dynamic>;
    }
    throw _errorFrom(res);
  }

  /// Login email + contraseña.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      await _guardarSesion(data['access_token'] as String, data['user'] as Map<String, dynamic>);
      return data['user'] as Map<String, dynamic>;
    }
    throw _errorFrom(res);
  }

  /// Login con id_token de Google Sign-In.
  static Future<Map<String, dynamic>> loginConGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/api/auth/google'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'id_token': idToken}),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      await _guardarSesion(data['access_token'] as String, data['user'] as Map<String, dynamic>);
      return data['user'] as Map<String, dynamic>;
    }
    throw _errorFrom(res);
  }

  /// Solicita un email para resetear la contraseña.
  static Future<String> solicitarResetPassword(String email) async {
    final res = await http.post(
      Uri.parse('${Config.apiUrl}/api/auth/forgot-password'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['message'] as String;
    }
    throw _errorFrom(res);
  }

  /// Reenvía el email de verificación.
  static Future<void> reenviarVerificacion() async {
    final token = await getToken();
    if (token == null) throw AuthException('No hay sesión activa');

    final res = await http.post(
      Uri.parse('${Config.apiUrl}/api/auth/resend-verification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw _errorFrom(res);
  }

  /// Refresca los datos del usuario desde el servidor.
  static Future<Map<String, dynamic>> refrescarUsuario() async {
    final token = await getToken();
    if (token == null) throw AuthException('No hay sesión activa');

    final res = await http.get(
      Uri.parse('${Config.apiUrl}/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode == 200) {
      final user = json.decode(res.body) as Map<String, dynamic>;
      _currentUser = user;
      await _storage.write(key: _kUser, value: json.encode(user));
      return user;
    }
    if (res.statusCode == 401) {
      // Token inválido o expirado: limpiar sesión
      await logout();
    }
    throw _errorFrom(res);
  }

  // ----------------- Helpers -----------------

  static AuthException _errorFrom(http.Response res) {
    String msg;
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      msg = (body['detail'] ?? body['message'] ?? res.body).toString();
    } catch (_) {
      msg = res.body;
    }
    return AuthException(msg, statusCode: res.statusCode);
  }
}

class AuthException implements Exception {
  final String message;
  final int statusCode;
  AuthException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}
