import 'package:flutter/material.dart';

import 'admin_store.dart';
import 'admin_ui.dart';

/// Productos activos (visibles en la tienda) que necesitan atención de stock.
List<ItemProducto> productosAgotados(AdminStore store) {
  final out = <ItemProducto>[];
  for (final i in store.productos) {
    if (i.enPapelera || !i.activo) continue;
    if (i.p.agotado) out.add(i);
  }
  out.sort((a, b) => a.p.nombre.toLowerCase().compareTo(b.p.nombre.toLowerCase()));
  return out;
}

/// Todavía hay unidades, pero ya están en el mínimo o por debajo.
List<ItemProducto> productosPorAcabarse(AdminStore store) {
  final out = <ItemProducto>[];
  for (final i in store.productos) {
    if (i.enPapelera || !i.activo) continue;
    if (i.p.critico) out.add(i);
  }
  out.sort((a, b) {
    final s = a.p.stock.compareTo(b.p.stock);
    if (s != 0) return s;
    return a.p.nombre.toLowerCase().compareTo(b.p.nombre.toLowerCase());
  });
  return out;
}

/// Cuadro de aviso del inicio. Solo se construye cuando hay productos que mostrar.
class CuadroAlertaStock extends StatelessWidget {
  const CuadroAlertaStock({
    super.key,
    required this.urgente,
    required this.cantidad,
    required this.onTap,
  });

  /// Rojo = sin stock. Naranja = a punto de acabarse.
  final bool urgente;
  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = urgente ? Tono.peligro : const Color(0xFFE07A00);
    final titulo = urgente ? 'Urgente: reponer stock' : 'Prevenir';
    final detalle = urgente
        ? (cantidad == 1
            ? '1 producto sin stock'
            : '$cantidad productos sin stock')
        : (cantidad == 1
            ? '1 producto a punto de acabarse'
            : '$cantidad productos a punto de acabarse');

    return _CajaPulsante(
      color: color,
      onTap: onTap,
      child: Row(
        children: [
          _SimboloAdvertencia(color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.tinta,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detalle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: color, size: 22),
        ],
      ),
    );
  }
}

/// Lista completa de los productos de una alerta.
class ListaAlertaStock extends StatelessWidget {
  const ListaAlertaStock({
    super.key,
    required this.store,
    required this.urgente,
    required this.onAbrir,
  });

  final AdminStore store;
  final bool urgente;
  final void Function(BuildContext context, ItemProducto item) onAbrir;

  @override
  Widget build(BuildContext context) {
    final color = urgente ? Tono.peligro : const Color(0xFFE07A00);
    final titulo =
        urgente ? 'Urgente: reponer stock' : 'Prevenir: a punto de acabarse';

    return Scaffold(
      backgroundColor: context.fondo,
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final lista =
              urgente ? productosAgotados(store) : productosPorAcabarse(store);
          final ancho = MediaQuery.sizeOf(context).width;
          final pad = ancho < 700 ? 16.0 : 32.0;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Volver',
                        style: IconButton.styleFrom(
                          backgroundColor: context.panel,
                          side: BorderSide(color: context.linea),
                        ),
                        icon: Icon(Icons.arrow_back_rounded, color: context.tinta),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _SimboloAdvertencia(color: color, grande: true),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    color: context.tinta,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lista.isEmpty
                                      ? 'Ya no hay productos en esta alerta.'
                                      : (urgente
                                          ? 'Estos productos están en cero. Hay que reponerlos.'
                                          : 'Todavía hay unidades, pero ya llegaron al stock mínimo.'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.tenue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
              if (lista.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Vacio(
                    icono: Icons.inventory_2_outlined,
                    titulo: 'Lista vacía',
                    detalle: urgente
                        ? 'Ningún producto activo está sin stock.'
                        : 'Ningún producto activo está por acabarse.',
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 40),
                  sliver: SliverList.separated(
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = lista[i];
                      return Aparece(
                        indice: i > 6 ? 6 : i,
                        child: _FilaProducto(
                          item: item,
                          color: color,
                          urgente: urgente,
                          onTap: () => onAbrir(context, item),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.item,
    required this.color,
    required this.urgente,
    required this.onTap,
  });

  final ItemProducto item;
  final Color color;
  final bool urgente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = item.p;
    final estado = urgente
        ? 'Sin stock'
        : 'Quedan ${p.stock} ${p.unidad} · mínimo ${p.stockMinimo}';

    return Tarjeta(
      onTap: onTap,
      radio: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              inicial(p.nombre),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: context.tinta,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${p.codigo} · ${p.marca}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: context.tenue),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.stock}',
                style: estiloNum(context, size: 20, color: color),
              ),
              Text(
                estado,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CajaPulsante extends StatefulWidget {
  const _CajaPulsante({
    required this.color,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_CajaPulsante> createState() => _CajaPulsanteState();
}

class _CajaPulsanteState extends State<_CajaPulsante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  bool _hover = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_c.value);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  widget.color.withOpacity(0.10 + 0.06 * t),
                  context.panel,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withOpacity(0.55 + 0.35 * t),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.12 + 0.22 * t),
                    blurRadius: 18 + 10 * t,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Triángulo de advertencia que late y emite un halo.
class _SimboloAdvertencia extends StatefulWidget {
  const _SimboloAdvertencia({required this.color, this.grande = false});

  final Color color;
  final bool grande;

  @override
  State<_SimboloAdvertencia> createState() => _SimboloAdvertenciaState();
}

class _SimboloAdvertenciaState extends State<_SimboloAdvertencia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.grande ? 52.0 : 44.0;
    final icono = widget.grande ? 30.0 : 26.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return SizedBox(
          width: base + 8,
          height: base + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: base + 8 * t,
                height: base + 8 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.22 * (1 - t * 0.35)),
                ),
              ),
              Transform.scale(
                scale: 1 + 0.08 * t,
                child: Icon(
                  Icons.warning_rounded,
                  color: widget.color,
                  size: icono,
                  shadows: [
                    Shadow(
                      color: widget.color.withOpacity(0.55),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
