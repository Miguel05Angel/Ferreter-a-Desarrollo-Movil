# Imagenes reales, vista 360 y modelos 3D desde Google Drive

La app ya esta preparada para mostrar **fotos reales, vista 360 y modelos 3D (.glb)**.
Mientras un producto no tenga recursos en Drive, sigue mostrando la ilustracion 3D
integrada, asi que puedes ir cargando producto por producto sin romper nada.

## 1. Que archivos necesitas por producto

| Tipo | Formato | Requisitos |
|---|---|---|
| **Modelo 3D real** | `.glb` (o `.gltf`) | Texturizado con el producto real, **menos de 15 MB**. |
| **Vista 360** | `.jpg` / `.png` | **24 a 36 fotos** seguidas alrededor del producto, fondo neutro (blanco o gris claro), misma distancia y altura en todas. |
| **Fotos estandar** | `.jpg` / `.png` | Alta resolucion: frontal, posterior y 1 o 2 detalles (minimo 2). |

Recomendaciones de peso: fotos de 1000 x 1000 px y menos de 250 KB cada una (comprime con
squoosh.app o tinypng.com). Si el `.glb` pesa demasiado, optimizalo con
`gltf-transform optimize modelo.glb modelo_opt.glb` o con la opcion Draco de Blender.

La lista de los 65 productos con el nombre de carpeta que le corresponde esta en
`LISTA_DE_IMAGENES.csv` (abrela con Excel o Google Sheets y usa la columna ESTADO para avanzar).

## 2. Como ordenar Google Drive

```
Catalogo_Ferreteria/
  HER-001/
    modelo.glb
    foto_01.jpg
    foto_02.jpg
    giro_01.jpg
    giro_02.jpg
    ...
    giro_36.jpg
  HER-002/
    foto_01.jpg
    foto_02.jpg
  TUB-001/
    ...
```

Reglas de nombres (importantes, el script los reconoce asi):
- La carpeta se llama igual que el **codigo del producto** (`HER-001`).
- `modelo.glb` para el 3D, `foto_01.jpg`, `foto_02.jpg`... y `giro_01.jpg` ... `giro_36.jpg`
  (con ceros a la izquierda para que se ordenen bien).

## 3. Conectar Drive con la app (una sola vez)

1. Sube las carpetas a tu Drive.
2. Entra a https://script.google.com , crea un **Nuevo proyecto** y pega el contenido de
   `drive_manifest.gs`. Guarda.
3. Ejecuta la funcion `generarManifiesto` y acepta los permisos. El script:
   - comparte cada archivo como "Cualquier persona con el enlace" (solo lectura),
   - crea `catalogo_media.json` en la carpeta raiz con los IDs de cada archivo.
4. En *Ver > Registros de ejecucion* copia el **ID DEL MANIFIESTO**.
5. Pegalo en `lib/core/constants/app_constants.dart`:

   ```dart
   static const String idManifiestoMedia = 'PEGA_AQUI_EL_ID';
   ```
6. Ejecuta `flutter pub get` y vuelve a compilar.

Cada vez que agregues o cambies archivos, vuelve a ejecutar `generarManifiesto`
(no hace falta recompilar la app; se descarga al abrirla).

Un ejemplo del archivo generado esta en `catalogo_media_EJEMPLO.json`.

## 4. Como se ve en la app

- En el detalle del producto aparece un selector con **3D / 360 / FOTOS / DISENO**
  segun lo que exista para ese producto.
- Las miniaturas de las listas, el carrito, el buscador y las tarjetas de Inicio usan la
  primera foto real. Cuando el producto vuela al carrito tambien lo hace con su foto.
- El modelo 3D se descarga una sola vez y queda guardado en el telefono.

## 5. De donde sacar o como generar las imagenes

1. **Fotos propias (la mejor opcion y sin problemas de derechos):** una caja de luz o una
   cartulina blanca, luz pareja y el celular en un tripode. Para la vista 360 usa un plato
   giratorio y toma 36 fotos girando 10 grados cada vez. Quita el fondo con remove.bg si hace falta.
2. **Catalogos oficiales de las marcas** (Truper, Pretul, Foset, Volteck, Iusa...): muchas
   publican fotos para distribuidores. Pide autorizacion o usa su kit de prensa; no copies
   fotos de tiendas de la competencia.
3. **Modelos 3D:**
   - Escanealos con el celular: Polycam, Kiri Engine o Luma AI exportan a `.glb`.
   - Generalos a partir de 1 a 4 fotos con herramientas de imagen a 3D (Meshy, Tripo, Rodin).
     Revisa que se parezcan al producto real antes de publicarlos.
   - Sketchfab tiene modelos descargables en `.glb`; revisa que la licencia (CC) permita uso comercial.

Prioridad sugerida: empieza por los productos destacados de Inicio (uno por tipo) y los de
mayor venta; con 2 fotos reales por producto ya mejora mucho el catalogo.

## 6. Cosas a tener en cuenta

- El visor 3D usa la libreria `model_viewer_plus` (WebView de Google). La primera vez necesita
  internet porque carga su motor desde la red; luego el `.glb` queda guardado en el telefono.
- Drive limita las descargas si un mismo archivo se baja muchisimas veces en un dia. Para una
  ferreteria pequena no hay problema; si la app crece, conviene pasar a Firebase Storage.
- Los archivos tienen que estar compartidos con el enlace; el script ya lo hace.
