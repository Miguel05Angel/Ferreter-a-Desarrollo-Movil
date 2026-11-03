import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Funciones de Google Maps (API de URLs de Maps, no requiere clave):
/// buscar una direccion en el mapa y trazar la ruta hasta ella.
class MapasService {
  MapasService._();

  static String _consulta(String direccion) =>
      Uri.encodeComponent('${direccion.trim()}, Peru');

  static Uri urlBusqueda(String direccion) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_consulta(direccion)}');

  static Uri urlRuta(String direccion) => Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_consulta(direccion)}'
      '&travelmode=driving');

  static Uri get urlFerreteria => Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${AppConstants.latitudFerreteria},${AppConstants.longitudFerreteria}');

  static Future<void> verDireccion(BuildContext context, String direccion) =>
      _abrir(context, urlBusqueda(direccion));

  static Future<void> comoLlegar(BuildContext context, String direccion) =>
      _abrir(context, urlRuta(direccion));

  static Future<void> verFerreteria(BuildContext context) =>
      _abrir(context, urlFerreteria);

  static Future<void> _abrir(BuildContext context, Uri url) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('No se pudo abrir Google Maps');
    } catch (_) {
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps en este dispositivo'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }
}
