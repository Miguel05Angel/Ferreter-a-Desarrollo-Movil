import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/inputs/quantity_selector.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';
import '../../widgets/visual/visor_3d.dart';
import 'producto_form_screen.dart';

/// Detalle del producto: toda la pantalla es un escenario oscuro con el
/// producto girando en 3D. La informacion va en un panel inferior y la
/// accion de agregar queda siempre visible.
class ProductoDetalleScreen extends StatefulWidget {
  final String productoId;
  const ProductoDetalleScreen({super.key, required this.productoId});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen>
    with SingleTickerProviderStateMixin {
  late final ThemeData _tema = AppTheme.dark;
  late final AnimationController _deriva;
  final GlobalKey _llaveVisor = GlobalKey();

  int _cantidad = 1;
  int _colorSeleccionado = 0;

  @override
  void initState() {
    super.initState();
    _deriva = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _deriva.dispose();
    super.dispose();
  }

  void _agregar(Producto producto, int colorHex) {
    final error =
        context.read<CarritoProvider>().agregar(producto, _cantidad);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.danger),
      );
      return;
    }

    // El producto sale del visor y vuela hasta el carrito flotante
    Offset desde = Offset(MediaQuery.of(context).size.width / 2, 260);
    final caja = _llaveVisor.currentContext?.findRenderObject();
    if (caja is RenderBox && caja.hasSize) {
      desde = caja.localToGlobal(caja.size.center(Offset.zero));
    }
    VueloAlCarrito.lanzar(
      context,
      tipo: producto.tipoVisual,
      colorHex: colorHex,
      desde: desde,
      tam: 150,
    );
    setState(() => _cantidad = 1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final producto = provider.buscarPorId(widget.productoId);

    if (producto == null) {
      return Theme(
        data: _tema,
        child: Scaffold(
          appBar: AppBar(title: const Text('Producto')),
          body: const Center(child: Text('El producto ya no existe.')),
        ),
      );
    }

    final categoria = provider.categoriaDe(producto.categoriaId);
    final colores = producto.coloresHex.isNotEmpty
        ? producto.coloresHex
        : [producto.colorHex];
    final colorActual = _colorSeleccionado < colores.length
        ? colores[_colorSeleccionado]
        : colores.first;
    final stockColor = producto.agotado
        ? const Color(0xFFFF6E6E)
        : (producto.stockBajo
            ? AppTheme.amarilloSenal
            : const Color(0xFF66BB6A));
    final alto = MediaQuery.of(context).size.height;
    final altoVisor = (alto * 0.36).clamp(220.0, 310.0).toDouble();

    return Theme(
      data: _tema,
      child: Scaffold(
        backgroundColor: AppTheme.grafito,
        body: Stack(
          children: [
            // ---------------------------------------------- escenario
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.45),
                    radius: 1.15,
                    colors: [
                      Color.lerp(AppTheme.grafito, categoria.color, 0.5)!,
                      AppTheme.grafito,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: PlanoPainter())),
            // Nombre de la categoria gigante que se desplaza lentamente
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _deriva,
                  builder: (context, _) => Transform.translate(
                    offset: Offset(
                        -Curves.easeInOut.transform(_deriva.value) * 420, 0),
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 96, left: 16),
                        child: Text(
                          '${categoria.nombre.toUpperCase()}  ' * 3,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 128,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -4,
                            color: Colors.white.withOpacity(0.045),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ------------------------------------------- barra
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppTheme.hueso,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            producto.codigo,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: AppTheme.hueso,
                          onPressed: () => AppRoutes.push(
                            context,
                            ProductoFormScreen(producto: producto),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: AppTheme.hueso,
                          onPressed: () {
                            ConfirmDialog.mostrar(
                              context,
                              titulo: 'Eliminar producto',
                              mensaje:
                                  '¿Estas seguro de eliminar "${producto.nombre}"? Esta accion no se puede deshacer.',
                              textoConfirmar: 'Eliminar',
                              onConfirmar: () {
                                context
                                    .read<ProductoProvider>()
                                    .eliminar(producto.id);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Producto eliminado'),
                                    backgroundColor: Color(0xFF2E7D32),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ------------------------------------- visor 3D
                  SizedBox(
                    height: altoVisor,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Hero(
                          tag: 'producto-${producto.id}',
                          flightShuttleBuilder: (_, __, ___, ____, _____) =>
                              FittedBox(
                            child: ProductoEstatico(
                              tipo: producto.tipoVisual,
                              colorHex: colorActual,
                              size: 100,
                              sombra: true,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: _llaveVisor,
                            child: Visor3D(
                              tipo: producto.tipoVisual,
                              colorHex: colorActual,
                              size: 190,
                              acento: Color.lerp(
                                  categoria.color, Colors.white, 0.35)!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -------------------------------------- panel
                  Expanded(
                    child: FadeSlide(
                      inicio: const Offset(0, 0.5),
                      delay: const Duration(milliseconds: 150),
                      child: Container(
                        width: double.infinity,
                        decoration: const ShapeDecoration(
                          color: Color(0xF0171B1F),
                          shape: BeveledRectangleBorder(
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(30)),
                            side: BorderSide(color: AppTheme.bordeOscuro),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 22, 22, 8),
                                child: _Info(
                                  producto: producto,
                                  categoriaNombre: categoria.nombre,
                                  categoriaColor: categoria.color,
                                  stockColor: stockColor,
                                  colores: colores,
                                  colorSeleccionado: _colorSeleccionado,
                                  onColor: (i) =>
                                      setState(() => _colorSeleccionado = i),
                                ),
                              ),
                            ),
                            _BarraAgregar(
                              producto: producto,
                              cantidad: _cantidad,
                              onCantidad: (v) =>
                                  setState(() => _cantidad = v),
                              onAgregar: () => _agregar(producto, colorActual),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _Info extends StatelessWidget {
  final Producto producto;
  final String categoriaNombre;
  final Color categoriaColor;
  final Color stockColor;
  final List<int> colores;
  final int colorSeleccionado;
  final ValueChanged<int> onColor;

  const _Info({
    required this.producto,
    required this.categoriaNombre,
    required this.categoriaColor,
    required this.stockColor,
    required this.colores,
    required this.colorSeleccionado,
    required this.onColor,
  });

  Widget _chip(String texto, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final claro = Color.lerp(categoriaColor, Colors.white, 0.45)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(categoriaNombre, claro),
            _chip(
              producto.agotado ? 'Agotado' : '${producto.stock} en stock',
              stockColor,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          producto.nombre,
          style: const TextStyle(
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: AppTheme.hueso,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'MARCA ${producto.marca.toUpperCase()}   -   VENTA POR ${producto.unidad.toUpperCase()}',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1,
            color: Color(0x99EDE8DF),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          producto.descripcion,
          style: const TextStyle(
              fontSize: 14.5, height: 1.5, color: Color(0xCCEDE8DF)),
        ),

        if (producto.esPintura) ...[
          const SizedBox(height: 20),
          const Text(
            'ELIGE TU COLOR',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: Color(0x99EDE8DF),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: colores.asMap().entries.map((e) {
              final activo = colorSeleccionado == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onColor(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.all(4),
                    transform: Matrix4.translationValues(0, activo ? -4 : 0, 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activo ? AppTheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(e.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(e.value).withOpacity(0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: activo
                          ? const Icon(Icons.check,
                              color: Colors.white70, size: 18)
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRECIO DE VENTA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.6,
                      color: Color(0x99EDE8DF),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.soles(producto.precioVenta),
                      style: const TextStyle(
                        fontSize: 38,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (producto.precioCompra > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'COMPRA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.6,
                      color: Color(0x99EDE8DF),
                    ),
                  ),
                  Text(
                    Formatters.soles(producto.precioCompra),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xCCEDE8DF),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _BarraAgregar extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final ValueChanged<int> onCantidad;
  final VoidCallback onAgregar;

  const _BarraAgregar({
    required this.producto,
    required this.cantidad,
    required this.onCantidad,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppTheme.grafito,
        border: Border(top: BorderSide(color: AppTheme.bordeOscuro)),
      ),
      child: producto.agotado
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Producto agotado. Repon el stock para poder venderlo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFFF6E6E), fontWeight: FontWeight.w700),
              ),
            )
          : Row(
              children: [
                QuantitySelector(
                  valor: cantidad,
                  maximo: producto.stock,
                  onCambio: onCantidad,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedButton(
                    texto:
                        'Agregar ${Formatters.soles(producto.precioVenta * cantidad)}',
                    icono: Icons.add_shopping_cart,
                    ancho: double.infinity,
                    onPressed: onAgregar,
                  ),
                ),
              ],
            ),
    );
  }
}
