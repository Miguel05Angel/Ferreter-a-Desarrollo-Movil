# Conectar ferreteria_app a Firestore (base `ferreteria-db`)

## 1. Copiar los archivos
Descomprime este zip SOBRE tu proyecto (mismas carpetas, reemplaza cuando pregunte).
Archivos nuevos/cambiados:

- lib/main.dart
- lib/services/firestore_service.dart
- lib/data/firestore_mappers.dart  (nuevo)
- lib/providers/{producto,cliente,proveedor,venta,cotizacion}_provider.dart
- android/app/src/main/AndroidManifest.xml  (permiso INTERNET)

No cambia ninguna pantalla ni el pubspec.yaml.

## 2. Reglas de la base (en Firebase Console)
Firestore Database -> selecciona la base **ferreteria-db** (selector de arriba)
-> pestana **Reglas** -> pega el contenido de `firestore.rules` -> **Publicar**.

## 3. Ejecutar
    flutter clean
    flutter pub get
    flutter run

## 4. Comprobar que funciona (consola de `flutter run`)
Debes ver, en este orden:

    ✅ Firebase INICIALIZADO. Proyecto: ferreteria-app-16bde
    ✅ Firestore CONECTADO a la base "ferreteria-db" (el servidor respondió)
    🌱 Firestore: datos iniciales cargados (N documentos).
    📡 Firestore [productos]: N documentos (servidor)

## 5. Prueba visual
1. En Firebase Console -> ferreteria-db -> Datos: aparecen las colecciones
   productos, clientes, proveedores, ventas, cotizaciones.
2. En la app crea un producto -> aparece en la consola en segundos.
3. En la consola cambia el stock de un producto -> cambia solo en la app.

## Si algo falla
| Mensaje en consola | Que hacer |
|---|---|
| permission-denied | Paso 2 (reglas) |
| not-found | El nombre de la base no es exactamente `ferreteria-db` |
| unavailable / sin respuesta | Internet del telefono o emulador |
| No sale ningun mensaje de Firestore | No estas usando estos archivos: revisa el paso 1 |
