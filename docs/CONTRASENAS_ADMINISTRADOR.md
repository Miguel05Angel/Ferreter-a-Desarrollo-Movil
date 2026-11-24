# Contraseñas desde la cuenta del administrador

## Uso

- Mi perfil → Cambiar mi contraseña: pide contraseña actual, nueva y confirmación.
- Usuarios → menú de tres puntos → Restablecer contraseña: pide la contraseña del administrador,
  la nueva contraseña de la cuenta seleccionada y su confirmación.
- En la fila de la propia cuenta, el menú ofrece Cambiar mi contraseña.
- Vendedores y visitantes no pueden abrir estos formularios dentro de la app.
- Las claves nuevas admiten de 6 a 20 caracteres y al menos un número, según el
  límite que ya utiliza el formulario de acceso. No se recortan espacios de la clave.

El cambio propio usa reautenticación y `updatePassword` de Firebase Authentication.
El restablecimiento de otra cuenta usa una función del servidor que comprueba
el rol real en Firestore, la identidad de la sesión y una autenticación de los
últimos cinco minutos. Se confirma que la cuenta destino corresponde a su DNI
y está habilitada. Se permite restablecer cuentas de vendedores y de otros
administradores. No cambia nombres, DNI ni roles.

No se utilizan correos de recuperación: las direcciones internas de acceso con
DNI no son buzones reales. Las contraseñas nunca se guardan en Firestore ni se
incluyen intencionalmente en los registros. El cambio propio no requiere una
función nueva del servidor; Firebase Authentication debe estar habilitado.

## Publicación pendiente, por indicación del usuario

La función nueva está preparada pero no se publicó en producción. Para habilitar
el restablecimiento de otras cuentas, desde la raíz del proyecto:

```powershell
firebase login --reauth
firebase deploy --only functions:restablecerPasswordUsuario --project ferreteria-el-constructor
```

La función se publica en `southamerica-east1`, región que usa el cliente para
esta operación. Firebase puede exigir facturación habilitada para publicar
Cloud Functions. No publicar otros módulos si no se han revisado.

La edición de nombre y teléfono mantiene el pendiente de reglas descrito en
`CORRECCIONES_FOTOS_Y_USUARIOS.md`. La función de contraseñas usa Admin SDK y no
necesita habilitar escrituras de contraseñas en las reglas de Firestore.

## Verificación

Se probaron las pantallas con sesiones simuladas, confirmación de clave,
restricción por rol y mensajes de error. En los emuladores se probó el handler
real de la función con Auth y Firestore locales: rechazo sin sesión, vendedor,
sesión antigua, datos inválidos, identidad inconsistente y administrador cuyo
rol cambió; restablecimiento de vendedor y de otro administrador; rechazo del
acceso con la clave anterior y aceptación de la nueva. Se verificó que Firestore
conserva únicamente los datos del perfil.

Para repetir el ensayo, ejecutar `npm ci` dentro de `functions` y luego, desde
la raíz del proyecto:

```powershell
firebase emulators:exec --config firebase.usuarios-test.json --project demo-ferreteria --only auth,firestore "node functions/prueba-passwords.cjs"
flutter test test/password_usuario_test.dart test/usuarios_edicion_test.dart
```

Se utiliza exclusivamente `demo-ferreteria` en las pruebas. No se modificaron
contraseñas ni datos de cuentas reales.

Referencias: [gestión de usuarios en Flutter](https://firebase.google.com/docs/auth/flutter/manage-users)
y [gestión de sesiones de Firebase](https://firebase.google.com/docs/auth/admin/manage-sessions).
