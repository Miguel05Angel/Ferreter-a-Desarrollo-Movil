# Cámara del perfil y fotos del catálogo

La pantalla Mi perfil permite elegir una foto desde la cámara o la galería,
previsualizarla, guardarla o quitarla. El botón de cámara está en la esquina
superior derecha, en lugar del carrito. La foto se reduce a un máximo de 180 KB
y se guarda en el campo `fotoPerfil` del documento del usuario que inició sesión.

El catálogo inicial de 77 productos tiene fotos asignadas por código. Las fotos
se descargan desde Drive y se muestran sobre fondo blanco conservando la
transparencia. No se agregan las imágenes del catálogo al APK.

- Las equivalencias del Drive original están en `lib/data/catalogo_fotos_drive.dart`.
- Las 51 fotos complementarias están en `lib/data/catalogo_fotos_referencia.dart`.
- Las fuentes de las referencias están en `docs/fuentes_fotos_referencia.json`.
- Carpeta de referencias: https://drive.google.com/drive/folders/1hjVaFcFnMzhc-tUBSiDpF1S3SkDwTj7b

Las fotos complementarias se identifican como referenciales: su marca o
presentación puede diferir del inventario. Los precios, medidas, marcas y
existencias de los productos no cambian.

## Ejecutar

```sh
flutter pub get
flutter run
```

Para incorporar esta rama a una copia del repositorio:

```sh
git fetch origin
git switch --track origin/codex/perfil-fotos-catalogo-20261117
flutter pub get
```

Si la rama ya existe localmente, usar `git switch codex/perfil-fotos-catalogo-20261117`
y `git pull --ff-only`.

## Firebase

El cambio de `firestore.rules` permite modificar `fotoPerfil` junto con `nombre`
en el perfil propio, limita la foto a 184320 bytes y mantiene protegidos DNI y rol.
Subir el commit a GitHub no publica estas reglas en Firebase. El responsable del
proyecto debe incorporar ese permiso en las reglas que utiliza actualmente,
conservando los permisos de los otros módulos.

## Comprobaciones

```sh
flutter test test/catalogo_drive_test.dart test/foto_perfil_test.dart test/widget_test.dart
```

Las pruebas comprueban la cobertura de fotos de los 77 productos, las
equivalencias de códigos, la preparación de la foto de perfil y el formulario
de acceso con DNI y contraseña.
