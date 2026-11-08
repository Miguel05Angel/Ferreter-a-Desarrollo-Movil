# Práctica 11 | Firebase para El Constructor

Se reutiliza la aplicación Android `com.example.ferreteria_app` del proyecto
`ferreteria-app-16bde` y la base de Firestore `ferreteria-db`.

La práctica se demuestra en **Productos**, **Carrito** y **Ventas**. Se busca en el
catálogo de Firestore, se agregan o quitan productos y se muestra el total. Al
confirmar el pago simulado se guarda una venta con sus productos, fecha, total y
estado. El historial usa la colección existente `ventas` y el campo `vendedorId`.
El vendedor consulta sus ventas y el administrador consulta todas.

El cambio solicitado para el equipo está en **Perfil → Usuarios → Registrar
vendedor**. El administrador da de alta al vendedor y conserva su sesión. Ambos
roles ingresan con DNI de ocho dígitos y contraseña. Firebase Authentication usa
un identificador interno del tipo `DNI@acceso.ferreteria.invalid`. La contraseña
queda bajo Firebase Authentication y el rol se guarda en `usuarios/{uid}`.
El servidor comprueba el rol antes de crear una cuenta.

## Demostración local sin facturación

Se necesita Flutter con Android, Firebase CLI, Node.js y Java para el emulador
de Firestore. Desde la carpeta del proyecto:

```powershell
npm.cmd --prefix functions ci
flutter pub get
firebase.cmd emulators:start --project demo-ferreteria --only auth,firestore,functions
```

1. Abre el panel de Emulator Suite en `http://localhost:4000`. En **Authentication**
   agrega un usuario con correo `10000001@acceso.ferreteria.invalid` y una contraseña
   de prueba que elijas. Copia el UID.
2. En Firestore selecciona la base `ferreteria-db`. Si el panel abre la base por
   defecto, usa `http://localhost:4000/firestore/ferreteria-db/data`. Crea el
   documento `usuarios/UID` con los campos de la tabla de abajo y el DNI
   `10000001`.
3. En otra terminal, ejecuta la app en un emulador Android. La dirección
   `10.0.2.2` apunta a la computadora que ejecuta Firebase.

```powershell
flutter run --dart-define=FIREBASE_EMULADOR=10.0.2.2
```

4. Entra como administrador. El primer acceso llena el catálogo de muestra si
   la colección está vacía. Desde **Perfil → Usuarios** registra un vendedor con
   otro DNI ficticio. Cierra sesión y entra con esa cuenta.
5. Busca un producto, agrégalo al carrito, prueba quitarlo, agrégalo de nuevo y
   confirma la venta. Verifica el total y el registro en **Ventas**. Entra como
   administrador para comprobar que también puede consultar esa venta.

La comprobación automatizada crea sus propias cuentas ficticias en una instancia
nueva de los emuladores. Ejecuta este comando con los emuladores detenidos.

```powershell
firebase.cmd emulators:exec --project demo-ferreteria --only auth,firestore,functions "node functions/prueba-emuladores.cjs"
```

## Configurar el Firebase compartido desde la cuenta de Miguel

1. Entra con la cuenta de Google que administra el proyecto y abre
   [ferreteria-app](https://console.firebase.google.com/project/ferreteria-app-16bde/overview).
   En Firestore, selecciona la base existente **ferreteria-db**. El archivo
   `android/app/google-services.json` del proyecto ya identifica esa app Android.
2. Pulsa **Actualizar** junto a **Spark**, elige **Blaze** y vincula la cuenta de
   facturación acordada con el equipo. Firebase requiere Blaze para publicar
   `registrarVendedor` y `registrarVenta`.
   [Publicar Cloud Functions](https://firebase.google.com/docs/functions/get-started)
3. En **Authentication → Sign-in method**, habilita **Correo electrónico/contraseña**.
   En **Authentication → Settings → User actions**, deshabilita la creación de
   cuentas por los usuarios. Si el ajuste aparece al habilitar Identity Platform,
   activa esa opción en la configuración de Authentication y vuelve a **User actions**.
   [Administrar la creación de cuentas](https://firebase.google.com/docs/auth/users)
4. En IAM del proyecto, otorga a la **cuenta de servicio de ejecución de las
   funciones** los roles **Cloud Datastore User** (`roles/datastore.user`) y
   **Firebase Authentication Admin** (`roles/firebaseauth.admin`). Por defecto
   para funciones de segunda generación es `NUMERO_DEL_PROYECTO-compute@developer.gserviceaccount.com`.
   El número se ve en **Configuración del proyecto → General**.
   [IAM del proyecto](https://console.cloud.google.com/iam-admin/iam?project=ferreteria-app-16bde)
5. Abre una terminal de PowerShell en la carpeta que contiene `firebase.json`.
   Instala Node.js 22 si hace falta. Instala Firebase CLI con
   `npm.cmd install -g firebase-tools` si el comando `firebase.cmd` todavía no está
   disponible. Inicia sesión en el CLI con la misma cuenta de Google del paso 1.

```powershell
firebase.cmd login
firebase.cmd projects:list
npm.cmd --prefix functions ci
firebase.cmd deploy --only "functions:registrarVendedor,functions:registrarVenta" --project ferreteria-app-16bde
```

6. Una vez que las dos funciones figuren como publicadas, revisa las reglas
   vigentes en la pestaña **Seguridad** de `ferreteria-db` y guarda una copia.
   El siguiente comando reemplaza las reglas de esa base. Si otras versiones
   de la app la están usando, coordina el cambio con el equipo para que actualicen
   su app y puedan iniciar sesión con los nuevos perfiles. Las reglas de esta
   versión dan acceso a la app a `usuarios`, `productos` y `ventas` según el rol.

```powershell
firebase.cmd deploy --only "firestore:ferreteria-db" --project ferreteria-app-16bde
```

7. En **Authentication → Users**, crea la primera cuenta administradora con
   `DNI@acceso.ferreteria.invalid`, sustituyendo `DNI` por sus ocho dígitos.
   Elige la contraseña en la consola y copia el UID. En **Firestore → ferreteria-db**
   abre o crea la colección `usuarios`, pega el UID como ID del documento y
   agrega estos cuatro campos de tipo **string**.

| Campo | Valor |
| --- | --- |
| `dni` | Los ocho dígitos usados en Authentication, con ceros iniciales si aplica |
| `nombre` | Nombre del administrador |
| `telefono` | Número o texto vacío |
| `rol` | `Administrador` |

8. Instala el APK para Firebase compartido o ejecuta `flutter pub get` y
   `flutter run` desde el código fuente. Entra con el DNI y la contraseña del
   paso 7. Ve a **Perfil → Usuarios → Registrar vendedor** y registra una cuenta
   de prueba con un DNI ficticio distinto. Comprueba que aparece tanto en
   **Authentication → Users** como en **Firestore → ferreteria-db → usuarios**.
   Luego inicia sesión con esa cuenta y verifica que ve el catálogo.

El administrador local de la demostración pertenece al emulador. Cada cuenta de
la base compartida se crea en el proyecto de Firebase del equipo. El responsable
del proyecto puede cambiar una contraseña desde Firebase Authentication.

Los registros de ventas antiguos sin `vendedorId` aparecen en el historial del
administrador. Para asociarlos a un vendedor se necesita el UID correcto.
Clientes, proveedores y cotizaciones siguen el flujo local de esta versión.
