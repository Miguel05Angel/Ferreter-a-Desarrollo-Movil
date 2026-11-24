# Correcciones de fotos y edición de usuarios — 23/11/2026

## Fotos del catálogo

Se descargan los archivos originales de Drive. El endpoint anterior de
Googleusercontent entregaba un JPEG con fondo negro incluso cuando el original
era un PNG transparente. Se verificó con la foto del alambre: la miniatura tenía
un píxel de fondo negro opaco y el original tenía alfa cero.

La URL nueva renueva la clave de caché. Las tarjetas y la galería conservan su
fondo blanco. Las miniaturas limitan la resolución decodificada en memoria según
su tamaño en pantalla. No se cambian las fotos ni los datos del inventario.

## Edición de usuarios

En Usuarios, el administrador puede tocar el lápiz de cada cuenta para editar
su nombre y teléfono. El teléfono es opcional; si se proporciona, debe tener
nueve dígitos y comenzar con 9. DNI, rol y contraseña no se editan en este formulario.
La lista se actualiza mediante su stream de Firestore. Al editar su propia cuenta,
también se actualiza el perfil de la sesión.

El acceso se valida tanto en las pantallas como en AuthProvider. Las reglas
incluyen un permiso de administrador limitado a nombre y teléfono. Se conserva
el permiso anterior de cada persona para cambiar el nombre y la foto de su propio
perfil; eso no le permite administrar otras cuentas.

## Pendiente: publicar el permiso en Firebase

Por indicación del usuario, los cambios quedan preparados. No se publicaron
reglas en la base real; la sesión de Firebase CLI fue rechazada con HTTP 401.
Instalar el APK no actualiza las reglas del servidor.

Después de ejecutar `firebase login --reauth`, revisar las reglas actuales de
Firestore en el proyecto `ferreteria-el-constructor`. Dentro de su bloque
`match /usuarios/{uid}`, incorporar el siguiente permiso. Reutilizar la función
`administrador()` existente (debe validar el rol real de la sesión).

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

Conservar los permisos vigentes de los demás módulos. Si se comprueba que el
archivo local `firestore.rules` contiene todos los permisos vigentes, puede
publicarse desde esta carpeta con:

```powershell
firebase deploy --only firestore:rules --project ferreteria-el-constructor
```

Si las reglas reales ya permiten la edición al administrador, no hace falta
agregar otro permiso. No se pudo verificar ese estado por falta de sesión válida.

## Verificación

- Las 7 pruebas existentes de catálogo, perfil y acceso pasaron.
- Las 3 pruebas nuevas verifican acceso restringido, guardado por administrador
  y rechazo de formularios inválidos.
- El análisis de los 8 archivos Dart modificados/nuevos no reportó observaciones.
- El análisis general reportó 125 observaciones en otros archivos existentes.
- En los emuladores de Auth y Firestore pasaron 10 comprobaciones de permisos.
  Se verificó que DNI y rol se conservan. El ensayo usa únicamente
  `demo-ferreteria`, sin datos de producción:

```powershell
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-usuarios.cjs"
```

## Compilar Android

```powershell
flutter pub get
flutter build apk --release --build-number=3
```

El APK mantiene el identificador de aplicación y la firma de compilación que ya
usa el proyecto. No desinstalar la app anterior si se desea conservar sus datos.
