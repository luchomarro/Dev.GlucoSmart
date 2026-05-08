/// Configuración global de la app GlucoSmart v0.5.
class Config {
  /// URL base del backend.
  static const String apiUrl = 'https://glucosmart-api.onrender.com';

  /// Google Client ID — obtenido desde Google Cloud Console > Credenciales.
  /// ⚠️  Debe coincidir EXACTAMENTE con el "ID de cliente" que aparece
  ///     en la consola (GlucoSmartWeb).
  static const String googleWebClientId =
      '434739758444-7c6fraj7vses1kcib8o0ee0qsm4km6pn.apps.googleusercontent.com';

  /// Para iOS se necesita un Client ID separado tipo "iOS".
  static const String googleIosClientId = '';
}
