import 'dart:convert';

import 'package:http/http.dart' as http;

import '/configuracion.dart';
import 'auth_service.dart';

/// Cliente HTTP que centraliza las llamadas al backend autenticadas.
///
/// Cada método agrega automáticamente el header `Authorization: Bearer <jwt>`.
/// Si el JWT está vencido o no existe, lanza [AuthException].
class ApiService {
  static const Duration _timeoutCorto = Duration(seconds: 15);
  static const Duration _timeoutLargo = Duration(seconds: 45);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw AuthException('No hay sesión activa');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------- Notificaciones (ML + Gemini) ----------------

  static Future<Map<String, dynamic>> obtenerNotificaciones() async {
    final url = Uri.parse('${Config.apiUrl}/api/notifications');
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers).timeout(_timeoutLargo);
    return _parseJson(res);
  }

  // ---------------- Perfil ----------------

  static Future<Map<String, dynamic>> obtenerMiPerfil() async {
    final url = Uri.parse('${Config.apiUrl}/api/users/me');
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers).timeout(_timeoutCorto);
    return _parseJson(res);
  }

  static Future<Map<String, dynamic>> actualizarMiPerfil({
    String? nombre,
    DateTime? fechaNacimiento,
    double? peso,
    double? altura,
    String? telefono,
    List<String>? condicionesMedicas,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/api/users/me');
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      if (peso != null) 'peso': peso,
      if (altura != null) 'altura': altura,
      if (telefono != null) 'telefono': telefono,
      if (condicionesMedicas != null) 'condiciones_medicas': condicionesMedicas,
    };
    final res = await http
        .patch(url, headers: headers, body: json.encode(body))
        .timeout(_timeoutCorto);
    return _parseJson(res);
  }

  // ---------------- Mediciones ----------------

  static Future<Map<String, dynamic>> registrarMedicion({
    double? glucosa,
    int? presionSis,
    int? presionDia,
    String notas = '',
    DateTime? fecha,
  }) async {
    final url = Uri.parse('${Config.apiUrl}/api/readings');
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      if (glucosa != null) 'glucosa': glucosa,
      if (presionSis != null) 'presion_sis': presionSis,
      if (presionDia != null) 'presion_dia': presionDia,
      'notas': notas,
      if (fecha != null) 'fecha': fecha.toIso8601String(),
    };
    final res = await http
        .post(url, headers: headers, body: json.encode(body))
        .timeout(_timeoutCorto);
    return _parseJson(res);
  }

  static Future<List<dynamic>> obtenerHistorial() async {
    final url = Uri.parse('${Config.apiUrl}/api/readings');
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers).timeout(_timeoutCorto);
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw _errorFrom(res);
  }

  // ---------------- Helpers ----------------

  static Map<String, dynamic> _parseJson(http.Response res) {
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw _errorFrom(res);
  }

  static ApiException _errorFrom(http.Response res) {
    String msg;
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      msg = (body['detail'] ?? body['message'] ?? res.body).toString();
    } catch (_) {
      msg = res.body;
    }
    return ApiException(msg, statusCode: res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
