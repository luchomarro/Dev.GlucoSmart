// Implementación WEB del servicio de Google Sign-In.
// Usa GIS (Google Identity Services) via dart:js + HtmlElementView.
// Este archivo SOLO se compila en Flutter Web.

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '/configuracion.dart';

// Stream global que emite el id_token cuando el usuario se autentica.
final _ctrl = StreamController<String>.broadcast();
bool _registered = false;

class GoogleSignInService {
  /// Stream que emite el id_token de Google cuando el login tiene éxito.
  static Stream<String> get tokenStream => _ctrl.stream;

  /// Inicializa el servicio y registra el HtmlElementView.
  /// Llamar una sola vez al iniciar la pantalla de login.
  static void init() {
    if (_registered) return;
    _registered = true;

    ui_web.platformViewRegistry.registerViewFactory(
      'glucosmart-google-btn',
      (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '52px'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';

        // 1. Obtener el objeto global de Google
        final google = globalContext.getProperty('google'.toJS) as JSObject?;
        if (google == null) return container;

        // 2. Navegar hasta google.accounts.id
        final accounts = google.getProperty('accounts'.toJS) as JSObject;
        final id = accounts.getProperty('id'.toJS) as JSObject;

        // 3. Inicializar
        final initParams = {
          'client_id': Config.googleWebClientId,
          'callback': ((JSObject resp) {
            final credential = resp.getProperty('credential'.toJS) as JSString?;
            if (credential != null && credential.toDart.isNotEmpty) {
              _ctrl.add(credential.toDart);
            }
          }).toJS,
        }.jsify();

        id.callMethod('initialize'.toJS, initParams);

        // 4. Renderizar el botón
        final renderParams = {
          'type': 'standard',
          'theme': 'outline',
          'size': 'large',
          'width': '380',
          'text': 'continue_with',
          'logo_alignment': 'left',
          'locale': 'es',
        }.jsify();

        id.callMethod('renderButton'.toJS, container as JSAny, renderParams);

        return container;
      },
    );
  }

  /// Devuelve el widget del botón de Google para Web (HtmlElementView).
  static Widget buildButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: const HtmlElementView(viewType: 'glucosmart-google-btn'),
    );
  }
}
