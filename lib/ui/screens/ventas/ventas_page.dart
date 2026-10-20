import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/venta.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/visual/tilt_3d.dart';
import 'venta_detalle_screen.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  String _filtro = 'Todas';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentaProvider>();
    final filtros = ['Todas', ...AppConstants.metodosPago];
    final lista = _filtro == 'Todas'
        ? provider.ventas
        : provider.ventas.where((v) => v.metodoPago == _filtro).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de ventas')),
      body: provider.ventas.isEmpty
          ? const EmptyState(
              icono: Icons.receipt_long_outlined,
              titulo: 'Sin ventas registradas',
              mensaje:
                  'Las ventas que registres desde el carrito apareceran aqui.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                FadeSlide(
                  child: SizedBox(
                    height: 84,
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            titulo: 'Ventas',
                            valor: provider.totalVentas.toDouble(),
                            icono: Icons.receipt_long_outlined,
                            color: const Color(0xFF0277BD),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            titulo: 'Hoy',
                            valor: provider.totalHoy,
                            prefijo: 'S/ ',
                            esMoneda: true,
                            icono: Icons.today_outlined,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filtros.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _ChipFiltro(
                      texto: filtros[i],
                      activo: filtros[i] == _filtro,
                      onTap: () => setState(() => _filtro = filtros[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (lista.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Sin ventas con $_filtro',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ...lista.asMap().entries.map(
                        (e) => FadeSlide(
                          key: ValueKey('${_filtro}_${e.value.id}'),
                          delay: Duration(
                              milliseconds: e.key < 8 ? e.key * 70 : 0),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _Ticket(
                              venta: e.value,
                              onTap: () => AppRoutes.push(
                                context,
                                VentaDetalleScreen(ventaId: e.value.id),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activo ? AppTheme.grafito : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo
                ? AppTheme.grafito
                : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
        ),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: activo
                ? AppTheme.primary
                : (oscuro ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

/// Venta presentada como un ticket de caja: datos a la izquierda, linea
/// punteada de corte y total a la derecha.
class _Ticket extends StatelessWidget {
  final Venta venta;
  final VoidCallback onTap;

  const _Ticket({required this.venta, required this.onTap});

  IconData _iconoPago(String metodo) {
    switch (metodo) {
      case 'Yape':
        return Icons.phone_iphone;
      case 'Plin':
        return Icons.smartphone;
      case 'Tarjeta':
        return Icons.credit_card;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final acento = venta.comprobante == 'Factura'
        ? const Color(0xFF0277BD)
        : AppTheme.success;

    return Tilt3D(
      anguloMax: 0.07,
      radioBorde: 14,
      builder: (context, t) => Card(
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: acento),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venta.clienteNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${venta.numero}  -  ${venta.comprobante.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: acento,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.fecha(venta.fecha),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 2,
                  child: CustomPaint(
                    painter: _CortePainter(
                      oscuro ? AppTheme.bordeOscuro : const Color(0xFFC9C2B5),
                    ),
                  ),
                ),
                Container(
                  width: 112,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Formatters.soles(venta.total),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconoPago(venta.metodoPago),
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            venta.metodoPago.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CortePainter extends CustomPainter {
  final Color color;

  _CortePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    const trazo = 5.0;
    const hueco = 4.0;
    for (var y = 6.0; y < size.height - 6; y += trazo + hueco) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, math.min(y + trazo, size.height - 6)), p);
    }
  }

  @override
  bool shouldRepaint(_CortePainter old) => old.color != color;
}
