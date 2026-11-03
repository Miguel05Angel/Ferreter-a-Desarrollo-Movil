import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../screens/clientes/cliente_form_screen.dart';

/// Perfil completo del cliente en una hoja modal: datos de contacto y su
/// historial con la ferreteria (cotizaciones y compras).
class PerfilClienteSheet extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback? onUsar;
  final int cotizaciones;
  final double totalCotizado;
  final int compras;
  final double totalComprado;

  const PerfilClienteSheet._({
    required this.cliente,
    required this.onUsar,
    required this.cotizaciones,
    required this.totalCotizado,
    required this.compras,
    required this.totalComprado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required Cliente cliente,
    VoidCallback? onUsar,
  }) {
    final nombre = cliente.nombre.trim().toLowerCase();
    final cots = context.read<CotizacionProvider>().cotizaciones.where((c) =>
        (c.clienteId.isNotEmpty && c.clienteId == cliente.id) ||
        c.clienteNombre.trim().toLowerCase() == nombre);
    final ventas = context
        .read<VentaProvider>()
        .ventas
        .where((v) => v.clienteNombre.trim().toLowerCase() == nombre);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PerfilClienteSheet._(
        cliente: cliente,
        onUsar: onUsar,
        cotizaciones: cots.length,
        totalCotizado: cots.fold(0.0, (s, c) => s + c.total),
        compras: ventas.length,
        totalComprado: ventas.fold(0.0, (s, v) => s + v.total),
      ),
    );
  }

  Widget _fila(IconData icono, String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 19, color: AppTheme.primary),
            const SizedBox(width: 12),
            SizedBox(
              width: 86,
              child: Text(etiqueta,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                      color: Colors.grey.shade600)),
            ),
            Expanded(
              child: Text(valor.isEmpty ? 'No registrado' : valor,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: valor.isEmpty ? Colors.grey : null)),
            ),
          ],
        ),
      );

  Widget _caja(String titulo, int n, double total, IconData icono, int ms) =>
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + ms),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 20, color: AppTheme.primary),
                const SizedBox(height: 6),
                Text('$n', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(titulo, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(Formatters.soles(total),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final esRuc = cliente.tipoDocumento == 'RUC';
    final color = esRuc ? const Color(0xFF0277BD) : AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppTheme.primary, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: color.withOpacity(0.14),
                      shape: BeveledRectangleBorder(
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(18)),
                        side: BorderSide(color: color.withOpacity(0.55)),
                      ),
                    ),
                    child: Text(cliente.nombre.isEmpty ? '?' : cliente.nombre[0].toUpperCase(),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente.nombre,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.15)),
                        const SizedBox(height: 4),
                        Text('${cliente.tipoDocumento}  ${cliente.documento}',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w900,
                                color: color)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              _fila(Icons.phone_outlined, 'TELÉFONO', cliente.telefono),
              _fila(Icons.place_outlined, 'DIRECCIÓN', cliente.direccion),
              _fila(Icons.mail_outline, 'CORREO', cliente.email),
              _fila(Icons.account_balance_wallet_outlined, 'CRÉDITO',
                  cliente.credito ? 'Habilitado' : 'Sin crédito'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _caja('Cotizaciones', cotizaciones, totalCotizado, Icons.request_quote_outlined, 0),
                  const SizedBox(width: 12),
                  _caja('Compras', compras, totalComprado, Icons.receipt_long_outlined, 120),
                ],
              ),
              const SizedBox(height: 18),
              if (onUsar != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onUsar!();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('USAR EN ESTA COTIZACIÓN'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              if (onUsar != null) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppRoutes.push(context, ClienteFormScreen(cliente: cliente));
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('EDITAR CLIENTE'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
