import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/chips/selector_opciones.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/inputs/quantity_selector.dart';
import '../../widgets/layout/section_header.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';
import 'pago_screen.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  String? _clienteId;
  String _comprobante = AppConstants.comprobantes.first;

  void _error(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _irAPagar() {
    final clientes = context.read<ClienteProvider>().clientes;
    Cliente? cliente;
    if (_clienteId != null) {
      for (final c in clientes) {
        if (c.id == _clienteId) {
          cliente = c;
          break;
        }
      }
    }

    if (_comprobante == 'Factura' &&
        (cliente == null || cliente.tipoDocumento != 'RUC')) {
      _error('Para emitir una factura elige un cliente con RUC');
      return;
    }

    AppRoutes.push(
      context,
      PagoScreen(cliente: cliente, comprobante: _comprobante),
    ).then((_) {
      if (mounted && context.read<CarritoProvider>().vacio) {
        setState(() => _clienteId = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final clientes = context.watch<ClienteProvider>();
    final categorias = context.read<ProductoProvider>();
    final igv = carrito.subtotal * AppConstants.igv;
    final unidades = carrito.items.fold<int>(0, (a, i) => a + i.cantidad);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva venta'),
        actions: [
          if (!carrito.vacio)
            IconButton(
              tooltip: 'Vaciar carrito',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                ConfirmDialog.mostrar(
                  context,
                  titulo: 'Vaciar carrito',
                  mensaje: 'Se eliminaran todos los productos del carrito.',
                  textoConfirmar: 'Vaciar',
                  onConfirmar: () => carrito.limpiar(),
                );
              },
            ),
        ],
      ),
      body: carrito.vacio
          ? const EmptyState(
              icono: Icons.shopping_cart_outlined,
              titulo: 'Carrito vacio',
              mensaje: 'Agrega productos desde el catalogo para registrar '
                  'una nueva venta.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                // ------------------------------------------ detalle
                const SectionHeader(titulo: 'Detalle del pedido'),
                ...carrito.items.asMap().entries.map(
                      (e) => FadeSlide(
                        key: ValueKey(e.value.producto.id),
                        delay: Duration(milliseconds: e.key * 70),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LineaPedido(
                            item: e.value,
                            colorCategoria: categorias
                                .categoriaDe(e.value.producto.categoriaId)
                                .color,
                            onCambiarCantidad: (nueva) {
                              final error = carrito.actualizarCantidad(
                                  e.value.producto.id, nueva);
                              if (error != null) _error(error);
                            },
                            onEliminar: () =>
                                carrito.eliminar(e.value.producto.id),
                          ),
                        ),
                      ),
                    ),

                // ------------------------------------------ cliente
                const SectionHeader(titulo: 'Cliente'),
                DropdownButtonFormField<String>(
                  initialValue: _clienteId,
                  isExpanded: true,
                  hint: const Text('Publico en general'),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline)),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Publico en general')),
                    ...clientes.clientes.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.nombre}  (${c.tipoDocumento})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _clienteId = v),
                ),

                // ------------------------------------- comprobante
                const SectionHeader(titulo: 'Comprobante'),
                SelectorOpciones(
                  opciones: AppConstants.comprobantes,
                  seleccionado: _comprobante,
                  onSeleccionar: (v) => setState(() => _comprobante = v),
                  iconoDe: (c) => c == 'Factura'
                      ? Icons.request_quote_outlined
                      : Icons.receipt_outlined,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topLeft,
                  child: _comprobante == 'Factura'
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'La factura requiere un cliente con RUC.',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 22),

                // ---------------------------------- ticket de totales
                FadeSlide(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: const ShapeDecoration(
                      color: AppTheme.grafito,
                      shape: BeveledRectangleBorder(
                        borderRadius:
                            BorderRadius.only(bottomRight: Radius.circular(22)),
                      ),
                    ),
                    child: Column(
                      children: [
                        const FranjaPeligro(alto: 9),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: Column(
                            children: [
                              _FilaTotal('Articulos', '${carrito.items.length}'),
                              const SizedBox(height: 8),
                              _FilaTotal('Unidades llevadas', '$unidades'),
                              const SizedBox(height: 8),
                              _FilaTotal('Subtotal',
                                  Formatters.soles(carrito.subtotal)),
                              const SizedBox(height: 8),
                              _FilaTotal('IGV (18%)', Formatters.soles(igv)),
                              const SizedBox(height: 14),
                              const _LineaCorte(),
                              const SizedBox(height: 14),
                              _FilaTotal(
                                'Total para pagar',
                                Formatters.soles(carrito.subtotal + igv),
                                destacado: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedButton(
                  texto: 'Pagar ${Formatters.soles(carrito.subtotal + igv)}',
                  icono: Icons.payments_outlined,
                  ancho: double.infinity,
                  onPressed: _irAPagar,
                ),
              ],
            ),
    );
  }
}

/// Linea del pedido: muestra con claridad el precio por unidad, las
/// unidades llevadas y el importe de esa linea.
class _LineaPedido extends StatelessWidget {
  final ItemCarrito item;
  final Color colorCategoria;
  final Function(int) onCambiarCantidad;
  final VoidCallback onEliminar;

  const _LineaPedido({
    required this.item,
    required this.colorCategoria,
    required this.onCambiarCantidad,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.producto;
    final gris = Colors.grey.shade600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorCategoria.withOpacity(0.10),
                        colorCategoria.withOpacity(0.26),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ProductoIlustracion(
                    tipo: p.tipoVisual,
                    colorHex: p.colorHex,
                    size: 46,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.codigo}  -  ${p.unidad.toUpperCase()}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                            color: gris),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.danger,
                  tooltip: 'Quitar',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Desglose: unitario x cantidad = importe
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF12161A)
                    : const Color(0xFFF4F1EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRECIO UNIT.',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              letterSpacing: 1,
                              color: gris)),
                      Text(
                        Formatters.soles(p.precioVenta),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('x',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                  ),
                  QuantitySelector(
                    valor: item.cantidad,
                    maximo: p.stock,
                    onCambio: onCambiarCantidad,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('IMPORTE',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              letterSpacing: 1,
                              color: gris)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0, 0.4),
                                    end: Offset.zero)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          Formatters.soles(item.subtotal),
                          key: ValueKey(item.subtotal),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.primary
                                    : const Color(0xFFD95800),
                          ),
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
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaTotal(this.etiqueta, this.valor, {this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: destacado ? 13 : 11.5,
            letterSpacing: 1.4,
            fontWeight: destacado ? FontWeight.w900 : FontWeight.w600,
            color: destacado ? AppTheme.hueso : const Color(0x99EDE8DF),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.4), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Text(
            valor,
            key: ValueKey(valor),
            style: TextStyle(
              fontSize: destacado ? 28 : 15,
              fontWeight: FontWeight.w900,
              letterSpacing: destacado ? -0.5 : 0,
              color: destacado ? AppTheme.primary : AppTheme.hueso,
            ),
          ),
        ),
      ],
    );
  }
}

/// Linea punteada de corte del ticket.
class _LineaCorte extends StatelessWidget {
  const _LineaCorte();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 9).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(
                width: 5, height: 1.6, color: const Color(0xFF4A535B)),
          ),
        );
      },
    );
  }
}
