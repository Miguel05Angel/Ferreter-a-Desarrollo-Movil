import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Llamadas y mensajes de WhatsApp a proveedores o al administrador.
class ContactoService {
  ContactoService._();

  /// Pasa un celular peruano de 9 digitos a formato internacional (51...).
  static String _internacional(String telefono) {
    final d = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length == 9 ? '51$d' : d;
  }

  static Future<void> whatsapp(
      BuildContext context, String telefono, String mensaje) {
    final url = Uri.parse(
        'https://wa.me/${_internacional(telefono)}?text=${Uri.encodeComponent(mensaje)}');
    return _abrir(context, url, 'WhatsApp');
  }

  static Future<void> llamar(BuildContext context, String telefono) {
    final numero = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    return _abrir(context, Uri(scheme: 'tel', path: numero), 'el telefono');
  }

  static Future<void> _abrir(BuildContext context, Uri url, String app) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('no se pudo abrir');
    } catch (_) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir $app en este dispositivo'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }
}
