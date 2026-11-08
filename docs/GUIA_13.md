# Guía Práctica N° 13 aplicada a El Constructor

Las tres secciones de la guía (sensores, Firebase en iOS, panel web) montadas
sobre este proyecto, no sobre un proyecto de ejemplo.

> Versiones verificadas en pub.dev el 2026-11-08. La guía original traía
> versiones de 2022–2023 que ya no resuelven con un Flutter actual.

---

## 0. Antes que nada: lo que estaba roto

Esto hay que entenderlo porque explica por qué el proyecto no compilaba.

En el commit `8a85087` ("Configure los codigos para la conexion con la base de
datos de Firebase") se agregó Firebase correctamente:

- `pubspec.yaml` con `firebase_core` y `cloud_firestore`
- `lib/main.dart` llamaba a `Firebase.initializeApp()`
- `lib/services/firestore_service.dart` y `lib/data/firestore_mappers.dart`

En el commit siguiente, `286dda8` ("Integré Google Maps y catálogo de
productos"), **el `pubspec.yaml` se sobrescribió y las dos dependencias de
Firebase desaparecieron**. El `main.dart` también perdió la inicialización.

Resultado antes de estos cambios:

| Archivo | Estado |
|---|---|
| `firestore_service.dart` | importa `cloud_firestore` → **no compila** |
| `firestore_mappers.dart` | importa `cloud_firestore` → **no compila** |
| `main.dart` | sin `Firebase.initializeApp()` |
| `FirestoreService` | nadie lo llamaba: código muerto |
| App en ejecución | solo datos locales de `MockData` |

Pasó porque los cambios se repartían como ZIP para "descomprimir encima"
(ver `INSTRUCCIONES.md`). Un ZIP que no incluye el trabajo de otro lo borra.
**Conviene dejar de pasar ZIPs y usar ramas y pull requests**, que es justo lo
que el repo ya tiene configurado.

También: `version: 1.0.0+2git` tenía un `git` pegado por error. El número de
build debe ser entero porque de ahí sale el `versionCode` de Android.

### Qué se corrigió

- `pubspec.yaml`: `version: 1.0.0+2`, SDK `^3.6.0`, Flutter `>=3.27.0`, y de
  vuelta `firebase_core: ^5.1.0` y `cloud_firestore: ^7.1.0`.
- `lib/main.dart`: vuelve a inicializar Firebase y a sembrar la base. Si
  Firebase falla **la app ya no se cae**: sigue con `MockData` y lo avisa por
  consola.
- `lib/firebase_options.dart` (nuevo): valores reales de Android tomados de
  `google-services.json`.

Para arrancar:

```bash
flutter clean
flutter pub get
flutter run
```

En la consola debe salir `✅ Firebase INICIALIZADO` y después
`✅ Firestore CONECTADO a la base "ferreteria-db"`.

---

## 1. Sensores del teléfono

Pantalla nueva: `lib/ui/screens/sensores/sensores_screen.dart`.
Se entra por **Perfil → Sensores y nivel**, o con la ruta
`AppRoutes.sensores`.

Dependencia: `sensors_plus: ^7.1.1`.

### Lo que lee

| Sensor | Para qué sirve | Unidad |
|---|---|---|
| Acelerómetro | aceleración **con** gravedad | m/s² |
| Giroscopio | velocidad de giro | rad/s |
| Magnetómetro | campo magnético (brújula) | µT |
| Aceleración del usuario | igual que el primero pero **sin** gravedad | m/s² |

Además convierte el acelerómetro en un **nivel de burbuja** en grados, que en
una ferretería sirve de verdad: apoyas el teléfono en una repisa o un marco y
te dice si quedó derecho.

### Los dos errores de la guía que aquí están corregidos

**1. Las suscripciones nunca se cancelaban.** La guía hace
`...EventStream().listen(...)` y no guarda el resultado. Al salir de la
pantalla los sensores siguen emitiendo: se fuga memoria y Flutter lanza
`setState() called after dispose()`. La corrección:

```dart
final List<StreamSubscription<dynamic>> _subs = [];

_subs.add(stream.listen((evento) {
  if (!mounted) return;        // el evento puede llegar tras cerrar
  setState(() => asignar(evento));
}, cancelOnError: true));

@override
void dispose() {
  for (final sub in _subs) {
    sub.cancel();              // <- esto falta en la guía
  }
  super.dispose();
}
```

**2. `SensorsPlatform.instance` es la vía interna.** La API pública son las
funciones de nivel superior (`accelerometerEventStream()`, etc.). Es lo que
usa el ejemplo oficial del paquete. Los getters viejos
(`accelerometerEvents`) están marcados `@Deprecated`.

Un detalle extra: un teléfono de gama baja puede no tener giroscopio o
magnetómetro. El `onError` de cada stream muestra "No disponible en este
equipo" en lugar de dejar la tarjeta en blanco para siempre.

---

## 2. Firebase y compilación para iOS

El proyecto **solo tiene carpeta `android/`**. Antes de cualquier cosa de iOS:

```bash
flutter create --platforms=ios .
```

Eso crea `ios/` sin tocar el código existente.

### 2.1 Registrar la app iOS en Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → proyecto
   **ferreteria-app-16bde**
2. Agregar aplicación → iOS
3. **Bundle ID**: el mismo que el `applicationId` de Android,
   `com.example.ferreteria_app`
4. Descargar `GoogleService-Info.plist` y ponerlo en `ios/Runner/`, **sin
   cambiarle el nombre**

> **Sobre `com.example`**: sirve para probar, pero Apple no acepta publicar en
> el App Store con el prefijo `com.example`. Cuando vayan a publicar hay que
> cambiarlo por algo propio (`pe.elconstructor.ferreteria`) en Android, iOS y
> Firebase a la vez.

### 2.2 Generar `firebase_options.dart`

`lib/firebase_options.dart` ya trae Android. Para que iOS y Web también
funcionen, la forma correcta es dejar que lo genere la herramienta oficial:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Mientras no se haga, arrancar en iOS o Web lanza un error con la instrucción
exacta de lo que falta, en vez de un mensaje incomprensible.

### 2.3 Permisos en `ios/Runner/Info.plist`

```xml
<key>NSMotionUsageDescription</key>
<string>La app usa los sensores de movimiento para el nivel de burbuja.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>La app muestra en el mapa la ubicacion de los proveedores.</string>
<key>NSCameraUsageDescription</key>
<string>La app necesita la camara para registrar fotos de productos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>La app necesita acceder a tus imagenes.</string>
```

Dos avisos importantes:

- **`NSMotionUsageDescription` es obligatorio** y la guía no lo menciona. Sin
  esa clave, iOS mata la app al abrir la pantalla de sensores.
- **No copien el `NSAppTransportSecurity` con `NSAllowsArbitraryLoads`** que
  trae la guía. Eso apaga la seguridad de transporte de todo el tráfico de la
  app. Firebase y Google Maps funcionan por HTTPS: no hace falta. Apple además
  pide justificarlo en la revisión.

### 2.4 Compilar en Codemagic (sin Mac)

`codemagic.yaml` ya está en la raíz del proyecto, con dos workflows:
`ios-build` y `web-build`.

Configuración que hay que hacer una vez en Codemagic:

| Dónde | Qué |
|---|---|
| Teams → Integrations | Conectar **App Store Connect** con una API key `.p8` (Issuer ID + Key ID) desde [appstoreconnect.apple.com/access/api](https://appstoreconnect.apple.com/access/api) |
| App settings → Environment variables | Grupo `firebase_ios`, variable `FIREBASE_PLIST` marcada **Secure**, con el `GoogleService-Info.plist` en base64 |
| App settings → Environment variables | Grupo `firebase_hosting`, variable `FIREBASE_TOKEN` (la da `firebase login:ci`) |

Para generar el base64 del plist en Windows:

```bash
certutil -encode GoogleService-Info.plist tmp.b64
```

Luego borren del archivo generado las líneas `-----BEGIN/END CERTIFICATE-----`
y peguen el resto como valor de la variable.

Diferencias con la guía en el `codemagic.yaml`:

- `max_build_duration: 60` en vez de 30. Un primer build con CocoaPods desde
  cero pasa de 30 minutos y se cancela solo.
- La firma se declara en `environment.ios_signing`, que es la forma actual.
- El `api_key: Encrypted(...)` de la guía ya no se usa; ahora es
  `auth: integration`.
- Si falta el plist, el build **falla con un mensaje claro** en vez de generar
  un IPA donde Firebase no arranca.

### 2.5 Instalar en un iPhone real

- **TestFlight** (recomendado): el workflow ya hace
  `submit_to_testflight: true`. En App Store Connect → TestFlight agregan
  testers por correo; les llega un enlace y la app dura 90 días.
- **IPA directo**: descargan el `.ipa` de los artifacts. Solo instala si está
  firmado con un perfil que incluya el UDID de ese iPhone.

---

## 3. Panel administrativo web

Archivos nuevos:

| Archivo | Para qué |
|---|---|
| `web/index.html`, `web/manifest.json` | la carpeta web que el proyecto no tenía |
| `lib/admin_app.dart` | raíz de la versión web |
| `lib/ui/screens/admin/admin_dashboard_screen.dart` | el panel |
| `firebase.json`, `.firebaserc` | Hosting y reglas |

### 3.1 Cómo decide qué mostrar

`lib/main.dart` usa `kIsWeb`, igual que la guía:

```dart
runApp(
  kIsWeb
      ? AdminWebApp(firebaseListo: firebaseListo)
      : const FerreteriaApp(),
);
```

En el navegador arranca el panel; en el teléfono, la app de siempre.
`FerreteriaApp` no se tocó.

### 3.2 Qué hace el panel

Primero pide **login con DNI y contraseña**, el mismo del teléfono, y solo
deja pasar a cuentas con rol **Administrador**. Después:

- **Resumen**: total de productos, cuántos están en stock bajo o agotados,
  valor del inventario, total vendido, y la lista de los que necesitan
  reposición.
- **Productos**: tabla en vivo con crear, editar y eliminar sobre Firestore.
- **Ventas**: listado de solo lectura.

Lee y escribe con el `FirestoreService` y los `Mapeadores` **que ya tenía el
proyecto**, usando el modelo `Producto` real (código, marca, unidad, precio de
compra y de venta, stock mínimo), no el `{nombre, precio}` del ejemplo de la
guía. Lo que se cambia en el panel aparece en los teléfonos y al contrario.

### 3.3 Tres decisiones distintas a la guía

**No se usa `flutter_admin_scaffold`.** Ese paquete (`^2.0.1`) no recibe
mantenimiento desde 2021. El menú lateral es un `NavigationRail` de Flutter:
una dependencia menos y se adapta solo al ancho de la ventana.

**El formulario es un diálogo que devuelve el producto.** La guía guarda un
`_editingId` en el State y lo modifica sin `setState`, así que el botón se
queda con el texto equivocado ("Agregar" cuando ya estás editando). Con un
diálogo que devuelve valor el problema no existe:

```dart
final editado = await showDialog<Producto>(
  context: context,
  builder: (_) => _ProductoFormDialog(original: p),
);
if (editado == null) return;   // canceló
```

**Eliminar pide confirmación.** En la guía un clic borra el documento. Esto es
una base compartida con los teléfonos y Firestore no tiene papelera: el panel
avisa antes.

Un detalle de rendimiento: los streams se crean **una sola vez** en
`initState`, no dentro de `build()`. Creándolos en `build()` cada redibujado
abre una suscripción nueva a Firestore, que se paga en lecturas facturadas.

### 3.4 Registrar la app Web

El panel necesita una app Web en Firebase, que todavía no existe:

1. Firebase Console → proyecto **ferreteria-app-16bde**
2. Configuración del proyecto → Agregar aplicación → **Web (`</>`)**
3. Apodo: `admin-panel-web`
4. `flutterfire configure` para rellenar `firebase_options.dart`

Si se saltan esto, el panel abre igual pero muestra una pantalla que explica
qué falta, con los pasos. No se queda en blanco.

### 3.5 Publicar en Firebase Hosting

Node.js ya está instalado (v24.18.0), así que:

```bash
npm install -g firebase-tools
```

```bash
firebase login
```

```bash
flutter build web --release
```

```bash
firebase deploy --only hosting
```

`firebase.json` y `.firebaserc` ya están configurados (`public: build/web`,
proyecto `ferreteria-app-16bde`), así que **no hace falta `firebase init
hosting`** y no hay riesgo de que les sobrescriba el `index.html`, que es el
accidente típico de ese comando.

Al terminar da una URL como `https://ferreteria-app-16bde.web.app`.

> `firebase.json` declara las reglas apuntando a la base **`ferreteria-db`**,
> no a `(default)`. La app usa una base con nombre, así que sin esa línea
> `firebase deploy --only firestore:rules` publicaría las reglas en la base
> equivocada y seguirían fallando los permisos.

---

## 4. Dos cosas de seguridad antes de entregar

**1. Las reglas de Firestore están abiertas.** `firestore.rules` tiene
`allow read, write: if true`. El repositorio es **público en GitHub** y trae
`google-services.json`, así que cualquiera que lo encuentre puede leer, editar
o borrar toda la base. Para la demo de clase funciona; antes de dejarlo
corriendo conviene cerrarlo con Firebase Authentication:

```
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

**2. La API key de Google Maps está en el `AndroidManifest.xml`** y el repo es
público. Esa key sí se puede usar desde fuera y el consumo se factura a la
cuenta. En Google Cloud Console → Credenciales conviene **restringirla** por
aplicación Android (nombre de paquete + huella SHA-1) y por API.

---

## 5. Lo que falta verificar

Nada de esto se pudo compilar: **Flutter no está instalado en la máquina donde
se hicieron los cambios**. Los archivos de configuración (`pubspec.yaml`,
`codemagic.yaml`, `firebase.json`, `.firebaserc`, `web/manifest.json`) sí se
validaron como YAML y JSON, y la API de `sensors_plus` se verificó contra el
código del paquete 7.1.1 descargado de pub.dev.

Lo que el equipo tiene que correr para confirmar:

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter run
```

```bash
flutter build web --release
```

Si `flutter pub get` se queja del SDK, es que la versión de Flutter es menor
que 3.27. Se arregla con `flutter upgrade`.

### Lo que queda pendiente de verdad

**La app del teléfono sigue leyendo de `MockData`, no de Firestore.** Los
`providers` (`ProductoProvider`, `ClienteProvider`, etc.) trabajan sobre
listas en memoria. `FirestoreService` siembra la base con esos mismos datos la
primera vez, así que al inicio panel y teléfono muestran lo mismo, pero
después **se separan**: lo que el panel escriba en Firestore no aparece en el
teléfono hasta que los providers lean de ahí.

Conectar los providers a Firestore es el paso siguiente y es un cambio de otro
tamaño. No entraba en esta guía.

---

## 6. Integración con el PR #2 (acceso con DNI)

Mientras esto se desarrollaba, `mirkoraymundo18` abrió el **PR #2** desde
`codex/acceso-dni-ferreteria`: 38 archivos, login con DNI, Cloud Functions y
reglas de Firestore cerradas. Toca cosas que esta guía también toca, así que
se integró en la rama `integracion/guia-13-sobre-pr2`.

Dato curioso: **los dos arreglamos por separado** el `version: 1.0.0+2git` y
la falta de dependencias de Firebase. Llegamos al mismo diagnóstico sin
saberlo.

### El conflicto que git no marca

Git reportaba 3 conflictos (`main.dart`, `app_routes.dart`, `firebase.json`).
El peligroso era un cuarto que **no** marcaba: el `pubspec.yaml`.

Como las líneas estaban en sitios distintos, git metió las dos versiones:

```yaml
  firebase_core: ^3.15.2      # del PR
  cloud_firestore: ^5.6.12    # del PR
  ...
  firebase_core: ^5.1.0       # de esta guía
  cloud_firestore: ^7.1.0     # de esta guía
```

Eso es YAML inválido — claves duplicadas — y `flutter pub get` lo rechaza.
Pasado por un parser: `duplicated mapping key (22:3)`.

**Lección para el equipo**: que git diga "sin conflicto" no significa que el
resultado funcione. En archivos de dependencias hay que revisar a mano.

La versión unificada mantiene una sola familia. En FlutterFire las versiones
van emparejadas, no se pueden mezclar generaciones:

```
firebase_core 5.1.0 · firebase_auth 7.0.1 · cloud_firestore 7.1.0 · cloud_functions 7.0.1
```

### Lo que hubo que rehacer

El PR recorta `FirestoreService` de 201 líneas a 40: desaparecen `escuchar()`,
`crear()`, `guardar()`, `eliminar()`, las constantes de colección y
`inicializarBaseDeDatos()`. Quedan `productos`, `ventas` y
`prepararCatalogo()`. El panel web usaba todo lo eliminado, así que se
reescribió contra la API nueva.

Además, las reglas nuevas niegan todo sin sesión. Consecuencias:

| Antes | Ahora |
|---|---|
| Panel anónimo | Pide login y exige rol Administrador |
| Sección Clientes | Sección Ventas |
| `inicializarBaseDeDatos()` al arrancar | `prepararCatalogo()` tras el login |

Lo de Clientes no es capricho: `firestore.rules` solo cubre `usuarios`,
`productos`, `ventas` y `_meta/catalogo`. Las colecciones `clientes`,
`proveedores` y `cotizaciones` **no tienen regla, así que se niegan por
defecto**. Si algún día la app las lee desde Firestore, habrá que añadirlas.

### Un arreglo en el código del PR

`FirebaseFerreteria.inicializar()` llamaba a `Firebase.initializeApp()` **sin
opciones**. En Android funciona porque lee `google-services.json`, pero en web
ese archivo no existe y falla. Se cambió para que pase
`DefaultFirebaseOptions.currentPlatform`, que cubre ambas.

Es el único cambio sobre código del PR; conviene comentárselo a su autor.

### Orden recomendado

1. Que entre el PR #2 a `main`.
2. Rebasar esta rama sobre el `main` nuevo (las decisiones de arriba ya están
   tomadas; sería mecánico).
3. `flutter pub get` y `flutter analyze` antes de abrir el PR.
