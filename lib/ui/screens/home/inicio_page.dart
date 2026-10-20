import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/categoria.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/venta.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/cards/category_card.dart';
import '../../widgets/layout/section_header.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';
import '../../widgets/visual/tilt_3d.dart';
import '../categorias/categorias_screen.dart';
import '../clientes/clientes_page.dart';
import '../cotizaciones/cotizaciones_page.dart';
import '../main/main_shell_screen.dart';
import '../productos/producto_detalle_screen.dart';
import '../proveedores/proveedores_page.dart';
import '../ventas/venta_detalle_screen.dart';

Color _naranjaTexto(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppTheme.primary
        : const Color(0xFFD95800);

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'BUENOS DIAS';
    if (h < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  /// Un producto por tipo de ilustracion, para que el carrusel sea variado.
  List<Producto> _destacados(List<Producto> todos) {
    final vistos = <String>{};
    final res = <Producto>[];
    for (final p in todos) {
      if (p.agotado) continue;
      if (vistos.add(p.tipoVisual)) res.add(p);
      if (res.length == 8) break;
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductoProvider>();
    final clientes = context.watch<ClienteProvider>();
    final ventas = context.watch<VentaProvider>();
    final usuario = context.watch<AuthProvider>().usuarioActual;

    final stockBajo = productos.productos.where((p) => p.stock <= 5).toList();
    final destacados = _destacados(productos.productos);
    final nombre = usuario?.nombre.split(' ').first ?? 'Invitado';
    final inicial = (usuario?.nombre.isNotEmpty ?? false)
        ? usuario!.nombre[0].toUpperCase()
        : '?';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ================================================ cabecera
          Container(
            color: AppTheme.grafito,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: PlanoPainter()),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FadeSlide(
                      inicio: const Offset(0, -0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _saludo(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        text: nombre,
                                        children: const [
                                          TextSpan(
                                            text: '.',
                                            style: TextStyle(
                                                color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        height: 1.05,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                        color: AppTheme.hueso,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: const ShapeDecoration(
                                  color: AppTheme.primary,
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(16)),
                                  ),
                                ),
                                child: Text(
                                  inicial,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.grafito,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Tablero del dia
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const _Mono('VENTAS DE HOY',
                                          Color(0x99EDE8DF)),
                                      const SizedBox(height: 4),
                                      TweenAnimationBuilder<double>(
                                        tween:
                                            Tween(begin: 0, end: ventas.totalHoy),
                                        duration:
                                            const Duration(milliseconds: 1500),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            Formatters.soles(v),
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  color: const Color(0xFF3A4148),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _MiniDato(
                                          valor: productos.totalProductos,
                                          etiqueta: 'PRODUCTOS'),
                                      const SizedBox(height: 7),
                                      _MiniDato(
                                          valor: clientes.totalClientes,
                                          etiqueta: 'CLIENTES'),
                                      const SizedBox(height: 7),
                                      _MiniDato(
                                          valor: productos.productosStockBajo,
                                          etiqueta: 'STOCK BAJO',
                                          alerta: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const FranjaPeligro(alto: 9),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================ destacados
                if (destacados.isNotEmpty) ...[
                  SectionHeader(
                    titulo: 'Destacados',
                    textoAccion: 'Ver todo',
                    onAccion: () => ShellNavegacion.irA(1),
                  ),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: destacados.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final p = destacados[i];
                        return FadeSlide(
                          delay: Duration(milliseconds: 200 + i * 90),
                          inicio: const Offset(0.35, 0),
                          child: _TarjetaDestacado(
                            producto: p,
                            categoria: productos.categoriaDe(p.categoriaId),
                            onTap: () => AppRoutes.push(
                              context,
                              ProductoDetalleScreen(productoId: p.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // ============================================ categorias
                SectionHeader(
                  titulo: 'Categorias',
                  textoAccion: 'Ver todo',
                  onAccion: () =>
                      AppRoutes.push(context, const CategoriasScreen()),
                ),
                SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 4),
                    itemCount: productos.categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final Categoria c = productos.categorias[i];
                      return FadeSlide(
                        delay: Duration(milliseconds: 100 + i * 70),
                        inicio: const Offset(0.3, 0),
                        child: CategoryCard(
                          categoria: c,
                          cantidad: productos.productos
                              .where((p) => p.categoriaId == c.id)
                              .length,
                          onTap: () => AppRoutes.push(
                              context, const CategoriasScreen()),
                        ),
                      );
                    },
                  ),
                ),

                // ======================================= accesos rapidos
                const SectionHeader(titulo: 'Accesos rapidos'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: [
                    _Acceso(
                      icono: Icons.point_of_sale,
                      texto: 'Nueva venta',
                      destacado: true,
                      color: AppTheme.primary,
                      onTap: () => ShellNavegacion.irA(3),
                    ),
                    _Acceso(
                      icono: Icons.people_alt_outlined,
                      texto: 'Clientes',
                      color: const Color(0xFF546E7A),
                      onTap: () =>
                          AppRoutes.push(context, const ClientesPage()),
                    ),
                    _Acceso(
                      icono: Icons.local_shipping_outlined,
                      texto: 'Proveedores',
                      color: const Color(0xFF0277BD),
                      onTap: () =>
                          AppRoutes.push(context, const ProveedoresPage()),
                    ),
                    _Acceso(
                      icono: Icons.request_quote_outlined,
                      texto: 'Cotizaciones',
                      color: const Color(0xFFF9A825),
                      onTap: () =>
                          AppRoutes.push(context, const CotizacionesPage()),
                    ),
                  ],
                ),

                // ========================================= alertas stock
                if (stockBajo.isNotEmpty) ...[
                  SectionHeader(
                    titulo: 'Alertas de stock',
                    textoAccion: 'Ver productos',
                    onAccion: () => ShellNavegacion.irA(1),
                  ),
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: stockBajo.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => FadeSlide(
                        delay: Duration(milliseconds: 100 + i * 100),
                        inicio: const Offset(0.35, 0),
                        child: _TarjetaAlerta(
                          producto: stockBajo[i],
                          onTap: () => AppRoutes.push(
                            context,
                            ProductoDetalleScreen(productoId: stockBajo[i].id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ========================================== ultimas ventas
                SectionHeader(
                  titulo: 'Ultimas ventas',
                  textoAccion: 'Ver todo',
                  onAccion: () => ShellNavegacion.irA(2),
                ),
                if (ventas.ventas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Aun no hay ventas registradas.',
                        style: TextStyle(color: Colors.grey.shade600)),
                  )
                else
                  FadeSlide(
                    inicio: const Offset(0, 0.2),
                    child: _LibroVentas(
                      ventas: ventas.ventas.take(4).toList(),
                      onTap: (v) => AppRoutes.push(
                        context,
                        VentaDetalleScreen(ventaId: v.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================== piezas

class _Mono extends StatelessWidget {
  final String texto;
  final Color color;

  const _Mono(this.texto, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10.5,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Dato pequeno del tablero con contador animado.
class _MiniDato extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final bool alerta;

  const _MiniDato({
    required this.valor,
    required this.etiqueta,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        alerta && valor > 0 ? const Color(0xFFFF5252) : AppTheme.hueso;
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: valor.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 19,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        Expanded(
          child: _Mono(etiqueta,
              alerta && valor > 0 ? color : const Color(0x99EDE8DF)),
        ),
      ],
    );
  }
}

/// Tarjeta del carrusel: el producto "flota" sobre su ficha y se mueve con
/// el dedo (paralaje 3D).
class _TarjetaDestacado extends StatelessWidget {
  final Producto producto;
  final Categoria categoria;
  final VoidCallback onTap;

  const _TarjetaDestacado({
    required this.producto,
    required this.categoria,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 172,
      child: Tilt3D(
        anguloMax: 0.16,
        radioBorde: 16,
        builder: (context, t) => Material(
          color: Theme.of(context).cardColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 124,
                  width: double.infinity,
                  color: categoria.color.withOpacity(oscuro ? 0.18 : 0.12),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 10,
                        top: 9,
                        child: Text(
                          producto.codigo,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: Offset(t.dx * -9, t.dy * -9),
                          child: Transform.scale(
                            scale: 1 + t.distance * 0.12,
                            child: ProductoEstatico(
                              tipo: producto.tipoVisual,
                              colorHex: producto.colorHex,
                              size: 100,
                              sombra: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.soles(producto.precioVenta),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _naranjaTexto(context),
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

class _Acceso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final bool destacado;
  final VoidCallback onTap;

  const _Acceso({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = destacado ? AppTheme.primary : Theme.of(context).cardColor;
    final tinta = destacado ? AppTheme.grafito : null;

    return Tilt3D(
      anguloMax: 0.14,
      radioBorde: 14,
      builder: (context, t) => Material(
        color: fondo,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: destacado
                ? AppTheme.primary
                : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: destacado
                        ? AppTheme.grafito
                        : color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Transform.translate(
                    offset: Offset(t.dx * -3, t.dy * -3),
                    child: Icon(icono,
                        size: 21,
                        color: destacado ? AppTheme.primary : color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: tinta),
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

/// Tarjeta de alerta: oscura, con franja de obra, producto flotando sobre
/// un halo rojo y un medidor segmentado del stock que queda.
class _TarjetaAlerta extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _TarjetaAlerta({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const rojo = Color(0xFFFF5252);
    final llenos = producto.stock.clamp(0, 5).toInt();

    return SizedBox(
      width: 178,
      child: Tilt3D(
        anguloMax: 0.16,
        radioBorde: 16,
        builder: (context, t) => Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const ShapeDecoration(
              color: AppTheme.grafito,
              shape: BeveledRectangleBorder(
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(24)),
                side: BorderSide(color: Color(0x99FF5252), width: 1.6),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const BeveledRectangleBorder(
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FranjaPeligro(alto: 7),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        const _PuntoAlerta(),
                        const SizedBox(width: 7),
                        const Text(
                          'REPONER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w900,
                            color: rojo,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          producto.codigo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Color(0x80EDE8DF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0x40FF5252), Color(0x00FF5252)],
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(t.dx * -8, t.dy * -8),
                          child: ProductoEstatico(
                            tipo: producto.tipoVisual,
                            colorHex: producto.colorHex,
                            size: 78,
                            sombra: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.hueso,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Expanded(
                                child: Container(
                                  height: 6,
                                  margin:
                                      EdgeInsets.only(right: i == 4 ? 0 : 3),
                                  decoration: BoxDecoration(
                                    color: i < llenos
                                        ? rojo
                                        : const Color(0xFF2E353B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          producto.stock <= 0
                              ? 'AGOTADO'
                              : 'QUEDAN ${producto.stock} ${producto.unidad.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: rojo,
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
      ),
    );
  }
}

/// Punto rojo que late para llamar la atencion.
class _PuntoAlerta extends StatefulWidget {
  const _PuntoAlerta();

  @override
  State<_PuntoAlerta> createState() => _PuntoAlertaState();
}

class _PuntoAlertaState extends State<_PuntoAlerta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5252).withOpacity(0.35 + 0.5 * _c.value),
              blurRadius: 4 + 8 * _c.value,
              spreadRadius: 1 + 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Libro de caja: un solo panel con el resumen (total y grafico de barras)
/// y las ventas como filas separadas por lineas finas.
class _LibroVentas extends StatelessWidget {
  final List<Venta> ventas;
  final ValueChanged<Venta> onTap;

  const _LibroVentas({required this.ventas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = ventas.fold<double>(0, (a, v) => a + v.total);
    final maximo = ventas.fold<double>(1, (a, v) => v.total > a ? v.total : a);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const ShapeDecoration(
        color: AppTheme.grafito,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(26)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ULTIMAS ${ventas.length} VENTAS',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                          color: Color(0x99EDE8DF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: total),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Formatters.soles(v),
                            style: const TextStyle(
                              fontSize: 30,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Barras proporcionales a cada venta
                SizedBox(
                  width: 110,
                  height: 46,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < ventas.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                                begin: 0,
                                end: (ventas[i].total / maximo)
                                    .clamp(0.12, 1.0)
                                    .toDouble()),
                            duration: Duration(milliseconds: 700 + i * 150),
                            curve: Curves.easeOutBack,
                            builder: (context, v, _) => Container(
                              width: 16,
                              height: 46 * v,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppTheme.primary
                                    : const Color(0xFF3A4148),
                                borderRadius: BorderRadius.circular(3),
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
          const FranjaPeligro(alto: 5),
          for (var i = 0; i < ventas.length; i++) ...[
            FadeSlide(
              delay: Duration(milliseconds: 150 + i * 90),
              inicio: const Offset(0.2, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(ventas[i]),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                    child: Row(
                      children: [
                        Text(
                          (i + 1).toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ventas[i].clienteNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.hueso,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ventas[i].numero}  -  ${ventas[i].metodoPago.toUpperCase()}  -  ${Formatters.fechaCorta(ventas[i].fecha)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Color(0x80EDE8DF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Formatters.soles(ventas[i].total),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.hueso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i < ventas.length - 1)
              const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: Color(0xFF2C3339)),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
