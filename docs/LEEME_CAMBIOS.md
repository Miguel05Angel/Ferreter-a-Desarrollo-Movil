# Como instalar esta version

1. Haz una **copia de seguridad** de tu proyecto actual.
2. Copia estas carpetas/archivos dentro de tu proyecto, sobrescribiendo:
   - `lib/`
   - `pubspec.yaml`
   - `android/app/src/main/AndroidManifest.xml`
3. En la terminal:
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

## Google Maps (clave de API)
El mapa usa Google Maps. Para verlo necesitas una clave:
1. https://console.cloud.google.com > crea un proyecto.
2. Activa **Maps SDK for Android**.
3. Crea una clave de API (Credenciales).
4. Abre `android/app/src/main/AndroidManifest.xml` y cambia `TU_API_KEY_AQUI` por tu clave.
Sin clave el mapa sale gris, pero "Como llegar" y "Google Maps" abren la app de Google Maps igual.

## Cuentas de prueba
Consulta la [guía de la práctica 11](GUIA_11_FIREBASE.md) para crear las
cuentas de prueba con DNI en los emuladores.

## Imagenes reales
Mira `GUIA_IMAGENES_REALES.md`.
