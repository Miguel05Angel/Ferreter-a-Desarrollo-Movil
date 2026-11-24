# Cambios de web, app e imágenes — 24/11/2026

La app y el panel usan el proyecto Firebase `ferreteria-el-constructor`, la base
`(default)` y la colección `productos`. Los cambios de precio y stock llegan
por las suscripciones de Firestore. La app ahora también respeta `activo: false`
y `eliminadoEn`, de modo que desactivar, enviar a papelera y restaurar desde la
web cambia la visibilidad en el teléfono.

## Imágenes

Se incluyen 76 fotografías distintas para los 77 productos del catálogo, en PNG
transparente, con un lado máximo de 640 px y miniaturas de hasta 192 px. Las
tarjetas de hasta 128 px usan miniaturas y limitan la decodificación para evitar
cargar fotos grandes en cada fila.

`ImagenCatalogo` reconoce tanto enlaces de Drive con `?id=` como rutas `/d/`,
incluidos los enlaces de descarga que utiliza Android. Primero resuelve el PNG
local. Para una foto remota nueva utiliza caché y mantiene la foto local del
producto durante la espera o ante un error. Las tarjetas y la galería no muestran
el cartel «FALTA IMAGEN» ni iconos de imagen rota mientras esperan una foto.
Un producto sin foto conserva su espacio sin un aviso de error.

El panel también muestra fotos en tarjetas, filas y detalle. Su almacén utiliza
la misma conexión Firestore del resto de la aplicación.

Para regenerar el catálogo, desde la raíz del proyecto:

```powershell
flutter pub get
dart run tool/preparar_imagenes.dart
```

El generador descarga las referencias de Drive, elimina blanco casi neutro
conectado al borde y conserva blancos interiores. Dos fotos con fondos gris y
texturizado tienen contornos específicos verificados. Reutiliza los PNG ya
existentes; para regenerar una fotografía concreta, retirar primero su PNG y su
miniatura. Revisar visualmente cualquier fotografía nueva antes de incorporarla.

## Permisos y publicación

`firestore.rules` refleja las reglas publicadas el 24/11/2026. El cambio que
corrigió el guardado fue permitir `update` de productos a administradores;
anteriormente incluso ellos solo podían modificar stock. Los vendedores siguen
sin poder cambiar precios, visibilidad ni eliminar productos. Conservan la
actualización de stock entero no negativo.

Esta subida de código no despliega Firebase ni genera una APK. La corrección de
permisos ya fue publicada y verificada en Firebase durante el trabajo del
24/11/2026. Antes de futuros despliegues de reglas, comparar siempre el archivo
con la configuración vigente para conservar cambios posteriores.

## Verificación

```powershell
flutter test
firebase emulators:exec --config firebase.precios-test.json --project demo-ferreteria-precios --only auth,firestore "node functions/prueba-precios.cjs"
flutter run -d chrome
```

Las pruebas de permisos se ejecutan exclusivamente en el proyecto demo con Auth
y Firestore locales. Verifican cambio de precio, guardado del formulario completo,
lectura del precio por el vendedor, restricciones por rol, stock, papelera y
restauración. No modifican productos ni cuentas reales.
