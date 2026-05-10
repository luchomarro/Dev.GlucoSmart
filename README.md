# GlucoSmart

**GlucoSmart** es una aplicación móvil desarrollada con Flutter para el monitoreo inteligente de niveles de glucosa en sangre. Permite a los usuarios registrar, visualizar y hacer seguimiento de sus mediciones de glucosa de manera sencilla e intuitiva.

---

## Características

- **Gráficos interactivos** de niveles de glucosa en el tiempo
- **Carga de imágenes** para adjuntar registros o fotos de dispositivos
- **Historial de mediciones** con formato de fecha localizado
- Diseño limpio con Material Design
- Soporte multiplataforma: Android, iOS, Web, Windows, macOS y Linux

---

## Tecnologías utilizadas

| Tecnología | Descripción |
|---|---|
| [Flutter](https://flutter.dev/) | Framework principal de desarrollo |
| [Dart](https://dart.dev/) | Lenguaje de programación |
| [fl_chart](https://pub.dev/packages/fl_chart) | Gráficos interactivos de glucosa |
| [image_picker](https://pub.dev/packages/image_picker) | Selección de imágenes desde cámara/galería |
| [intl](https://pub.dev/packages/intl) | Internacionalización y formato de fechas |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | Íconos estilo iOS |

---

## Instalación y configuración

### Prerrequisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.11.5`
- Dart `^3.11.5`
- Android Studio / Xcode (para desarrollo móvil)

### Pasos

1. **Clona el repositorio:**

```bash
git clone https://github.com/luchomarro/Dev.GlucoSmart.git
cd Dev.GlucoSmart
```

2. **Instala las dependencias:**

```bash
flutter pub get
```

3. **Ejecuta la aplicación:**

```bash
flutter run
```

Para una plataforma específica:

```bash
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d chrome    # Web
flutter run -d windows   # Windows
```

---

## Estructura del proyecto

```
Dev.GlucoSmart/
├── android/          # Configuración nativa Android
├── ios/              # Configuración nativa iOS
├── linux/            # Configuración para Linux
├── macos/            # Configuración para macOS
├── web/              # Configuración para Web
├── windows/          # Configuración para Windows
├── lib/              # Código fuente principal (Dart)
│   └── main.dart     # Punto de entrada de la app
├── assets/
│   └── images/       # Recursos de imagen
├── test/             # Pruebas unitarias y de widget
├── pubspec.yaml      # Dependencias y configuración del proyecto
└── README.md
```

---

## Pruebas

```bash
flutter test
```

---

## Contribuciones

¡Las contribuciones son bienvenidas! Si deseas mejorar GlucoSmart:

1. Haz un fork del repositorio
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
3. Realiza tus cambios y haz commit: `git commit -m 'Agrega nueva funcionalidad'`
4. Sube tu rama: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

---

## Licencia

Este proyecto es de uso privado. Para más información, contacta al autor.

---

## Autor

**luchomarro** — [@luchomarro](https://github.com/luchomarro)

---

> _GlucoSmart — Monitorea tu salud de forma inteligente_
