# Claves de API

Qué hay que hacer para que la clave de Google Maps deje de estar expuesta, y
qué no sirve de nada aunque lo parezca.

Fecha: 8 de noviembre de 2026.

---

## Lo primero, porque casi todos lo entienden al revés

**Sacar la clave del repositorio no la protege.**

La clave de Maps para Android **tiene que viajar dentro del APK**. Es así por
diseño: el SDK la lee del manifiesto en el teléfono del usuario. Cualquiera que
descargue el APK la extrae con un descompresor. No existe forma de esconderla.

Y la nuestra, además, **sigue en el historial de git**. Entró el 25 de octubre
de 2026 en el commit `286dda8`. Aunque hoy la borremos del archivo, un
`git log -p` la recupera. Reescribir el historial de un repositorio que ya
tiene tres PR mergeados no compensa.

Así que el cambio de esta rama —mover la clave a un archivo no versionado—
**sirve para que no entren claves nuevas al repositorio**, no para salvar la
que ya se filtró.

Lo que protege de verdad son los dos pasos de abajo: **rotar** y **restringir**.

---

## Paso 1: restringir (lo urgente)

Una clave sin restricciones funciona desde cualquier aplicación y para
cualquier API de Google. Hay bots que rastrean GitHub buscando el patrón
`AIza...`; si la encuentran, las peticiones se cargan a nuestro proyecto.

Qué pasa entonces depende de la cuenta:

- **Con facturación activada**: llega la factura. Maps cobra por carga de mapa.
- **Sin facturación**: se agota la cuota y **la app deja de mostrar mapas**.

En Google Cloud Console → **APIs y servicios** → **Credenciales** → clic en la
clave:

**Restricción de aplicación** → *Apps de Android*. Se añade el par nombre de
paquete + huella SHA-1. Una petición que no venga de un APK firmado con ese
certificado se rechaza, aunque lleve la clave correcta.

**Restricción de API** → *Restringir clave* → marcar solo **Maps SDK for
Android**. Si se filtra, no sirve para Geocoding, Places ni Directions.

### Las huellas SHA-1

El keystore de depuración se genera **por máquina**: cada uno tiene la suya. Si
se registra solo una, a los demás se les rompen los mapas. Hay que añadir las
tres.

Que cada uno corra esto y pase el resultado:

```bash
keytool -list -v -alias androiddebugkey -keystore "$HOME/.android/debug.keystore" -storepass android -keypass android
```

| Quién | SHA-1 |
|---|---|
| Daniel (75578004-droid) | `80:C5:69:AD:07:86:11:25:6F:CB:31:F9:5B:9D:9B:E1:CA:6A:69:AB` |
| Miguel | *(pendiente)* |
| Mirko | *(pendiente)* |

Falta una cuarta: la del keystore de **release**, cuando se cree. Hoy no
existe, porque `build.gradle.kts` firma la release con la clave de depuración.

---

## Paso 2: rotar (porque la actual está quemada)

La clave que está en el historial hay que darla por perdida. El orden importa,
para no quedarse sin mapas en medio:

1. Crear una clave nueva en Credenciales.
2. Restringirla con el paso 1 **antes** de usarla.
3. Ponerla en `android/secrets.properties` y comprobar que el mapa carga.
4. Recién entonces **borrar la clave vieja**.

Si se borra primero, la app deja de funcionar hasta que el cambio se propague.

---

## Cómo queda configurado el proyecto

La clave ya no está en `AndroidManifest.xml`. Ahora hay un placeholder:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${MAPS_API_KEY}"/>
```

`android/app/build.gradle.kts` lo rellena leyendo `android/secrets.properties`,
que está en el `.gitignore`.

**Cada uno tiene que crear el suyo**, una vez:

```bash
cp android/secrets.properties.example android/secrets.properties
```

Y poner la clave dentro. Si el archivo falta, el proyecto **compila igual**:
el mapa sale gris y el log dice `API key not found`. Es preferible a un build
roto que nadie sabe arreglar.

---

## La clave de Firebase NO es el mismo caso

En `lib/firebase_options.dart` hay otra clave `AIza...`. **Esa es normal que
sea pública** y no hay que esconderla: Google la documenta así. Lo que protege
a Firebase no es el secreto de esa clave, sino las reglas de seguridad.

Y ahí estamos bien: desde que entró el PR #2, `firestore.rules` exige sesión
iniciada y comprueba el rol. La regla `allow read, write: if true` que había
antes ya no está.

---

## El `applicationId`: resuelto, con dos rezagados

Cuando se escribió este documento el proyecto usaba `com.example.ferreteria_app`,
el placeholder de la plantilla de Flutter, que **Google Play rechaza**. Cambiarlo
estaba bloqueado: el `google-services.json` declaraba el paquete viejo y el
plugin de Google Services falla si no coinciden.

**El 16 de noviembre Miguel lo resolvió** (PR #8). Movió el proyecto a un
Firebase nuevo (`ferreteria-el-constructor`), registró ahí la app Android con el
paquete definitivo y también la app Web, y actualizó el `google-services.json`.
Android quedó alineado:

```
applicationId = "com.elconstructor.ferreteria_app"
namespace     = "com.elconstructor.ferreteria_app"
```

Esto importa para las claves: la restricción del paso 1 se registra contra el
nombre de paquete, así que hay que usar **`com.elconstructor.ferreteria_app`**.
Si alguien alcanzó a registrar el `com.example`, esa restricción ya no sirve y
hay que rehacerla.

### Los dos rezagados

El cambio se aplicó en Android pero no llegó a dos sitios. Se arreglan en esta
rama:

| Archivo | Se quedó en |
|---|---|
| `codemagic.yaml` | `bundle_identifier: com.example.ferreteria_app` |
| `lib/firebase_options.dart` | el mensaje de ayuda para registrar la app iOS |

El de `codemagic.yaml` no es cosmético: el build de iOS firmaría contra un
identificador que ya no corresponde al proyecto.

---

## Verificación

No es teoría: se compiló un APK de debug en cada caso, con Flutter 3.47.9 y
Gradle 9.3.1.

| Caso | Resultado |
|---|---|
| **Sin** `secrets.properties` | Compila. Manifiesto fusionado: `android:value=""` |
| **Con** `secrets.properties` | Compila. Manifiesto fusionado: la clave real, sin rastro del placeholder |

Lo que **no** se probó: ejecutar la app con un mapa en pantalla. Hace falta un
dispositivo y una clave ya restringida.

---

## De paso, dos cosas que vimos

`AndroidManifest.xml` tiene `android:usesCleartextTraffic="true"`, que permite
tráfico HTTP sin cifrar en toda la app. Si todo lo que consume la app es HTTPS
—y debería—, conviene quitarlo.

Y la release se firma con la clave de depuración (`signingConfig =
signingConfigs.getByName("debug")`). Es el valor por defecto de la plantilla.
Para el curso da igual; para publicar, no.
