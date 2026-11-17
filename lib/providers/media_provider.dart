import 'package:flutter/foundation.dart';

import '../data/models/producto_media.dart';
import '../data/catalogo_fotos_drive.dart';
import '../data/catalogo_fotos_referencia.dart';
import '../services/media_service.dart';

enum EstadoMedia { sinConfigurar, cargando, listo, error }

/// Carga una sola vez el manifiesto de imagenes reales desde Google Drive y
/// responde que recursos tiene cada producto.
class MediaProvider extends ChangeNotifier {
  Map<String, ProductoMedia> _mapa = {};
  EstadoMedia _estado = EstadoMedia.listo;

  EstadoMedia get estado => _estado;

  ProductoMedia? de(String codigo) {
    // Forzamos mayúsculas y quitamos espacios para evitar fallos de coincidencia
    final key = codigo.trim().toUpperCase();

    // Las fotos del Drive compartido se asocian por código; conservamos 3D y 360 del manifiesto.
    final remoto = _mapa[key];
    final codigoFoto = equivalenciasFotosDrive[key] ?? key;
    final referencia = fotosReferenciaDrive[key];
    final fotoDrive = referencia ?? catalogoFotosDrive[codigoFoto];
    final m = fotoDrive == null
        ? remoto
        : ProductoMedia(
            codigo: key,
            fotos: [fotoDrive],
            fotoReferencial: referencia != null,
            modelo3d: remoto?.modelo3d,
            giro360: remoto?.giro360 ?? const [],
          );
    return (m != null && m.tieneAlgo) ? m : null;
  }

  /// Primera fotografia del producto para usar como miniatura.
  String? miniatura(String codigo) {
    final m = de(codigo);
    if (m == null) return null;
    if (m.tieneFotos) return MediaService.urlImagen(m.fotos.first, ancho: 500);
    if (m.tieneGiro) return MediaService.urlImagen(m.giro360.first, ancho: 500);
    return null;
  }

  Future<void> cargar() async {
    _estado = EstadoMedia.cargando;
    notifyListeners();
    try {
      _mapa = await MediaService.cargarManifiesto();
      _estado = EstadoMedia.listo;
    } catch (e) {
      debugPrint('MediaProvider: $e');
      // Las referencias a las fotos de Drive siguen disponibles aunque
      // falle la descarga del manifiesto opcional de recursos 3D y 360.
      _estado = EstadoMedia.listo;
    }
    notifyListeners();
  }
}
