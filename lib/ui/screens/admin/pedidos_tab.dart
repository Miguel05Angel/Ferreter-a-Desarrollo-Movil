import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'admin_store.dart';
import 'admin_ui.dart';
import 'calendario_rango.dart';

Color _colorEstado(EstadoPedido e) => switch (e) {
      EstadoPedido.pendiente => Tono.alerta,
      EstadoPedido.cotizado => Tono.info,
      EstadoPedido.ordenado => Tono.ok,
    };

String _nombreEstado(EstadoPedido e) => switch (e) {
      EstadoPedido.pendiente => 'Sin cotizar',
      EstadoPedido.cotizado => 'Cotizado',
      EstadoPedido.ordenado => 'Ordenado',
    };

bool _vencido(Pedido p) =>
    p.estado == EstadoPedido.pendiente &&
    p.respuestaAntes != null &&
    p.respuestaAntes!.isBefore(DateTime.now());

class PedidosTab extends StatefulWidget {
  const PedidosTab({super.key, required this.store});

  final AdminStore store;

  @override
  State<PedidosTab> createState() => _PedidosTabState();
}

class _PedidosTabState extends State<PedidosTab> {
  String _q = '';
  int _estado = 0; // 0 todos, 1 pendiente, 2 cotizado, 3 ordenado
  RangoFechas? _rango;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final s = widget.store;
        if (s.pedidosError != null) {
          return Padding(
            padding: const EdgeInsets.only(top: kNavAlto),
            child: ErrorCaja(
              error: s.pedidosError!,
              explicacion:
                  'Agrega una regla en firestore.rules que permita a los '
                  'administradores leer la colección '
                  '"${AdminStore.colPedidos}".',
            ),
          );
        }
        if (!s.pedidosListo) return const Cargando();

        var pend = 0, cot = 0, ord = 0;
        for (final p in s.pedidos) {
          switch (p.estado) {
            case EstadoPedido.pendiente:
              pend++;
            case EstadoPedido.cotizado:
              cot++;
            case EstadoPedido.ordenado:
              ord++;
          }
        }

        final q = _q.trim().toLowerCase();
        final lista = <Pedido>[];
        for (final p in s.pedidos) {
          if (_estado == 1 && p.estado != EstadoPedido.pendiente) continue;
          if (_estado == 2 && p.estado != EstadoPedido.cotizado) continue;
          if (_estado == 3 && p.estado != EstadoPedido.ordenado) continue;
          if (_rango != null && !_rango!.contiene(p.fecha)) continue;
          if (q.isNotEmpty &&
              !'${p.numero} ${p.proveedor} ${p.descripcion} ${p.codigo}'
                  .toLowerCase()
                  .contains(q)) {
            continue;
          }
          lista.add(p);
        }

        final ancho = MediaQuery.sizeOf(context).width;
        final pad = ancho < 700 ? 16.0 : 32.0;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, kNavAlto + 14, pad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Aparece(
                      child: EncabezadoPagina(
                        titulo: 'Pedidos a proveedores',
                        subtitulo:
                            'Seguimiento de cotizaciones y órdenes de compra',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Aparece(
                      indice: 1,
                      child: LayoutBuilder(
                        builder: (context, caja) {
                          final cols = caja.maxWidth >= 980
                              ? 4
                              : caja.maxWidth >= 560
                                  ? 2
                                  : 1;
                          const gap = 14.0;
                          final w = (caja.maxWidth - gap * (cols - 1)) / cols;
                          Widget k(String t, int n, Color c, String nota) =>
                              SizedBox(
                                width: w,
                                child: Kpi(
                                  titulo: t,
                                  valor: n.toDouble(),
                                  formato: entero,
                                  color: c,
                                  nota: nota,
                                ),
                              );
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              k('Pedidos', s.pedidos.length, Tono.violeta,
                                  'Registrados en total'),
                              k('Sin cotizar', pend, Tono.alerta,
                                  'Esperan respuesta'),
                              k('Cotizados', cot, Tono.info,
                                  'Listos para ordenar'),
                              k('Ordenados', ord, Tono.ok, 'Compra emitida'),
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
                            hint: 'Buscar por número, proveedor o producto…',
                            onChanged: (v) => setState(() => _q = v),
                          );
                          final fechas = BotonFechas(
                            valor: _rango,
                            onCambio: (r) => setState(() => _rango = r),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Segmentos(
                          items: [
                            SegItem(texto: 'Todos', contador: s.pedidos.length),
                            SegItem(texto: 'Sin cotizar', contador: pend),
                            SegItem(texto: 'Cotizados', contador: cot),
                            SegItem(texto: 'Ordenados', contador: ord),
                          ],
                          indice: _estado,
                          anchoItem: 132,
                          onCambio: (v) => setState(() => _estado = v),
                        ),
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
                  icono: Icons.local_shipping_outlined,
                  titulo: s.pedidos.isEmpty
                      ? 'Aún no hay pedidos a proveedores'
                      : 'Sin resultados',
                  detalle: s.pedidos.isEmpty
                      ? 'Aparecerán aquí cuando la app móvil guarde las '
                          'solicitudes en la colección "${AdminStore.colPedidos}".'
                      : 'Prueba con otra búsqueda, fecha o estado.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, k) {
                      final p = lista[k];
                      return Aparece(
                        key: ValueKey('p-${p.id}'),
                        indice: math.min(k, 8),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TarjetaPedido(
                            p: p,
                            onTap: () => dialogo<void>(
                              context,
                              (_) => _DetallePedido(p: p),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: lista.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({required this.p, required this.onTap});

  final Pedido p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(p.estado);
    return Tarjeta(
      onTap: onTap,
      radio: 16,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, caja) {
          final ancho = caja.maxWidth >= 720;
          return Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.proveedor.isEmpty ? 'Proveedor sin nombre' : p.proveedor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: context.tinta,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.descripcion.isEmpty
                          ? p.numero
                          : '${p.numero} · ${p.descripcion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: context.tenue),
                    ),
                  ],
                ),
              ),
              if (ancho)
                Expanded(
                  flex: 2,
                  child: Text(
                    p.cantidad > 0 ? '${p.cantidad} ${p.unidad}' : '—',
                    style: estiloNum(
                      context,
                      size: 13.5,
                      peso: FontWeight.w700,
                      color: context.tinta,
                    ),
                  ),
                ),
              if (ancho)
                Expanded(
                  flex: 2,
                  child: Text(
                    p.fecha == null ? '—' : fechaTxt(p.fecha!),
                    style: estiloNum(
                      context,
                      size: 13,
                      peso: FontWeight.w600,
                      color: context.tenue,
                    ),
                  ),
                ),
              Wrap(
                spacing: 6,
                children: [
                  if (_vencido(p)) const Etiqueta('Vencido', Tono.peligro),
                  Etiqueta(_nombreEstado(p.estado), color),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: context.tenue),
            ],
          );
        },
      ),
    );
  }
}

class _DetallePedido extends StatelessWidget {
  const _DetallePedido({required this.p});

  final Pedido p;

  @override
  Widget build(BuildContext context) {
    Widget fila(String t, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(t, style: TextStyle(color: context.tenue, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                v.isEmpty ? '—' : v,
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

    final color = _colorEstado(p.estado);
    final filas = <Widget>[
      fila('Proveedor', p.proveedor),
      fila('Producto', p.descripcion),
      fila('Código', p.codigo),
      fila('Cantidad', p.cantidad > 0 ? '${p.cantidad} ${p.unidad}' : ''),
      fila('Solicitante', p.solicitante),
      fila('Fecha', p.fecha == null ? '' : fechaTxt(p.fecha!)),
      fila('Responder antes de',
          p.respuestaAntes == null ? '' : fechaTxt(p.respuestaAntes!)),
      if (p.total != null) fila('Total', soles(p.total!)),
    ];

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
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.numero,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: context.tinta,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            Etiqueta(_nombreEstado(p.estado), color),
                            if (_vencido(p)) const Etiqueta('Vencido', Tono.peligro),
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
            Divider(height: 1, color: context.linea),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Column(
                  children: [
                    for (var k = 0; k < filas.length; k++) ...[
                      filas[k],
                      if (k < filas.length - 1)
                        Divider(height: 1, color: context.linea),
                    ],
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
