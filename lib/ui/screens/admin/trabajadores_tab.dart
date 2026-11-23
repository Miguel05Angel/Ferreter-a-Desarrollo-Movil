import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/venta.dart';
import 'admin_store.dart';
import 'admin_ui.dart';
import 'calendario_rango.dart';

/// Ventas de un trabajador dentro del período elegido.
class _Rendimiento {
  _Rendimiento(this.t);

  final Trabajador t;
  int ventas = 0;
  double total = 0;

  double get promedio => ventas == 0 ? 0 : total / ventas;
}

class TrabajadoresTab extends StatefulWidget {
  const TrabajadoresTab({super.key, required this.store});

  final AdminStore store;

  @override
  State<TrabajadoresTab> createState() => _TrabajadoresTabState();
}

class _TrabajadoresTabState extends State<TrabajadoresTab> {
  String _q = '';
  int _rol = 0; // 0 todos, 1 administradores, 2 vendedores
  RangoFechas? _rango;

  String _norm(String s) => s.trim().toLowerCase();

  List<_Rendimiento> _calcular(AdminStore s) {
    final porId = <String, _Rendimiento>{};
    final porNombre = <String, _Rendimiento>{};
    final todos = <_Rendimiento>[];
    for (final t in s.trabajadores) {
      final r = _Rendimiento(t);
      todos.add(r);
      porId[t.id] = r;
      porNombre[_norm(t.nombre)] = r;
    }
    for (final Venta v in s.ventas) {
      if (_rango != null && !_rango!.contiene(v.fecha)) continue;
      final r = porId[v.vendedorId] ?? porNombre[_norm(v.vendedor)];
      if (r == null) continue;
      r.ventas++;
      r.total += v.total;
    }
    return todos;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final s = widget.store;
        if (s.trabajadoresError != null) {
          return Padding(
            padding: const EdgeInsets.only(top: kNavAlto),
            child: ErrorCaja(
              error: s.trabajadoresError!,
              explicacion:
                  'Las reglas de Firestore no permiten listar la colección '
                  '"${AdminStore.colUsuarios}". Agrega una regla que deje a '
                  'los administradores leerla.',
            ),
          );
        }
        if (!s.trabajadoresListo) return const Cargando();

        final admins = s.trabajadores.where((t) => t.esAdmin).length;
        final vendedores = s.trabajadores.length - admins;
        final activos = s.trabajadores.where((t) => t.activo).length;

        final q = _q.trim().toLowerCase();
        final todos = _calcular(s);
        final lista = todos.where((r) {
          if (_rol == 1 && !r.t.esAdmin) return false;
          if (_rol == 2 && r.t.esAdmin) return false;
          if (q.isNotEmpty &&
              !'${r.t.nombre} ${r.t.dni} ${r.t.email}'.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        }).toList()
          ..sort((a, b) => b.total.compareTo(a.total));

        final mejor = todos.fold<double>(0, (m, r) => math.max(m, r.total));
        final ventasPeriodo = todos.fold<int>(0, (a, r) => a + r.ventas);
        final totalPeriodo = todos.fold<double>(0, (a, r) => a + r.total);

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
                        titulo: 'Cantidad de trabajadores',
                        subtitulo:
                            'Personal registrado y rendimiento de ventas',
                      ),
                    ),
                    const SizedBox(height: 22),
                    Aparece(
                      indice: 1,
                      child: _Resumen(
                        total: s.trabajadores.length,
                        admins: admins,
                        vendedores: vendedores,
                        activos: activos,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Aparece(
                      indice: 2,
                      child: LayoutBuilder(
                        builder: (context, caja) {
                          final cols = caja.maxWidth >= 640 ? 2 : 1;
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
                                      ? 'Ventas del equipo'
                                      : 'Ventas del período',
                                  valor: ventasPeriodo.toDouble(),
                                  formato: entero,
                                  color: Tono.violeta,
                                  nota: 'Atribuidas a un trabajador',
                                ),
                              ),
                              SizedBox(
                                width: w,
                                child: Kpi(
                                  titulo: 'Total vendido por el equipo',
                                  valor: totalPeriodo,
                                  formato: soles,
                                  color: Tono.ok,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Aparece(
                      indice: 3,
                      child: LayoutBuilder(
                        builder: (context, caja) {
                          final buscador = BuscadorCampo(
                            hint: 'Buscar por nombre, DNI o correo…',
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
                      indice: 4,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Segmentos(
                          items: [
                            SegItem(
                                texto: 'Todos', contador: s.trabajadores.length),
                            SegItem(texto: 'Admins', contador: admins),
                            SegItem(texto: 'Vendedores', contador: vendedores),
                          ],
                          indice: _rol,
                          anchoItem: 124,
                          onCambio: (v) => setState(() => _rol = v),
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
                  icono: Icons.groups_outlined,
                  titulo: s.trabajadores.isEmpty
                      ? 'Aún no hay trabajadores'
                      : 'Sin resultados',
                  detalle: s.trabajadores.isEmpty
                      ? 'Los usuarios registrados en la app aparecerán aquí.'
                      : 'Prueba con otra búsqueda o filtro.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 90),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 214,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, k) {
                      final r = lista[k];
                      return Aparece(
                        key: ValueKey('w-${r.t.id}'),
                        indice: math.min(k, 8),
                        child: _TarjetaTrabajador(
                          r: r,
                          puesto: r.ventas > 0 && _rol == 0 && _q.isEmpty
                              ? k + 1
                              : null,
                          relativo: mejor <= 0 ? 0 : r.total / mejor,
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

class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.total,
    required this.admins,
    required this.vendedores,
    required this.activos,
  });

  final int total;
  final int admins;
  final int vendedores;
  final int activos;

  @override
  Widget build(BuildContext context) {
    Widget dato(String t, int n, Color c) {
      return Padding(
        padding: const EdgeInsets.only(right: 28, top: 6, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.tenue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$n',
              style: estiloNum(context, size: 22, peso: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Tarjeta(
      elevarAlHover: false,
      radio: 20,
      padding: const EdgeInsets.all(26),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 14,
        spacing: 40,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trabajadores registrados',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.tenue,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: total.toDouble()),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (c, v, _) => Text(
                  '${v.round()}',
                  style: estiloNum(c, size: 64, peso: FontWeight.w800)
                      .copyWith(letterSpacing: -3, height: 1.05),
                ),
              ),
            ],
          ),
          Wrap(
            children: [
              dato('Administradores', admins, Tono.acento),
              dato('Vendedores', vendedores, Tono.info),
              dato('Activos', activos, Tono.ok),
              dato('Inactivos', total - activos, Tono.peligro),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaTrabajador extends StatelessWidget {
  const _TarjetaTrabajador({
    required this.r,
    required this.relativo,
    this.puesto,
  });

  final _Rendimiento r;
  final double relativo;
  final int? puesto;

  @override
  Widget build(BuildContext context) {
    final t = r.t;
    final color = t.esAdmin ? Tono.acento : Tono.info;
    final medalla = puesto != null && puesto! <= 3;

    return Tarjeta(
      elevarAlHover: false,
      radio: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  inicial(t.nombre),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: context.tinta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        Etiqueta(t.rol, color, punto: false),
                        if (!t.activo) Etiqueta('Inactivo', context.tenue),
                      ],
                    ),
                  ],
                ),
              ),
              if (medalla)
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Tono.alerta.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$puesto',
                    style: const TextStyle(
                      color: Tono.alerta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (t.dni.isNotEmpty) 'DNI ${t.dni}',
              if (t.email.isNotEmpty) t.email,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: context.tenue),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _Cifra(titulo: 'Ventas', valor: '${r.ventas}'),
              ),
              Expanded(
                child: _Cifra(titulo: 'Vendido', valor: soles(r.total)),
              ),
              Expanded(
                child: _Cifra(titulo: 'Ticket', valor: soles(r.promedio)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: relativo.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                color: color,
                backgroundColor: color.withOpacity(0.14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.tenue,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: estiloNum(context, size: 14.5, peso: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
