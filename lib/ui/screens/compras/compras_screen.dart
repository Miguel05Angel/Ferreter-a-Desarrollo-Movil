import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/solicitud_cotizacion.dart';
import '../../../providers/compra_provider.dart';
import '../../../services/compra_exportador.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/appbar_taller.dart';
import 'solicitud_detalle_screen.dart';

/// Solicitudes de cotizacion y ordenes de compra a proveedores.
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  EstadoCompra? _filtro;

  @override
  Widget build(BuildContext context) {
    if (!Permisos.de(context).puedeSolicitarReposicion) {
      return const AccesoRestringido(
        titulo: 'Compras',
        detalle: 'Las compras a proveedores son solo para el Administrador.',
      );
    }
    final prov = context.watch<CompraProvider>();
    final lista =
        prov.solicitudes.where((s) => _filtro == null || s.estado == _filtro).toList();

    return Scaffold(
      appBar: const AppBarTaller(
        mostrarCarrito: false,
        subtitulo: 'Cotizaciones y ordenes',
        title: Text('Compras'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              children: [
                _Chip('Todas', prov.solicitudes.length, _filtro == null,
                    () => setState(() => _filtro = null)),
                for (final e in EstadoCompra.values)
                  _Chip(e.texto, prov.contar(e), _filtro == e,
                      () => setState(() => _filtro = e)),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? const EmptyState(
                    icono: Icons.request_quote_outlined,
                    titulo: 'Sin solicitudes',
                    mensaje:
                        'Cuando un producto este por agotarse, solicita su reposicion desde las alertas de stock.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => FadeSlide(
                      delay: Duration(milliseconds: i < 8 ? i * 70 : 0),
                      child: _Tarjeta(
                        s: lista[i],
                        onTap: () => AppRoutes.push(
                          context,
                          SolicitudDetalleScreen(solicitudId: lista[i].id),
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

class _Chip extends StatelessWidget {
  final String texto;
  final int cantidad;
  final bool activo;
  final VoidCallback onTap;

  const _Chip(this.texto, this.cantidad, this.activo, this.onTap);

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
            '${texto.toUpperCase()}  $cantidad',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: activo ? AppTheme.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final SolicitudCotizacion s;
  final VoidCallback onTap;

  const _Tarjeta({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, icono) = switch (s.estado) {
      EstadoCompra.solicitada => (AppTheme.amarilloSenal, Icons.hourglass_top),
      EstadoCompra.cotizada => (const Color(0xFF64B5F6), Icons.price_check),
      EstadoCompra.ordenada =>
        (const Color(0xFF66BB6A), Icons.assignment_turned_in_outlined),
    };
    final total = s.cotizacion?.total(s.cantidad);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BeveledRectangleBorder(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(14)),
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.ordenNumero ?? s.numero,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${s.cantidad} ${s.unidad} - ${s.descripcion}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.proveedorNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.estado.texto.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total != null
                          ? Formatters.soles(total)
                          : CompraExportador.fecha(s.fecha),
                      style: TextStyle(
                        fontFamily: total != null ? null : 'monospace',
                        fontSize: total != null ? 14 : 10.5,
                        fontWeight: FontWeight.w900,
                        color: total != null ? null : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
