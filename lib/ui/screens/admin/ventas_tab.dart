import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/venta.dart';
import 'admin_store.dart';
import 'admin_ui.dart';
import 'calendario_rango.dart';

class VentasTab extends StatefulWidget {
  const VentasTab({super.key, required this.store});

  final AdminStore store;

  @override
  State<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends State<VentasTab> {
  static const _pagina = 60;

  final _scroll = ScrollController();
  String _q = '';
  String? _metodo;
  RangoFechas? _rango;
  int _visibles = _pagina;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 700 && _visibles < _total) {
        setState(() => _visibles += _pagina);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _cambiar(VoidCallback f) => setState(() {
        f();
        _visibles = _pagina;
      });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final s = widget.store;
        if (s.ventasError != null) {
          return Padding(
            padding: const EdgeInsets.only(top: kNavAlto),
            child: ErrorCaja(error: s.ventasError!),
          );
        }
        if (!s.ventasListo) return const Cargando();

        final metodos = s.ventas.map((v) => v.metodoPago).toSet().toList()..sort();
        final q = _q.trim().toLowerCase();
        final lista = <Venta>[];
        var total = 0.0;
        for (final v in s.ventas) {
          if (_metodo != null && v.metodoPago != _metodo) continue;
          if (_rango != null && !_rango!.contiene(v.fecha)) continue;
          if (q.isNotEmpty &&
              !'${v.comprobante} ${v.numero} ${v.clienteNombre} ${v.vendedor}'
                  .toLowerCase()
                  .contains(q)) {
            continue;
          }
          lista.add(v);
          total += v.total;
        }
        _total = lista.length;
        final promedio = lista.isEmpty ? 0.0 : total / lista.length;
        final visibles = math.min(lista.length, _visibles);
        final ancho = MediaQuery.sizeOf(context).width;
        final pad = ancho < 700 ? 16.0 : 32.0;

        return CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, kNavAlto + 14, pad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Aparece(
                      child: EncabezadoPagina(
                        titulo: 'Ventas',
                        subtitulo:
                            '${s.ventas.length} comprobantes · actualizado en tiempo real',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Aparece(
                      indice: 1,
                      child: LayoutBuilder(
                        builder: (context, caja) {
                          final cols = caja.maxWidth >= 760 ? 3 : 1;
                          const gap = 14.0;
                          final w = (caja.maxWidth - gap * (cols - 1)) / cols;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: w,
                                child: Kpi(
                                  titulo: _rango == null
                                      ? 'Total vendido'
                                      : 'Total del período',
                                  valor: total,
                                  formato: soles,
                                  color: Tono.ok,
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: Kpi(
                                  titulo: 'Comprobantes',
                                  valor: lista.length.toDouble(),
                                  formato: entero,
                                  color: Tono.violeta,
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: Kpi(
                                  titulo: 'Ticket promedio',
                                  valor: promedio,
                                  formato: soles,
                                  color: Tono.info,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Aparece(
                      indice: 2,
                      child: LayoutBuilder(
                        builder: (context, caja) {
                          final buscador = BuscadorCampo(
                            hint: 'Buscar por cliente, vendedor o comprobante…',
                            onChanged: (v) => _cambiar(() => _q = v),
                          );
                          final fechas = BotonFechas(
                            valor: _rango,
                            onCambio: (r) => _cambiar(() => _rango = r),
                          );
                          if (caja.maxWidth < 640) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buscador,
                                const SizedBox(height: 10),
                                fechas,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: buscador),
                              const SizedBox(width: 12),
                              fechas,
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Aparece(
                      indice: 3,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Pildora(
                            texto: 'Todos los pagos',
                            activo: _metodo == null,
                            onTap: () => _cambiar(() => _metodo = null),
                          ),
                          for (final m in metodos)
                            Pildora(
                              texto: m,
                              activo: _metodo == m,
                              onTap: () => _cambiar(() => _metodo = m),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (lista.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Vacio(
                  icono: Icons.receipt_long_outlined,
                  titulo: s.ventas.isEmpty
                      ? 'Todavía no hay ventas'
                      : 'Sin resultados',
                  detalle: s.ventas.isEmpty
                      ? 'Cuando se emita un comprobante aparecerá aquí.'
                      : 'Prueba con otra búsqueda, fecha o método de pago.',
                ),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                sliver: const SliverToBoxAdapter(child: _CabeceraVentas()),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                sliver: SliverFixedExtentList(
                  itemExtent: 66,
                  delegate: SliverChildBuilderDelegate(
                    (context, k) {
                      final v = lista[k];
                      return Aparece(
                        key: ValueKey('v-${v.id}'),
                        indice: math.min(k, 10),
                        child: _FilaVenta(
                          v: v,
                          ultima: k == visibles - 1,
                          onTap: () => dialogo<void>(
                            context,
                            (_) => _DetalleVenta(v: v),
                          ),
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
}

class _CabeceraVentas extends StatelessWidget {
  const _CabeceraVentas();

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
          final ancho = caja.maxWidth >= 860;
          return Row(
            children: [
              Expanded(flex: 4, child: Text('COMPROBANTE', style: estilo())),
              if (ancho) Expanded(flex: 2, child: Text('FECHA', style: estilo())),
              if (ancho) Expanded(flex: 2, child: Text('VENDEDOR', style: estilo())),
              if (ancho) Expanded(flex: 2, child: Text('PAGO', style: estilo())),
              Expanded(
                flex: 2,
                child: Text('TOTAL', textAlign: TextAlign.right, style: estilo()),
              ),
              const SizedBox(width: 30),
            ],
          );
        },
      ),
    );
  }
}

class _FilaVenta extends StatefulWidget {
  const _FilaVenta({required this.v, required this.ultima, required this.onTap});

  final Venta v;
  final bool ultima;
  final VoidCallback onTap;

  @override
  State<_FilaVenta> createState() => _FilaVentaState();
}

class _FilaVentaState extends State<_FilaVenta> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.v;
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
              final ancho = caja.maxWidth >= 860;
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Tono.violeta.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              size: 19, color: Tono.violeta),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.clienteNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: context.tinta,
                                ),
                              ),
                              Text(
                                ancho
                                    ? '${v.comprobante} ${v.numero}'
                                    : '${v.comprobante} ${v.numero} · ${fechaTxt(v.fecha)}',
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
                  if (ancho)
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${fechaTxt(v.fecha)}  ${horaTxt(v.fecha)}',
                        style: estiloNum(
                          context,
                          size: 13,
                          peso: FontWeight.w600,
                          color: context.tenue,
                        ),
                      ),
                    ),
                  if (ancho)
                    Expanded(
                      flex: 2,
                      child: Text(
                        v.vendedor.isEmpty ? '—' : v.vendedor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.tenue, fontSize: 13.5),
                      ),
                    ),
                  if (ancho)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Etiqueta(v.metodoPago, Tono.info, punto: false),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      soles(v.total),
                      textAlign: TextAlign.right,
                      style: estiloNum(context, size: 15, peso: FontWeight.w800),
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

class _DetalleVenta extends StatelessWidget {
  const _DetalleVenta({required this.v});

  final Venta v;

  @override
  Widget build(BuildContext context) {
    Widget dato(String t, String valor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(t, style: TextStyle(color: context.tenue, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: context.tinta,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget resumen(String t, double valor, {bool fuerte = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              t,
              style: TextStyle(
                color: fuerte ? context.tinta : context.tenue,
                fontWeight: fuerte ? FontWeight.w800 : FontWeight.w500,
                fontSize: fuerte ? 15 : 13,
              ),
            ),
            const Spacer(),
            Text(
              soles(valor),
              style: estiloNum(
                context,
                size: fuerte ? 22 : 13.5,
                peso: fuerte ? FontWeight.w800 : FontWeight.w600,
              ).copyWith(letterSpacing: fuerte ? -0.5 : 0),
            ),
          ],
        ),
      );
    }

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
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Tono.violeta.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Tono.violeta),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v.comprobante} ${v.numero}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: context.tinta,
                          ),
                        ),
                        Text(
                          '${fechaTxt(v.fecha)} · ${horaTxt(v.fecha)}',
                          style: estiloNum(
                            context,
                            size: 12.5,
                            peso: FontWeight.w600,
                            color: context.tenue,
                          ),
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
            Divider(height: 1, color: context.linea),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dato('Cliente', v.clienteNombre),
                    dato('Vendedor', v.vendedor.isEmpty ? '—' : v.vendedor),
                    dato('Método de pago', v.metodoPago),
                    const SizedBox(height: 10),
                    Text(
                      'PRODUCTOS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: context.tenue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final i in v.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: context.tinta,
                                    ),
                                  ),
                                  Text(
                                    '${i.cantidad} × ${soles(i.precioUnitario)}',
                                    style: estiloNum(
                                      context,
                                      size: 12.5,
                                      peso: FontWeight.w500,
                                      color: context.tenue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              soles(i.cantidad * i.precioUnitario),
                              style: estiloNum(context, size: 14, peso: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: BoxDecoration(
                color: context.panel2,
                border: Border(top: BorderSide(color: context.linea)),
              ),
              child: Column(
                children: [
                  resumen('Subtotal', v.subtotal),
                  resumen('IGV', v.igv),
                  const SizedBox(height: 4),
                  resumen('Total', v.total, fuerte: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
