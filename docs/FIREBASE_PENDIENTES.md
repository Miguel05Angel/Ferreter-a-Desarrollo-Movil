# Entrega a quien administra Firebase

El código incluye fotos sin fondo negro y administración de usuarios desde la
app: editar nombre/teléfono, cambiar la contraseña propia, restablecer la de otra
cuenta y eliminar usuarios. Este commit no publica reglas ni funciones en Firebase.
No hace falta generar un APK para hacer la configuración pendiente.

## 1. Actualizar el proyecto

Desde la copia local del repositorio `Miguel05Angel/Ferreter-a-Desarrollo-Movil`:

```powershell
git switch main
git pull --ff-only origin main
flutter pub get
firebase login --reauth
firebase use ferreteria-el-constructor
```

Conservar los cambios locales propios antes de actualizar. La app usa el proyecto
`ferreteria-el-constructor` y la base de Firestore `(default)`, de acuerdo con
`lib/services/firebase_ferreteria.dart`. Las cuentas de personal están en
`usuarios/{uid}`, donde el ID del documento coincide con el UID de Authentication.
El acceso con DNI usa internamente `DNI@acceso.ferreteria.invalid`.

## 2. Permiso de edición de usuarios

Respaldar las reglas que están publicadas actualmente. Dentro de
`match /usuarios/{uid}`, agregar el permiso de edición administrativa contenido
en `firestore.rules`, conservando los permisos vigentes de los demás módulos:

```text
allow update: if administrador()
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['nombre', 'telefono'])
  && request.resource.data.nombre is string
  && request.resource.data.nombre.size() >= 3
  && request.resource.data.nombre.size() <= 50
  && request.resource.data.telefono is string
  && (request.resource.data.telefono == ''
    || request.resource.data.telefono.matches('^9[0-9]{8}$'));
```

`administrador()` debe comprobar la sesión y el rol real del perfil, como en el
archivo local. No habilitar cambios de DNI/rol ni eliminación directa de perfiles
desde el cliente. Si las reglas publicadas ya cubren este permiso, no duplicarlo.

Solo después de reconciliar el archivo local con las reglas vigentes:

```powershell
firebase deploy --only firestore:rules --project ferreteria-el-constructor
```

No reemplazar las reglas del servidor con el archivo local sin compararlas:
pueden existir permisos adicionales de clientes, proveedores, pedidos u otros módulos.

## 3. Publicar las dos funciones nuevas

Usar Node.js 22, según `functions/package.json`. Desde la raíz del repositorio:

```powershell
Push-Location functions
npm ci
Pop-Location
firebase deploy --only "functions:restablecerPasswordUsuario,functions:eliminarUsuario" --project ferreteria-el-constructor
```

Ambas funciones están exportadas en `functions/index.js` y usan la región
`southamerica-east1`; el cliente de estas dos operaciones apunta a esa misma región.
La cuenta que despliega debe tener los permisos necesarios en el proyecto. Firebase
puede pedir habilitar facturación para Cloud Functions. No desplegar todas las
funciones si solo se busca activar estas operaciones.

Las funciones verifican identidad, rol Administrador en Firestore y autenticación
de los últimos cinco minutos. La app pide la contraseña actual del administrador
y lo reautentica antes de llamarlas. No guardar contraseñas en Firestore.

Cambiar la contraseña propia usa Authentication directamente y no depende de estas
funciones. Restablecer la de otra cuenta y eliminar usuarios sí dependen de publicarlas.
La eliminación impide borrar la propia cuenta y conserva las ventas históricas.

## 4. Verificar en la app

1. Iniciar sesión como administrador. En Usuarios, el lápiz edita nombre/teléfono.
2. En el menú de tres puntos de otra cuenta, restablecer la contraseña de una cuenta
   de prueba. Verificar que la clave nueva permite acceder y la anterior no.
3. Desde Mi perfil, probar Cambiar mi contraseña con una cuenta de prueba.
4. Eliminar exclusivamente una cuenta de prueba: confirmar su DNI y la contraseña
   del administrador. Debe desaparecer de Usuarios y Authentication; sus ventas
   anteriores deben conservarse.
5. Iniciar sesión como vendedor: no debe tener acceso a estas opciones administrativas.

No eliminar cuentas reales para comprobar la implementación. No intentar borrar
la cuenta del administrador que está conectado.

## 5. Pruebas locales disponibles

```powershell
flutter test
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-usuarios.cjs"
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-passwords.cjs"
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-eliminar.cjs"
```

Los emuladores necesitan Java y las dependencias instaladas en `functions`.
Todos los ensayos de servidor usan exclusivamente `demo-ferreteria`.

Detalles: `CORRECCIONES_FOTOS_Y_USUARIOS.md`, `CONTRASENAS_ADMINISTRADOR.md` y
`ELIMINAR_USUARIOS.md`. No se incluyen claves de cuentas ni tokens en esta entrega.
