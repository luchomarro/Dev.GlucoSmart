// Dispatch condicional: Dart elige el archivo correcto al compilar.
//   - dart.library.html  → disponible en Web      → usa google_sign_in_web.dart
//   - dart.library.io    → disponible en Android/iOS → usa google_sign_in_mobile.dart
export 'google_sign_in_web.dart'
    if (dart.library.io) 'google_sign_in_mobile.dart';
