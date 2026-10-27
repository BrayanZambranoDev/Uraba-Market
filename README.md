# Urabá Market

Plataforma móvil para que los comerciantes de Urabá publiquen y vendan sus productos, y para que los compradores los encuentren y se comuniquen con ellos directamente.

## Funcionalidades

- Registro e inicio de sesión con correo o con Google.
- Perfil de comerciante y directorio de vendedores.
- Publicación de productos y búsqueda.
- Pedidos y detalle de cada orden.
- Chat entre compradores y vendedores.
- Asistente con inteligencia artificial.
- Detección de conexión a internet.

## Tecnologías

- **Flutter / Dart** para la app móvil.
- **Firebase Authentication** (correo y Google Sign-In).
- **Cloud Firestore** como base de datos en tiempo real.

## Estructura

```
lib/
├── main.dart
├── home_screen.dart
└── src/
    ├── services/   # autenticación, Firestore y conectividad
    ├── theme/      # estilos de la app
    └── *_screen.dart  # pantallas (login, productos, pedidos, chat, perfil...)
```

## Cómo ejecutarlo

1. Instalar [Flutter](https://docs.flutter.dev/get-started/install).
2. Configurar un proyecto de Firebase propio (`flutterfire configure`).
3. Ejecutar:
   ```bash
   flutter pub get
   flutter run
   ```

## Autor

Brayan Santiago Zambrano Guzmán · [GitHub](https://github.com/BrayanZambranoDev)
