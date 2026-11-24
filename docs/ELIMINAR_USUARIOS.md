# Eliminar usuarios — administración

En Usuarios, usar el menú de tres puntos de otra cuenta → Eliminar usuario.
La pantalla muestra nombre, DNI y rol de la cuenta seleccionada. Para confirmar,
el administrador escribe el DNI de esa cuenta y su propia contraseña.

La función `eliminarUsuario` comprueba el rol real del administrador, su
identidad y una autenticación de los últimos cinco minutos. Impide eliminar
la propia cuenta. Elimina el usuario de Firebase Authentication y luego su
perfil de Firestore. Las ventas históricas y sus referencias no se borran.

La eliminación no se puede deshacer. Si se pierde la respuesta o falla la
limpieza del perfil después de retirar el acceso, se puede repetir la operación
para terminarla. No se elimina primero el perfil dejando una cuenta con acceso.

## Publicación pendiente

Los cambios están en el código y se probaron localmente; no se publicaron las
funciones de administración en el proyecto real. Como en la entrega anterior,
para habilitar eliminar usuarios y restablecer contraseñas de otras cuentas:

```powershell
firebase login --reauth
firebase deploy --only functions:eliminarUsuario,functions:restablecerPasswordUsuario --project ferreteria-el-constructor
```

Ambas funciones usan `southamerica-east1`. Conservar las reglas de los otros
módulos; no conceder eliminación directa de perfiles desde el cliente. La
edición de nombre y teléfono mantiene su permiso de reglas independiente.

## Pruebas

- Las 15 pruebas de Flutter pasan, incluyendo menú, confirmación del DNI,
  contraseña obligatoria, error de autenticación y restricción de acceso.
- Las pruebas del servidor en emuladores verifican: rechazo sin sesión,
  vendedor, sesión antigua, cuenta propia e identidad de destino inconsistente;
  eliminación de vendedor y otro administrador; eliminación en Authentication
  y Firestore; conservación de ventas; repetición de la solicitud y limpieza
  de un perfil cuyo acceso ya fue eliminado.

Después de `npm ci` en `functions`, desde la raíz del proyecto:

```powershell
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-eliminar.cjs"
```

Estas pruebas eliminan exclusivamente cuentas ficticias del proyecto emulado
`demo-ferreteria`. No se eliminaron cuentas reales durante el desarrollo.

Referencia: [administración de usuarios con Firebase Admin SDK](https://firebase.google.com/docs/auth/admin/manage-users).
