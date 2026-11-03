import 'package:flutter/foundation.dart';

import '../data/models/producto_media.dart';
import '../services/media_service.dart';

enum EstadoMedia { sinConfigurar, cargando, listo, error }

/// Carga una sola vez el manifiesto de imagenes reales desde Google Drive y
/// responde que recursos tiene cada producto.
class MediaProvider extends ChangeNotifier {
  Map<String, ProductoMedia> _mapa = {};
  EstadoMedia _estado = EstadoMedia.sinConfigurar;

  EstadoMedia get estado => _estado;

  ProductoMedia? de(String codigo) {
    // Forzamos mayúsculas y quitamos espacios para evitar fallos de coincidencia
    final key = codigo.trim().toUpperCase(); 
    
    // Buscamos directamente en el JSON descargado
    final m = _mapa[key];
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
      _estado = _mapa.isEmpty ? EstadoMedia.sinConfigurar : EstadoMedia.listo;
    } catch (e) {
      debugPrint('MediaProvider: $e');
      _estado = EstadoMedia.error;
    }
    notifyListeners();
  }
}