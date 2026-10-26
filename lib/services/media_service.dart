import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../data/models/producto_media.dart';

class MediaService {
  MediaService._();

  static String urlImagen(String id, {int ancho = 900}) =>
      'https://lh3.googleusercontent.com/d/$id';

  static String urlDescarga(String id) =>
      'https://drive.usercontent.google.com/download?id=$id&export=download&confirm=t';

  static Uri get urlManifiesto => Uri.parse(
      'https://drive.usercontent.google.com/download?id=${AppConstants.idManifiestoMedia}&export=download&confirm=t');
      
  static Future<Map<String, ProductoMedia>> cargarManifiesto() async {
    if (AppConstants.idManifiestoMedia.isEmpty) return {};
    try {
      // 🔥 AGREGAMOS EL USER-AGENT AQUÍ PARA ENGAÑAR A GOOGLE DRIVE
      final r = await http.get(
        urlManifiesto,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (r.statusCode != 200) {
        debugPrint('🚨 ERROR HTTP JSON: ${r.statusCode}');
        throw HttpException('Manifiesto: HTTP ${r.statusCode}');
      }

      final json = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final productos = (json['productos'] ?? json) as Map<String, dynamic>;
      final mapa = <String, ProductoMedia>{};
      
      productos.forEach((codigo, valor) {
        if (valor is Map<String, dynamic>) {
          mapa[codigo.trim().toUpperCase()] = ProductoMedia.fromJson(codigo, valor);
        }
      });
      return mapa;
    } catch (e) {
      debugPrint('🚨 ERROR AL DESCARGAR JSON: $e');
      rethrow;
    }
  }

  static Future<String> descargarModelo(
    String codigo,
    String id, {
    ValueChanged<double>? alProgresar,
  }) async {
    final dir = await getApplicationCacheDirectory();
    final carpeta = Directory('${dir.path}/modelos3d');
    if (!await carpeta.exists()) await carpeta.create(recursive: true);
    final archivo = File('${carpeta.path}/${codigo}_$id.glb');
    if (await archivo.exists() && await archivo.length() > 1024) {
      return archivo.path;
    }

    final cliente = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(urlDescarga(id)));
      final resp = await cliente.send(req).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw HttpException('Modelo: HTTP ${resp.statusCode}');
      }
      final total = resp.contentLength ?? 0;
      var recibido = 0;
      final sink = archivo.openWrite();
      await for (final trozo in resp.stream) {
        sink.add(trozo);
        recibido += trozo.length;
        if (total > 0) alProgresar?.call(recibido / total);
      }
      await sink.close();
      if (await archivo.length() < 1024) {
        await archivo.delete();
        throw const HttpException('El archivo del modelo no es valido');
      }
      return archivo.path;
    } finally {
      cliente.close();
    }
  }
}