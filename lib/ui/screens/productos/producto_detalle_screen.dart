import 'package:flutter/material.dart';

import '../../widgets/layout/appbar_taller.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/recomendador.dart';
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
import '../../widgets/media/escenario_producto.dart';
import '../../../providers/media_provider.dart';
import '../../widgets/visual/tilt_3d.dart';
import '../main/main_shell_screen.dart';
import 'producto_form_screen.dart';
import 'reposicion_screen.dart';

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

  void _agregar(Producto producto, int colorHex, int cantidad) {
    final error =
        context.read<CarritoProvider>().agregar(producto, cantidad);
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
      imagenUrl: context.read<MediaProvider>().miniatura(producto.codigo),
    );
    setState(() => _cantidad = 1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final permisos = Permisos.de(context);
    final carrito = context.watch<CarritoProvider>();
    final producto = provider.buscarPorId(widget.productoId);

    if (producto == null) {
      return Theme(
        data: _tema,
        child: Scaffold(
          appBar: AppBarTaller(title: const Text('Producto')),
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
    final recomendaciones = Recomendador.para(producto, provider.productos);

    // Unidades de este producto que ya estan separadas en el carrito
    final enCarrito = carrito.items
        .where((i) => i.producto.id == producto.id)
        .fold<int>(0, (a, i) => a + i.cantidad);
    final disponible =
        (producto.stock - enCarrito).clamp(0, producto.stock).toInt();
    final cantidad =
        disponible == 0 ? 1 : _cantidad.clamp(1, disponible).toInt();
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
                        const BotonCarrito(),
                        if (permisos.puedeGestionarProductos) ...[
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
                      ],
                    ),
                  ),

                  // ------------------------- escenario (3D / 360 / fotos)
                  SizedBox(
                    height: altoVisor,
                    child: KeyedSubtree(
                      key: _llaveVisor,
                      child: EscenarioProducto(
                        producto: producto,
                        colorHex: colorActual,
                        acento: Color.lerp(
                            categoria.color, Colors.white, 0.35)!,
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
                                  puedeVerCostos: permisos.puedeVerCostos,
                                  disponible: disponible,
                                  enCarrito: enCarrito,
                                  puedeReponer: permisos.puedeSolicitarReposicion,
                                  onReponer: () => AppRoutes.push(
                                    context,
                                    ReposicionScreen(productoId: producto.id),
                                  ),
                                  recomendaciones: recomendaciones,
                                  onAbrir: (p) => AppRoutes.push(
                                    context,
                                    ProductoDetalleScreen(productoId: p.id),
                                  ),
                                ),
                              ),
                            ),
                            _BarraAgregar(
                              producto: producto,
                              cantidad: cantidad,
                              disponible: disponible,
                              enCarrito: enCarrito,
                              onCantidad: (v) =>
                                  setState(() => _cantidad = v),
                              onAgregar: () =>
                                  _agregar(producto, colorActual, cantidad),
                              onIrAlCarrito: () {
                                Navigator.of(context)
                                    .popUntil((r) => r.isFirst);
                                ShellNavegacion.irA(3);
                              },
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
  final bool puedeVerCostos;
  final int disponible;
  final int enCarrito;
  final bool puedeReponer;
  final VoidCallback onReponer;
  final List<Recomendacion> recomendaciones;
  final ValueChanged<Producto> onAbrir;

  const _Info({
    required this.producto,
    required this.categoriaNombre,
    required this.categoriaColor,
    required this.stockColor,
    required this.colores,
    required this.colorSeleccionado,
    required this.onColor,
    required this.puedeVerCostos,
    required this.disponible,
    required this.enCarrito,
    required this.puedeReponer,
    required this.onReponer,
    required this.recomendaciones,
    required this.onAbrir,
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
              producto.agotado
                  ? 'Agotado'
                  : (enCarrito > 0
                      ? '$disponible disponibles'
                      : '${producto.stock} en stock'),
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
            if (puedeVerCostos && producto.precioCompra > 0)
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
        const SizedBox(height: 26),
        const _EtiquetaSeccion('FICHA DEL PRODUCTO'),
        const SizedBox(height: 10),
        _TarjetaDisponibilidad(
          producto: producto,
          disponible: disponible,
          enCarrito: enCarrito,
          colorEstado: stockColor,
          puedeReponer: puedeReponer,
          onReponer: onReponer,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TileDato(
                etiqueta: 'MARCA',
                valor: producto.marca,
                sub: 'FABRICANTE',
                color: AppTheme.hueso,
                progreso: 1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TileDato(
                etiqueta: 'SE VENDE POR',
                valor: producto.unidad,
                sub: 'UNIDAD DE VENTA',
                color: const Color(0xFF64B5F6),
                progreso: 1,
              ),
            ),
          ],
        ),
        if (puedeVerCostos && producto.precioCompra > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF241D12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x66FFC400)),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 20, color: AppTheme.amarilloSenal),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SOLO ADMINISTRADOR',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.amarilloSenal,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'GANANCIA ${Formatters.soles(producto.precioVenta - producto.precioCompra)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.hueso,
                      ),
                    ),
                    Text(
                      '${((producto.precioVenta - producto.precioCompra) / producto.precioVenta * 100).toStringAsFixed(0)}% DE MARGEN',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: Color(0x99EDE8DF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (recomendaciones.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _EtiquetaSeccion('TE RECOMENDAMOS'),
          const SizedBox(height: 4),
          Text(
            'LO QUE NECESITAS JUNTO CON ${producto.nombre.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              letterSpacing: 1,
              color: Color(0x80EDE8DF),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: recomendaciones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => FadeSlide(
                delay: Duration(milliseconds: 250 + i * 80),
                inicio: const Offset(0.3, 0),
                child: _TarjetaRecomendada(
                  recomendacion: recomendaciones[i],
                  color: categoriaColor,
                  onTap: () => onAbrir(recomendaciones[i].producto),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Disponibilidad del producto. Las unidades que ya estan en el carrito se
/// descuentan con una animacion y el numero restante se muestra en gris
/// (plomo): estan separadas, pero la compra aun no se finaliza.
class _TarjetaDisponibilidad extends StatelessWidget {
  final Producto producto;
  final int disponible;
  final int enCarrito;
  final Color colorEstado;
  final bool puedeReponer;
  final VoidCallback onReponer;

  const _TarjetaDisponibilidad({
    required this.producto,
    required this.disponible,
    required this.enCarrito,
    required this.colorEstado,
    required this.puedeReponer,
    required this.onReponer,
  });

  static const Color _plomo = Color(0xFF9AA3AB);

  @override
  Widget build(BuildContext context) {
    final reservado = enCarrito > 0;
    final bajo = producto.stockBajo || producto.agotado;
    final total = producto.stock <= 0 ? 1 : producto.stock;
    final tope = total < 20 ? 20 : total; // escala de la barra

    final colorNumero = reservado ? _plomo : colorEstado;
    String estado;
    if (producto.agotado) {
      estado = 'AGOTADO';
    } else if (disponible == 0) {
      estado = 'TODO EN TU CARRITO';
    } else if (producto.stockBajo) {
      estado = 'STOCK BAJO';
    } else {
      estado = 'DISPONIBLE';
    }
    final colorChip = disponible == 0 && !producto.agotado ? _plomo : colorEstado;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2226),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 22, color: colorChip),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'DISPONIBILIDAD',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0x99EDE8DF),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorChip.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorChip.withOpacity(0.6)),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    color: colorChip,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // El numero baja con una animacion al separar unidades
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: disponible.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: TextStyle(
                    fontSize: 40,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: colorNumero,
                  ),
                  child: Text('${v.round()}'),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  producto.unidad.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 1.4,
                    color: Color(0x99EDE8DF),
                  ),
                ),
              ),
              const Spacer(),
              if (reservado)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 15, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        '$enCarrito EN TU CARRITO',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra: disponibles (color), separadas (plomo) y vendidas (fondo)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: disponible / tope),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, dispo, _) => TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: (disponible + enCarrito) / tope),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, hasta, __) => LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Container(color: const Color(0xFF2E353B)),
                        Container(
                          width: c.maxWidth * hasta.clamp(0.0, 1.0),
                          color: _plomo.withOpacity(0.55),
                        ),
                        Container(
                          width: c.maxWidth * dispo.clamp(0.0, 1.0),
                          color: reservado ? _plomo : colorEstado,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              reservado
                  ? 'Unidades separadas en tu carrito. Se liberan si quitas el producto; el stock se descuenta al finalizar la venta.'
                  : (producto.agotado
                      ? 'No hay unidades para vender.'
                      : (producto.stockBajo
                          ? 'Quedan pocas unidades, conviene reponer.'
                          : 'Stock suficiente para vender.')),
              key: ValueKey('$reservado-${producto.stockBajo}-${producto.agotado}'),
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: Color(0xB3EDE8DF)),
            ),
          ),
          if (bajo) ...[
            const SizedBox(height: 12),
            if (puedeReponer)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.8),
                  ),
                  onPressed: onReponer,
                  icon: const Icon(Icons.local_shipping_outlined, size: 19),
                  label: const Text('SOLICITAR REPOSICION DE STOCK'),
                ),
              )
            else
              const Text(
                'AVISA AL ADMINISTRADOR PARA SOLICITAR LA REPOSICION',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                  color: Color(0x80EDE8DF),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  final String texto;

  const _EtiquetaSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 14, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: AppTheme.hueso,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(height: 1, color: AppTheme.bordeOscuro),
        ),
      ],
    );
  }
}

class _TileDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String sub;
  final Color color;
  final double progreso;

  const _TileDato({
    required this.etiqueta,
    required this.valor,
    required this.sub,
    required this.color,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Color(0x99EDE8DF),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progreso),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: const Color(0xFF2E353B),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              letterSpacing: 0.8,
              color: Color(0x80EDE8DF),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRecomendada extends StatelessWidget {
  final Recomendacion recomendacion;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaRecomendada({
    required this.recomendacion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final producto = recomendacion.producto;
    return SizedBox(
      width: 140,
      child: Tilt3D(
        anguloMax: 0.18,
        radioBorde: 14,
        builder: (context, t) => Material(
          color: const Color(0xFF1D2226),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.bordeOscuro),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 94,
                  width: double.infinity,
                  color: color.withOpacity(0.16),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recomendacion.motivo.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.grafito,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: Offset(t.dx * -7, t.dy * -7 + 6),
                          child: ProductoEstatico(
                            tipo: producto.tipoVisual,
                            colorHex: producto.colorHex,
                            size: 66,
                            sombra: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.hueso,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.soles(producto.precioVenta),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
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

class _BarraAgregar extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final int disponible;
  final int enCarrito;
  final ValueChanged<int> onCantidad;
  final VoidCallback onAgregar;
  final VoidCallback onIrAlCarrito;

  const _BarraAgregar({
    required this.producto,
    required this.cantidad,
    required this.disponible,
    required this.enCarrito,
    required this.onCantidad,
    required this.onAgregar,
    required this.onIrAlCarrito,
  });

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    if (producto.agotado) {
      contenido = Container(
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
      );
    } else if (disponible == 0) {
      // Todas las unidades ya estan separadas en el carrito
      contenido = Row(
        children: [
          Expanded(
            child: Text(
              'Las $enCarrito unidades ya estan en tu carrito.',
              style: const TextStyle(
                  fontSize: 13, height: 1.3, color: Color(0xCCEDE8DF)),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedButton(
            texto: 'Ir al carrito',
            icono: Icons.shopping_cart_outlined,
            onPressed: onIrAlCarrito,
            ancho: 170,
          ),
        ],
      );
    } else {
      contenido = Row(
        children: [
          QuantitySelector(
            valor: cantidad,
            maximo: disponible,
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
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: AppTheme.grafito,
        border: Border(top: BorderSide(color: AppTheme.bordeOscuro)),
      ),
      child: contenido,
    );
  }
}
