import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/producto.dart';
import 'admin_store.dart';
import 'admin_ui.dart';
import 'alertas_stock.dart';
import 'calendario_rango.dart';

// ===========================================================================
// UTILIDADES
// ===========================================================================

Set<String> codigosUsados(AdminStore s, {String? excepto}) {
  final ex = (excepto ?? '').trim().toLowerCase();
  return {
    for (final i in s.productos)
      if (i.p.codigo.trim().toLowerCase() != ex) i.p.codigo.trim().toLowerCase(),
  };
}

Color _colorProducto(Producto p) => Color(p.colorHex | 0xFF000000);

Etiqueta _etiquetaEstado(BuildContext context, ItemProducto i) {
  if (i.enPapelera) return const Etiqueta('Papelera', Tono.peligro);
  if (!i.activo) return Etiqueta('Inactivo', context.tenue);
  if (i.p.agotado) return const Etiqueta('Agotado', Tono.peligro);
  if (i.p.stockBajo) return const Etiqueta('Stock bajo', Tono.alerta);
  return const Etiqueta('Disponible', Tono.ok);
}

Color _colorStock(Producto p) =>
    p.agotado ? Tono.peligro : (p.stockBajo ? Tono.alerta : Tono.ok);

class _BarraStock extends StatelessWidget {
  const _BarraStock(this.p);

  final Producto p;

  @override
  Widget build(BuildContext context) {
    final tope = math.max(1, p.stockMinimo * 3);
    final v = (p.stock / tope).clamp(0.0, 1.0).toDouble();
    final c = _colorStock(p);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: v),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, valor, _) => LinearProgressIndicator(
          value: valor,
          minHeight: 4,
          color: c,
          backgroundColor: c.withOpacity(0.15),
        ),
      ),
    );
  }
}

// ===========================================================================
// PESTAÑA
// ===========================================================================

class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key, required this.store});

  final AdminStore store;

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  static const _pagina = 48;
  static const _ordenes = [
    'Más recientes',
    'Nombre (A-Z)',
    'Precio (mayor)',
    'Stock (menor)',
  ];

  final _scroll = ScrollController();
  String _q = '';
  int _vista = 0; // 0 tarjetas, 1 tabla
  int _estado = 0; // 0 activos, 1 inactivos, 2 papelera
  int _stock = 0; // 0 todos, 1 bajo, 2 agotado
  int _orden = 0;
  RangoFechas? _rango;
  int _visibles = _pagina;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Carga progresiva: se pintan 48 elementos y se agregan más al acercarse
  /// al final. Las listas son perezosas (builders), nunca se pintan todas.
  void _alDesplazar() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels > p.maxScrollExtent - 700 && _visibles < _total) {
      setState(() => _visibles += _pagina);
    }
  }

  void _cambiar(VoidCallback f) => setState(() {
        f();
        _visibles = _pagina;
      });

  List<ItemProducto> _filtrar() {
    final q = _q.trim().toLowerCase();
    final out = <ItemProducto>[];
    for (final i in widget.store.productos) {
      final ok = switch (_estado) {
        0 => !i.enPapelera && i.activo,
        1 => !i.enPapelera && !i.activo,
        _ => i.enPapelera,
      };
      if (!ok) continue;
      if (_estado != 2) {
        if (_stock == 1 && !(i.p.stockBajo && !i.p.agotado)) continue;
        if (_stock == 2 && !i.p.agotado) continue;
      }
      if (_rango != null && !_rango!.contiene(i.creadoEn)) continue;
      if (q.isNotEmpty && !i.busqueda.contains(q)) continue;
      out.add(i);
    }
    switch (_orden) {
      case 1:
        out.sort((a, b) =>
            a.p.nombre.toLowerCase().compareTo(b.p.nombre.toLowerCase()));
      case 2:
        out.sort((a, b) => b.p.precioVenta.compareTo(a.p.precioVenta));
      case 3:
        out.sort((a, b) => a.p.stock.compareTo(b.p.stock));
    }
    return out;
  }

  Future<void> _nuevo() async {
    final msg = await dialogo<String>(
      context,
      (_) => _DialogoNuevo(store: widget.store),
    );
    if (msg != null && mounted) toast(context, msg);
  }

  Future<void> _abrir(ItemProducto i) async {
    final msg = await dialogo<String>(
      context,
      (_) => DetalleProducto(store: widget.store, id: i.id),
    );
    if (msg != null && mounted) toast(context, msg);
  }

  Future<void> _restaurar(ItemProducto i) async {
    final ok = await ejecutar(
      () => widget.store.restaurar(i.id),
      que: 'restaurar el producto',
      alFallar: (m) => toast(context, m, error: true),
    );
    if (ok && mounted) toast(context, '"${i.p.nombre}" restaurado y visible otra vez');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final s = widget.store;
        if (s.productosError != null) {
          return Padding(
            padding: const EdgeInsets.only(top: kNavAlto),
            child: ErrorCaja(error: s.productosError!),
          );
        }
        if (!s.productosListo) return const Cargando();

        var activos = 0, inactivos = 0, papelera = 0;
        for (final i in s.productos) {
          if (i.enPapelera) {
            papelera++;
          } else if (i.activo) {
            activos++;
          } else {
            inactivos++;
          }
        }

        final lista = _filtrar();
        _total = lista.length;
        final visibles = math.min(lista.length, _visibles);
        final ancho = MediaQuery.sizeOf(context).width;
        final pad = ancho < 700 ? 16.0 : 32.0;

        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, kNavAlto + 14, pad, 0),
              sliver: SliverToBoxAdapter(
                child: _cabecera(context, activos, inactivos, papelera),
              ),
            ),
            if (lista.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Vacio(
                  icono: _estado == 2
                      ? Icons.delete_outline_rounded
                      : Icons.inventory_2_outlined,
                  titulo: s.productos.isEmpty
                      ? 'Aún no hay productos'
                      : (_estado == 2
                          ? 'La papelera está vacía'
                          : 'Sin resultados'),
                  detalle: s.productos.isEmpty
                      ? 'Crea el primero con el botón "Nuevo producto".'
                      : (_estado == 2
                          ? 'Los productos eliminados aparecen aquí durante '
                              '${AdminStore.diasPapelera} días.'
                          : 'Prueba con otra búsqueda, fecha o filtro.'),
                ),
              )
            else if (_vista == 0)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 6, pad, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 272,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 238,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, k) {
                      final i = lista[k];
                      return Aparece(
                        key: ValueKey('g-${i.id}'),
                        indice: math.min(k, 10),
                        child: _TarjetaProducto(
                          item: i,
                          onTap: () => _abrir(i),
                          onRestaurar: () => _restaurar(i),
                        ),
                      );
                    },
                    childCount: visibles,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 6, pad, 0),
                sliver: const SliverToBoxAdapter(child: _CabeceraTabla()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 0),
                sliver: SliverFixedExtentList(
                  itemExtent: 62,
                  delegate: SliverChildBuilderDelegate(
                    (context, k) {
                      final i = lista[k];
                      return Aparece(
                        key: ValueKey('t-${i.id}'),
                        indice: math.min(k, 10),
                        child: _FilaTabla(
                          item: i,
                          ultima: k == visibles - 1,
                          onTap: () => _abrir(i),
                          onRestaurar: () => _restaurar(i),
                        ),
                      );
                    },
                    childCount: visibles,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: visibles < lista.length
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Tono.acento),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  void _verAlerta(bool urgente) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => ListaAlertaStock(
          store: widget.store,
          urgente: urgente,
          onAbrir: (ctx, item) async {
            final msg = await dialogo<String>(
              ctx,
              (_) => DetalleProducto(store: widget.store, id: item.id),
            );
            if (msg != null && ctx.mounted) toast(ctx, msg);
          },
        ),
        transitionsBuilder: (_, anim, __, child) {
          final c = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: c,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(c),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _cabecera(BuildContext context, int activos, int inactivos, int papelera) {
    final agotados = productosAgotados(widget.store);
    final porAcabarse = productosPorAcabarse(widget.store);
    final buscador = BuscadorCampo(
      hint: 'Buscar por nombre, código o marca…',
      onChanged: (v) => _cambiar(() => _q = v),
    );

    final orden = PopupMenuButton<int>(
      tooltip: 'Ordenar',
      color: context.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.linea),
      ),
      onSelected: (o) => _cambiar(() => _orden = o),
      itemBuilder: (_) => [
        for (var k = 0; k < _ordenes.length; k++)
          PopupMenuItem<int>(
            value: k,
            child: Row(
              children: [
                Icon(
                  k == _orden ? Icons.check_rounded : Icons.sort_rounded,
                  size: 18,
                  color: k == _orden ? Tono.acento : context.tenue,
                ),
                const SizedBox(width: 10),
                Text(_ordenes[k], style: TextStyle(color: context.tinta)),
              ],
            ),
          ),
      ],
      child: Tarjeta(
        elevarAlHover: false,
        radio: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 18, color: context.tenue),
            const SizedBox(width: 8),
            Text(
              _ordenes[_orden],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: context.tinta,
              ),
            ),
          ],
        ),
      ),
    );

    final vista = Segmentos(
      items: const [
        SegItem(icono: Icons.grid_view_rounded),
        SegItem(icono: Icons.table_rows_rounded),
      ],
      tooltips: const ['Vista de tarjetas', 'Vista de tabla'],
      indice: _vista,
      anchoItem: 46,
      onCambio: (v) => _cambiar(() => _vista = v),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Aparece(
          child: EncabezadoPagina(
            titulo: 'Productos',
            subtitulo:
                '$activos activos · $inactivos inactivos · $papelera en papelera',
            acciones: [
              FilledButton.icon(
                onPressed: _nuevo,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Nuevo producto',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Tono.acento,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (agotados.isNotEmpty || porAcabarse.isNotEmpty) ...[
          const SizedBox(height: 18),
          Aparece(
            indice: 1,
            child: LayoutBuilder(
              builder: (context, caja) {
                final columnas = caja.maxWidth >= 760;
                final cuadros = <Widget>[
                  if (agotados.isNotEmpty)
                    CuadroAlertaStock(
                      urgente: true,
                      cantidad: agotados.length,
                      onTap: () => _verAlerta(true),
                    ),
                  if (porAcabarse.isNotEmpty)
                    CuadroAlertaStock(
                      urgente: false,
                      cantidad: porAcabarse.length,
                      onTap: () => _verAlerta(false),
                    ),
                ];
                if (!columnas || cuadros.length == 1) {
                  return Column(
                    children: [
                      for (var i = 0; i < cuadros.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        cuadros[i],
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < cuadros.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cuadros[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 22),
        Aparece(
          indice: 1,
          child: LayoutBuilder(
            builder: (context, caja) {
              final angosto = caja.maxWidth < 760;
              final herramientas = Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BotonFechas(
                    valor: _rango,
                    onCambio: (r) => _cambiar(() => _rango = r),
                  ),
                  orden,
                  vista,
                ],
              );
              if (angosto) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [buscador, const SizedBox(height: 10), herramientas],
                );
              }
              return Row(
                children: [
                  Expanded(child: buscador),
                  const SizedBox(width: 12),
                  herramientas,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Aparece(
          indice: 2,
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Segmentos(
                items: [
                  SegItem(texto: 'Activos', contador: activos),
                  SegItem(texto: 'Inactivos', contador: inactivos),
                  SegItem(
                    icono: Icons.delete_outline_rounded,
                    texto: 'Papelera',
                    contador: papelera,
                  ),
                ],
                indice: _estado,
                anchoItem: 126,
                onCambio: (v) => _cambiar(() => _estado = v),
              ),
              if (_estado != 2)
                Wrap(
                  spacing: 8,
                  children: [
                    Pildora(
                      texto: 'Todo el stock',
                      activo: _stock == 0,
                      onTap: () => _cambiar(() => _stock = 0),
                    ),
                    Pildora(
                      texto: 'Stock bajo',
                      activo: _stock == 1,
                      onTap: () => _cambiar(() => _stock = 1),
                    ),
                    Pildora(
                      texto: 'Agotados',
                      activo: _stock == 2,
                      onTap: () => _cambiar(() => _stock = 2),
                    ),
                  ],
                ),
              if (_estado == 2)
                Text(
                  'Se eliminan solos a los ${AdminStore.diasPapelera} días.',
                  style: TextStyle(color: context.tenue, fontSize: 13),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

// ===========================================================================
// TARJETA
// ===========================================================================

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.item,
    required this.onTap,
    required this.onRestaurar,
  });

  final ItemProducto item;
  final VoidCallback onTap;
  final VoidCallback onRestaurar;

  @override
  Widget build(BuildContext context) {
    final p = item.p;
    final color = _colorProducto(p);
    final apagado = !item.activo || item.enPapelera;

    return Opacity(
      opacity: apagado ? 0.82 : 1,
      child: Tarjeta(
        onTap: onTap,
        padding: EdgeInsets.zero,
        radio: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: color.withOpacity(apagado ? 0.07 : 0.14),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(17)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      inicial(p.nombre),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: color.withOpacity(apagado ? 0.45 : 0.85),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Text(
                      p.codigo,
                      style: estiloNum(
                        context,
                        size: 11.5,
                        peso: FontWeight.w700,
                        color: context.tenue,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 9,
                    child: _etiquetaEstado(context, item),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: context.tinta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.marca.trim().isEmpty ? p.unidad : '${p.marca} · ${p.unidad}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: context.tenue),
                    ),
                    const Spacer(),
                    if (item.enPapelera)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Se elimina en ${item.diasRestantes} día(s)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.tenue,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onRestaurar,
                            icon: const Icon(Icons.restore_rounded, size: 17),
                            label: const Text('Restaurar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Tono.acento,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              soles(p.precioVenta),
                              style: estiloNum(context, size: 17, peso: FontWeight.w800)
                                  .copyWith(letterSpacing: -0.4),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.stock} uds',
                                style: estiloNum(
                                  context,
                                  size: 12,
                                  peso: FontWeight.w700,
                                  color: _colorStock(p),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(width: 58, child: _BarraStock(p)),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// TABLA
// ===========================================================================

class _CabeceraTabla extends StatelessWidget {
  const _CabeceraTabla();

  @override
  Widget build(BuildContext context) {
    TextStyle estilo() => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: context.tenue,
        );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: context.panel2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: context.linea),
      ),
      child: LayoutBuilder(
        builder: (context, caja) {
          final marca = caja.maxWidth >= 900;
          final stock = caja.maxWidth >= 640;
          return Row(
            children: [
              Expanded(flex: 5, child: Text('PRODUCTO', style: estilo())),
              if (marca)
                Expanded(flex: 2, child: Text('MARCA', style: estilo())),
              Expanded(
                flex: 2,
                child: Text('PRECIO', textAlign: TextAlign.right, style: estilo()),
              ),
              if (stock)
                Expanded(flex: 2, child: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text('STOCK', style: estilo()),
                )),
              Expanded(flex: 2, child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('ESTADO', style: estilo()),
              )),
              const SizedBox(width: 30),
            ],
          );
        },
      ),
    );
  }
}

class _FilaTabla extends StatefulWidget {
  const _FilaTabla({
    required this.item,
    required this.ultima,
    required this.onTap,
    required this.onRestaurar,
  });

  final ItemProducto item;
  final bool ultima;
  final VoidCallback onTap;
  final VoidCallback onRestaurar;

  @override
  State<_FilaTabla> createState() => _FilaTablaState();
}

class _FilaTablaState extends State<_FilaTabla> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final p = i.p;
    final color = _colorProducto(p);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: _h ? context.panel2 : context.panel,
            border: Border(
              left: BorderSide(color: context.linea),
              right: BorderSide(color: context.linea),
              bottom: BorderSide(color: context.linea),
            ),
            borderRadius: widget.ultima
                ? const BorderRadius.vertical(bottom: Radius.circular(14))
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, caja) {
              final marca = caja.maxWidth >= 900;
              final stock = caja.maxWidth >= 640;
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            inicial(p.nombre),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: context.tinta,
                                ),
                              ),
                              Text(
                                p.codigo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: estiloNum(
                                  context,
                                  size: 12,
                                  peso: FontWeight.w600,
                                  color: context.tenue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (marca)
                    Expanded(
                      flex: 2,
                      child: Text(
                        p.marca.isEmpty ? '—' : p.marca,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.tenue, fontSize: 13.5),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      soles(p.precioVenta),
                      textAlign: TextAlign.right,
                      style: estiloNum(context, size: 14, peso: FontWeight.w800),
                    ),
                  ),
                  if (stock)
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.stock}',
                              style: estiloNum(
                                context,
                                size: 13.5,
                                peso: FontWeight.w800,
                                color: _colorStock(p),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _BarraStock(p),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: i.enPapelera
                            ? TextButton(
                                onPressed: widget.onRestaurar,
                                style: TextButton.styleFrom(
                                  foregroundColor: Tono.acento,
                                  padding: EdgeInsets.zero,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                                child: Text('Restaurar · ${i.diasRestantes} d'),
                              )
                            : _etiquetaEstado(context, i),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.tenue),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// NUEVO PRODUCTO
// ===========================================================================

class _DialogoNuevo extends StatefulWidget {
  const _DialogoNuevo({required this.store});

  final AdminStore store;

  @override
  State<_DialogoNuevo> createState() => _DialogoNuevoState();
}

class _DialogoNuevoState extends State<_DialogoNuevo> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.panel,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.linea),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 660,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nuevo producto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: context.tinta,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close_rounded, color: context.tenue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.linea),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(26),
                child: Column(
                  children: [
                    if (_error != null) ...[
                      Aviso(texto: _error!, error: true),
                      const SizedBox(height: 16),
                    ],
                    FormularioProducto(
                      codigosUsados: codigosUsados(widget.store),
                      textoGuardar: 'Crear producto',
                      onCancelar: () => Navigator.of(context).pop(),
                      onGuardar: (p) async {
                        setState(() => _error = null);
                        final ok = await ejecutar(
                          () => widget.store.crear(p),
                          que: 'crear el producto',
                          alFallar: (m) {
                            if (mounted) setState(() => _error = m);
                          },
                        );
                        if (ok && mounted) {
                          Navigator.of(context)
                              .pop('Producto "${p.nombre}" creado');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// DETALLE (modal de vista rápida con edición colapsable)
// ===========================================================================

class DetalleProducto extends StatefulWidget {
  const DetalleProducto({super.key, required this.store, required this.id});

  final AdminStore store;
  final String id;

  @override
  State<DetalleProducto> createState() => _DetalleProductoState();
}

class _DetalleProductoState extends State<DetalleProducto> {
  final _llaveEdicion = GlobalKey();
  bool _editando = false;
  bool _cerrando = false;
  String? _msg;
  bool _msgError = false;

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _msg = texto;
      _msgError = error;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _msg == texto) setState(() => _msg = null);
    });
  }

  void _cerrar(String mensaje) {
    _cerrando = true;
    Navigator.of(context).pop(mensaje);
  }

  Future<void> _alternarEdicion() async {
    setState(() => _editando = !_editando);
    if (_editando) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      final ctx = _llaveEdicion.currentContext;
      if (ctx != null && mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Future<void> _cambiarActivo(ItemProducto i, bool activo) async {
    final ok = await ejecutar(
      () => widget.store.definirActivo(i.id, activo),
      que: activo ? 'activar el producto' : 'desactivar el producto',
      alFallar: (m) => _aviso(m, error: true),
    );
    if (ok) {
      _aviso(activo
          ? 'Producto activado: ya se muestra en la app.'
          : 'Producto desactivado: la app ya no lo muestra.');
    }
  }

  Future<void> _aPapelera(ItemProducto i) async {
    final si = await dialogo<bool>(
      context,
      (_) => ConfirmarDialogo(
        icono: Icons.delete_outline_rounded,
        color: Tono.peligro,
        titulo: 'Mover a la papelera',
        mensaje: '"${i.p.nombre}" dejará de mostrarse en la app. Podrás '
            'restaurarlo durante ${AdminStore.diasPapelera} días; después se '
            'eliminará de forma definitiva.',
        textoConfirmar: 'Mover a papelera',
      ),
    );
    if (si != true || !mounted) return;
    final ok = await ejecutar(
      () => widget.store.aPapelera(i.id),
      que: 'mover el producto a la papelera',
      alFallar: (m) => _aviso(m, error: true),
    );
    if (ok && mounted) {
      _cerrar('"${i.p.nombre}" se movió a la papelera');
    }
  }

  Future<void> _restaurar(ItemProducto i) async {
    final ok = await ejecutar(
      () => widget.store.restaurar(i.id),
      que: 'restaurar el producto',
      alFallar: (m) => _aviso(m, error: true),
    );
    if (ok) _aviso('Producto restaurado y visible en la app.');
  }

  Future<void> _eliminarDefinitivo(ItemProducto i) async {
    final si = await dialogo<bool>(
      context,
      (_) => ConfirmarDialogo(
        icono: Icons.delete_forever_rounded,
        color: Tono.peligro,
        titulo: 'Eliminar definitivamente',
        mensaje: '"${i.p.nombre}" se borrará de la base de datos ahora mismo. '
            'Esta acción no se puede deshacer.',
        textoConfirmar: 'Eliminar para siempre',
      ),
    );
    if (si != true || !mounted) return;
    final ok = await ejecutar(
      () => widget.store.eliminarDefinitivo(i.id),
      que: 'eliminar el producto',
      alFallar: (m) => _aviso(m, error: true),
    );
    if (ok && mounted) _cerrar('"${i.p.nombre}" se eliminó definitivamente');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final item = widget.store.buscarProducto(widget.id);
        if (item == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_cerrando) {
              _cerrando = true;
              Navigator.of(context).maybePop();
            }
          });
          return const SizedBox.shrink();
        }
        return _contenido(context, item);
      },
    );
  }

  Widget _contenido(BuildContext context, ItemProducto item) {
    final p = item.p;
    final color = _colorProducto(p);
    final alto = MediaQuery.sizeOf(context).height;
    final ancho = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: context.panel,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.all(ancho < 600 ? 10 : 28),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: context.linea),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 940, maxHeight: alto * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------------------- cabecera ---------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 18),
              decoration: BoxDecoration(
                color: color.withOpacity(context.oscuro ? 0.10 : 0.09),
                border: Border(bottom: BorderSide(color: context.linea)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      inicial(p.nombre),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: context.tinta,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              p.codigo,
                              style: estiloNum(
                                context,
                                size: 13,
                                peso: FontWeight.w700,
                                color: context.tenue,
                              ),
                            ),
                            _etiquetaEstado(context, item),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close_rounded, color: context.tenue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ------------------------------ cuerpo ---------------------------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _msg == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Aviso(texto: _msg!, error: _msgError),
                            ),
                    ),
                    LayoutBuilder(
                      builder: (context, caja) {
                        final dos = caja.maxWidth >= 700;
                        final metricas = _metricas(context, item);
                        final ficha = _ficha(context, item);
                        if (dos) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: metricas),
                              const SizedBox(width: 28),
                              Expanded(flex: 6, child: ficha),
                            ],
                          );
                        }
                        return Column(
                          children: [metricas, const SizedBox(height: 22), ficha],
                        );
                      },
                    ),
                    if (p.descripcion.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        'DESCRIPCIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: context.tenue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: context.tinta,
                        ),
                      ),
                    ],
                    // ------------------- edición colapsable ------------------
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: !_editando
                          ? const SizedBox(width: double.infinity)
                          : Container(
                              key: _llaveEdicion,
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 24),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: context.panel2,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: context.linea),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Editar producto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: context.tinta,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  FormularioProducto(
                                    original: p,
                                    codigosUsados: codigosUsados(
                                      widget.store,
                                      excepto: p.codigo,
                                    ),
                                    onCancelar: () =>
                                        setState(() => _editando = false),
                                    onGuardar: (nuevo) async {
                                      final ok = await ejecutar(
                                        () => widget.store.guardar(nuevo),
                                        que: 'guardar los cambios',
                                        alFallar: (m) =>
                                            _aviso(m, error: true),
                                      );
                                      if (ok && mounted) {
                                        setState(() => _editando = false);
                                        _aviso('Cambios guardados.');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // -------------------------- barra de acciones --------------------
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: context.panel,
                border: Border(top: BorderSide(color: context.linea)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (!item.enPapelera)
                    OutlinedButton.icon(
                      onPressed: _alternarEdicion,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _editando
                              ? Icons.expand_less_rounded
                              : Icons.edit_rounded,
                          key: ValueKey(_editando),
                          size: 18,
                        ),
                      ),
                      label: Text(_editando ? 'Ocultar edición' : 'Editar'),
                      style: _estiloBoton(context, context.tinta),
                    )
                  else
                    Text(
                      'Se eliminará automáticamente en ${item.diasRestantes} día(s)',
                      style: TextStyle(
                        color: context.tenue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: item.enPapelera
                        ? [
                            FilledButton.icon(
                              onPressed: () => _restaurar(item),
                              icon: const Icon(Icons.restore_rounded, size: 18),
                              label: const Text('Restaurar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Tono.acento,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _eliminarDefinitivo(item),
                              icon: const Icon(Icons.delete_forever_rounded,
                                  size: 18),
                              label: const Text('Eliminar definitivamente'),
                              style: _estiloBoton(context, Tono.peligro),
                            ),
                          ]
                        : [
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _cambiarActivo(item, !item.activo),
                              icon: Icon(
                                item.activo
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: Text(
                                item.activo ? 'Desactivar' : 'Activar',
                              ),
                              style: _estiloBoton(
                                context,
                                item.activo ? Tono.alerta : Tono.ok,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _aPapelera(item),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              label: const Text('Eliminar'),
                              style: _estiloBoton(context, Tono.peligro),
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

  ButtonStyle _estiloBoton(BuildContext context, Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.5), width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _metricas(BuildContext context, ItemProducto item) {
    final p = item.p;
    final ganancia = p.precioVenta - p.precioCompra;
    final margen = (p.precioCompra > 0 && p.precioVenta > 0)
        ? '${(ganancia / p.precioVenta * 100).toStringAsFixed(1)} %'
        : '—';

    Widget m(String t, String v, {Color? color}) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.panel2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.tenue,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                v,
                style: estiloNum(
                  context,
                  size: 20,
                  peso: FontWeight.w800,
                  color: color,
                ).copyWith(letterSpacing: -0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATOS COMERCIALES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: context.tenue,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            m('Precio de venta', soles(p.precioVenta)),
            m('Precio de compra', soles(p.precioCompra)),
            m('Ganancia por unidad', soles(ganancia),
                color: ganancia >= 0 ? Tono.ok : Tono.peligro),
            m('Margen', margen),
            m('Stock', '${p.stock} ${p.unidad}', color: _colorStock(p)),
            m('Valor en inventario', soles(p.precioVenta * p.stock)),
          ],
        ),
      ],
    );
  }

  Widget _ficha(BuildContext context, ItemProducto item) {
    final p = item.p;

    Widget fila(String t, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                t,
                style: TextStyle(fontSize: 13, color: context.tenue),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.tinta,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filas = <Widget>[
      fila('Código', p.codigo),
      fila('Marca', p.marca.isEmpty ? '—' : p.marca),
      fila('Unidad', p.unidad),
      fila('Stock mínimo', '${p.stockMinimo}'),
      if (p.categoriaId.isNotEmpty) fila('Categoría', p.categoriaId),
      if (p.fuente.isNotEmpty) fila('Fuente del precio', p.fuente),
      if (p.fechaPrecio != null) fila('Precio verificado', fechaTxt(p.fechaPrecio!)),
      if (p.calidad > 0) fila('Calidad', '${p.calidad.toStringAsFixed(1)} / 5'),
      if (item.creadoEn != null) fila('Registrado', fechaTxt(item.creadoEn!)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FICHA TÉCNICA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: context.tenue,
          ),
        ),
        const SizedBox(height: 4),
        for (var k = 0; k < filas.length; k++) ...[
          filas[k],
          if (k < filas.length - 1) Divider(height: 1, color: context.linea),
        ],
      ],
    );
  }
}

// ===========================================================================
// FORMULARIO (compartido por "Nuevo" y "Editar")
// ===========================================================================

class FormularioProducto extends StatefulWidget {
  const FormularioProducto({
    super.key,
    this.original,
    required this.codigosUsados,
    required this.onGuardar,
    required this.onCancelar,
    this.textoGuardar = 'Guardar cambios',
  });

  /// `null` cuando se crea un producto nuevo.
  final Producto? original;

  /// Códigos (en minúsculas) que ya existen: evita duplicados.
  final Set<String> codigosUsados;
  final Future<void> Function(Producto) onGuardar;
  final VoidCallback onCancelar;
  final String textoGuardar;

  @override
  State<FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<FormularioProducto> {
  final _form = GlobalKey<FormState>();
  final _kCompra = GlobalKey<FormFieldState<String>>();

  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _marca;
  late final TextEditingController _unidad;
  late final TextEditingController _precioVenta;
  late final TextEditingController _precioCompra;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;

  bool _guardando = false;
  bool _intentoFallido = false;

  @override
  void initState() {
    super.initState();
    final p = widget.original;
    _codigo = TextEditingController(text: p?.codigo ?? '');
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _marca = TextEditingController(text: p?.marca ?? '');
    _unidad = TextEditingController(text: p?.unidad ?? 'Unidad');
    _precioVenta =
        TextEditingController(text: p == null ? '' : '${p.precioVenta}');
    _precioCompra =
        TextEditingController(text: p == null ? '' : '${p.precioCompra}');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _stockMinimo =
        TextEditingController(text: p == null ? '5' : '${p.stockMinimo}');
  }

  @override
  void dispose() {
    for (final c in [
      _codigo,
      _nombre,
      _descripcion,
      _marca,
      _unidad,
      _precioVenta,
      _precioCompra,
      _stock,
      _stockMinimo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_form.currentState?.validate() ?? false)) {
      HapticFeedback.selectionClick();
      setState(() => _intentoFallido = true);
      return;
    }
    setState(() {
      _intentoFallido = false;
      _guardando = true;
    });
    final p = widget.original;
    final resultado = Producto(
      id: p?.id ?? 'web-${DateTime.now().millisecondsSinceEpoch}',
      codigo: _codigo.text.trim(),
      nombre: _nombre.text.trim(),
      descripcion: _descripcion.text.trim(),
      // Se conservan los campos que este formulario no edita.
      categoriaId: p?.categoriaId ?? '',
      marca: _marca.text.trim(),
      unidad: _unidad.text.trim().isEmpty ? 'Unidad' : _unidad.text.trim(),
      precioVenta: _num(_precioVenta.text)!,
      precioCompra: _num(_precioCompra.text) ?? 0,
      stock: int.parse(_stock.text.trim()),
      stockMinimo: int.tryParse(_stockMinimo.text.trim()) ?? 5,
      tipoVisual: p?.tipoVisual ?? 'generico',
      colorHex: p?.colorHex ?? 0xFF607D8B,
      coloresHex: p?.coloresHex ?? const [],
      fuente: p?.fuente ?? '',
      urlFuente: p?.urlFuente ?? '',
      fechaPrecio: p?.fechaPrecio,
      calidad: p?.calidad ?? 0,
    );
    try {
      await widget.onGuardar(resultado);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ------------------------------ validaciones ------------------------------

  String? _vCodigo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El código es obligatorio';
    if (t.length < 3) return 'Mínimo 3 caracteres';
    if (t.length > 20) return 'Máximo 20 caracteres';
    if (!RegExp(r'^[A-Za-z0-9._\-]+$').hasMatch(t)) {
      return 'Solo letras, números, punto y guiones';
    }
    if (widget.codigosUsados.contains(t.toLowerCase())) {
      return 'Ya existe un producto con este código';
    }
    return null;
  }

  String? _vNombre(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El nombre es obligatorio';
    if (t.length < 3) return 'Mínimo 3 caracteres';
    if (t.length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  String? _vVenta(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El precio de venta es obligatorio';
    final n = _num(t);
    if (n == null) return 'Debe ser un número';
    if (n <= 0) return 'Debe ser mayor que 0';
    if (n > 1000000) return 'Valor demasiado alto';
    return null;
  }

  String? _vCompra(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = _num(t);
    if (n == null) return 'Debe ser un número';
    if (n < 0) return 'No puede ser negativo';
    final venta = _num(_precioVenta.text);
    if (venta != null && n > venta) return 'Es mayor que el precio de venta';
    return null;
  }

  String? _vStock(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El stock es obligatorio';
    final n = int.tryParse(t);
    if (n == null) return 'Debe ser un entero';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  String? _vMinimo(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return 'Debe ser un entero';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  // ---------------------------------- UI -------------------------------------

  Widget _fila(bool ancho, List<Widget> hijos) {
    if (!ancho) {
      return Column(
        children: [
          for (var k = 0; k < hijos.length; k++) ...[
            if (k > 0) const SizedBox(height: 14),
            hijos[k],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var k = 0; k < hijos.length; k++) ...[
          if (k > 0) const SizedBox(width: 14),
          Expanded(child: hijos[k]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = TextStyle(
      color: context.tinta,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
    final precioFmt = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}[.,]?\d{0,2}')),
    ];
    final enteroFmt = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(7),
    ];

    return LayoutBuilder(
      builder: (context, caja) {
        final ancho = caja.maxWidth >= 520;
        return Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fila(ancho, [
                TextFormField(
                  controller: _codigo,
                  style: texto,
                  textCapitalization: TextCapitalization.characters,
                  decoration: decoCampo(context, 'Código *', Icons.qr_code_2_rounded),
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  validator: _vCodigo,
                ),
                TextFormField(
                  controller: _marca,
                  style: texto,
                  decoration: decoCampo(context, 'Marca', Icons.sell_outlined),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                ),
              ]),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nombre,
                style: texto,
                decoration:
                    decoCampo(context, 'Nombre *', Icons.inventory_2_outlined),
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                validator: _vNombre,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descripcion,
                style: texto,
                maxLines: 2,
                maxLength: 200,
                decoration:
                    decoCampo(context, 'Descripción', Icons.notes_rounded),
              ),
              const SizedBox(height: 6),
              _fila(ancho, [
                TextFormField(
                  controller: _precioVenta,
                  style: texto,
                  decoration: decoCampo(
                    context,
                    'Precio de venta *',
                    Icons.payments_outlined,
                    prefijo: 'S/ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: precioFmt,
                  validator: _vVenta,
                  onChanged: (_) {
                    if (_precioCompra.text.isNotEmpty) {
                      _kCompra.currentState?.validate();
                    }
                  },
                ),
                TextFormField(
                  key: _kCompra,
                  controller: _precioCompra,
                  style: texto,
                  decoration: decoCampo(
                    context,
                    'Precio de compra',
                    Icons.shopping_cart_outlined,
                    prefijo: 'S/ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: precioFmt,
                  validator: _vCompra,
                ),
              ]),
              const SizedBox(height: 14),
              _fila(ancho, [
                TextFormField(
                  controller: _stock,
                  style: texto,
                  decoration: decoCampo(context, 'Stock *', Icons.layers_outlined),
                  keyboardType: TextInputType.number,
                  inputFormatters: enteroFmt,
                  validator: _vStock,
                ),
                TextFormField(
                  controller: _stockMinimo,
                  style: texto,
                  decoration: decoCampo(
                    context,
                    'Stock mínimo',
                    Icons.notification_important_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: enteroFmt,
                  validator: _vMinimo,
                ),
                TextFormField(
                  controller: _unidad,
                  style: texto,
                  decoration:
                      decoCampo(context, 'Unidad', Icons.straighten_rounded),
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                ),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _intentoFallido
                    ? const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Aviso(
                          texto: 'Revisa los campos marcados en rojo antes de guardar.',
                          error: true,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '* Obligatorio',
                    style: TextStyle(fontSize: 12, color: context.tenue),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _guardando ? null : widget.onCancelar,
                    style: TextButton.styleFrom(
                      foregroundColor: context.tenue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Tono.acento,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _guardando
                          ? const SizedBox(
                              key: ValueKey('c'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.textoGuardar,
                              key: const ValueKey('t'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
