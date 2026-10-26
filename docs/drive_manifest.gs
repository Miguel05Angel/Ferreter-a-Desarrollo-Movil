/**
 * GENERADOR DEL MANIFIESTO DE IMAGENES (catalogo_media.json)
 *
 * Como usarlo:
 *  1. En Google Drive crea la carpeta c  y dentro una
 *     carpeta por cada producto, con el CODIGO como nombre (HER-001, TUB-002...).
 *  2. Dentro de cada carpeta sube los archivos con estos nombres:
 *        modelo.glb                 -> modelo 3D real (maximo 15 MB)
 *        foto_01.jpg, foto_02.jpg   -> fotos estandar (frontal, posterior, detalle)
 *        giro_01.jpg ... giro_36.jpg-> secuencia de la vista 360, en orden
 *  3. Entra a script.google.com > Nuevo proyecto > pega este codigo > Guardar.
 *  4. Ejecuta la funcion  generarManifiesto  (acepta los permisos).
 *  5. Copia el "ID DEL MANIFIESTO" que aparece en el registro de ejecucion y
 *     pegalo en  lib/core/constants/app_constants.dart  (idManifiestoMedia).
 *
 * Vuelve a ejecutarlo cada vez que agregues o cambies archivos.
 */
const NOMBRE_CARPETA_RAIZ = 'Catalogo_Ferreteria';

function generarManifiesto() {
  const raices = DriveApp.getFoldersByName(NOMBRE_CARPETA_RAIZ);
  if (!raices.hasNext()) {
    throw new Error('No existe la carpeta "' + NOMBRE_CARPETA_RAIZ + '" en tu Drive.');
  }
  const raiz = raices.next();
  const productos = {};
  const carpetas = raiz.getFolders();

  const ordenar = function (a, b) {
    return a[0].localeCompare(b[0], undefined, { numeric: true });
  };

  while (carpetas.hasNext()) {
    const carpeta = carpetas.next();
    const codigo = carpeta.getName().trim().toUpperCase();
    let modelo = null;
    const fotos = [];
    const giro = [];

    const archivos = carpeta.getFiles();
    while (archivos.hasNext()) {
      const f = archivos.next();
      const nombre = f.getName().toLowerCase();
      // La app necesita que el archivo se pueda ver con el enlace
      f.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

      if (nombre.endsWith('.glb') || nombre.endsWith('.gltf')) {
        modelo = f.getId();
      } else if (/^giro_\d+\./.test(nombre)) {
        giro.push([nombre, f.getId()]);
      } else if (/^foto_\d+\./.test(nombre)) {
        fotos.push([nombre, f.getId()]);
      }
    }

    if (modelo || fotos.length || giro.length) {
      productos[codigo] = {
        modelo3d: modelo,
        fotos: fotos.sort(ordenar).map(function (x) { return x[1]; }),
        giro360: giro.sort(ordenar).map(function (x) { return x[1]; }),
      };
    }
  }

  const contenido = JSON.stringify(
    { generado: new Date().toISOString(), productos: productos },
    null,
    2
  );

  // Reemplaza el manifiesto anterior
  const anteriores = raiz.getFilesByName('catalogo_media.json');
  while (anteriores.hasNext()) anteriores.next().setTrashed(true);

  const manifiesto = raiz.createFile('catalogo_media.json', contenido, MimeType.PLAIN_TEXT);
  manifiesto.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

  Logger.log('Productos con recursos: ' + Object.keys(productos).length);
  Logger.log('ID DEL MANIFIESTO (pegalo en AppConstants.idManifiestoMedia): ' + manifiesto.getId());
}
