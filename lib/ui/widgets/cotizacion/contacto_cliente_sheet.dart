import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/cotizacion.dart';
import '../../../providers/cliente_provider.dart';

/// Panel "Contactar cliente": datos del cliente de una cotizacion y accesos
/// directos para llamar, escribir por WhatsApp y abrir su direccion en
/// Google Maps.
class ContactoClienteSheet extends StatelessWidget {
  final String nombre;
  final String tipoDoc;
  final String documento;
  final String telefono;
  final String direccion;

  const ContactoClienteSheet._({
    required this.nombre,
    required this.tipoDoc,
    required this.documento,
    required this.telefono,
    required this.direccion,
  });

  static Future<void> mostrar(BuildContext context, Cotizacion c) {
    Cliente? cliente;
    for (final x in context.read<ClienteProvider>().clientes) {
      if ((c.clienteId.isNotEmpty && x.id == c.clienteId) ||
          x.nombre.trim().toLowerCase() == c.clienteNombre.trim().toLowerCase()) {
        cliente = x;
        break;
      }
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactoClienteSheet._(
        nombre: c.clienteNombre,
        tipoDoc: c.tipoDocumento.isNotEmpty
            ? c.tipoDocumento
            : (cliente?.tipoDocumento ?? 'DOC'),
        documento: c.documento.isNotEmpty ? c.documento : (cliente?.documento ?? ''),
        telefono: cliente?.telefono ?? '',
        direccion: cliente?.direccion ?? '',
      ),
    );
  }

  static String _digitos(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static Future<void> _abrir(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('No se pudo abrir la aplicación en este dispositivo'),
      ));
    }
  }

  Widget _fila(
    BuildContext context, {
    required IconData icono,
    required String etiqueta,
    required String valor,
    required int ms,
    List<Widget> acciones = const [],
  }) {
    final vacio = valor.isEmpty;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + ms),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icono, size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(vacio ? 'No registrado' : valor,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: vacio ? Colors.grey : null)),
                ],
              ),
            ),
            if (!vacio) ...acciones,
          ],
        ),
      ),
    );
  }

  Widget _accion(IconData icono, String tip, Color color, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Tooltip(
          message: tip,
          child: Material(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icono, color: color, size: 22),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final num = _digitos(telefono);
    final esCelular = num.length == 9 && num.startsWith('9');
    final conPais = num.length == 9 ? '51$num' : num;

    final acciones = <Widget>[
      _accion(Icons.call, 'Llamar', AppTheme.success,
          () => _abrir(context, Uri.parse('tel:$num'))),
      _accion(Icons.chat, 'WhatsApp', const Color(0xFF25D366),
          () => _abrir(context, Uri.parse('https://wa.me/$conPais'))),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppTheme.primary, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('CONTACTAR CLIENTE',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary)),
              const SizedBox(height: 6),
              const Divider(height: 14),
              _fila(context,
                  icono: Icons.person_outline,
                  etiqueta: 'NOMBRE',
                  valor: nombre,
                  ms: 0),
              _fila(context,
                  icono: Icons.badge_outlined,
                  etiqueta: tipoDoc.isEmpty ? 'DNI / RUC' : tipoDoc,
                  valor: documento,
                  ms: 60),
              _fila(context,
                  icono: Icons.phone_outlined,
                  etiqueta: 'TELÉFONO',
                  valor: esCelular ? '' : telefono,
                  ms: 120,
                  acciones: acciones),
              _fila(context,
                  icono: Icons.smartphone_outlined,
                  etiqueta: 'CELULAR',
                  valor: esCelular ? telefono : '',
                  ms: 180,
                  acciones: acciones),
              _fila(context,
                  icono: Icons.place_outlined,
                  etiqueta: 'DIRECCIÓN',
                  valor: direccion,
                  ms: 240,
                  acciones: [
                    _accion(
                      Icons.map_outlined,
                      'Abrir en Google Maps',
                      const Color(0xFF1A73E8),
                      () => _abrir(
                        context,
                        Uri.parse('https://www.google.com/maps/search/?api=1&query='
                            '${Uri.encodeComponent(direccion)}'),
                      ),
                    ),
                  ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
