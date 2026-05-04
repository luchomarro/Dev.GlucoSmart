/// Configuración global de la app GlucoSmart v0.5.
class Config {
  /// URL base del backend.
  /// IMPORTANTE: cambia esto por la URL real de tu Render.
  static const String apiUrl = 'https://glucosmart-api.onrender.com';

  /// Google Client ID (Web client - se usa también en Android).
  /// Lo obtienes desde Google Cloud Console > Credenciales.
  /// Déjalo vacío si no vas a habilitar Google Sign-In todavía.
  static const String googleWebClientId = '434739758444-0ltkodp0qcvgadus54jas2mnejhenrut.apps.googleusercontent.com';

  /// Para iOS necesitas un Client ID separado tipo "iOS".
  static const String googleIosClientId = '';
}
