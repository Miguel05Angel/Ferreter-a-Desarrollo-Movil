import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/categoria.dart';
import '../../../data/models/producto.dart';

/// Filtros activos del catalogo: marcas, tipos y rango de presupuesto.
/// (La categoria se elige en el mismo panel, pero la aplica la pantalla.)
class FiltrosCatalogo {
  final Set<String> marcas;
  final Set<String> tipos;
  final RangeValues? rango;

  const FiltrosCatalogo({
    this.marcas = const {},
    this.tipos = const {},
    this.rango,
  });

  bool get activo => marcas.isNotEmpty || tipos.isNotEmpty || rango != null;
  int get cantidad =>
      (marcas.isNotEmpty ? 1 : 0) + (tipos.isNotEmpty ? 1 : 0) + (rango != null ? 1 : 0);

  /// [techo] es el maximo del deslizador: si el rango llega ahi significa
  /// "S/ X a mas" (sin limite superior).
  bool acepta(Producto p, double techo) {
    if (marcas.isNotEmpty && !marcas.contains(p.marca)) return false;
    if (tipos.isNotEmpty && !tipos.contains(p.tipoLabel)) return false;
    final r = rango;
    if (r != null) {
      if (p.precioVenta < r.start) return false;
      if (r.end < techo && p.precioVenta > r.end) return false;
    }
    return true;
  }

  /// Limite minimo del deslizador. En una ferreteria el ticket es alto
  /// (fierro, cemento, herramientas electricas), por eso llega a S/ 5,000+.
  /// Cambia este valor para ajustar el tope.
  static const double techoMinimo = 5000;

  /// Salto del deslizador (S/).
  static const double paso = 50;

  /// Maximo del deslizador para un conjunto de productos.
  static double techoDe(Iterable<Producto> productos) {
    var maximo = 0.0;
    for (final p in productos) {
      if (p.precioVenta > maximo) maximo = p.precioVenta;
    }
    final techo = (maximo / 500).ceil() * 500.0;
    return techo < techoMinimo ? techoMinimo : techo;
  }
}

/// Lo que devuelve el panel: categoria elegida ('todas' si ninguna) + filtros.
class ResultadoFiltros {
  final String categoriaId;
  final FiltrosCatalogo filtros;
  const ResultadoFiltros(this.categoriaId, this.filtros);
}

String _miles(double v) => v
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

/// Abre el panel de filtros con un orden logico:
///   1. Categoria  ->  2. Marca (solo las de esa categoria)  ->  3. Presupuesto
/// y un boton explicito "Mostrar todo" para limpiar todo.
/// Devuelve el resultado SOLO si el usuario pulsa "Aplicar filtros".
Future<ResultadoFiltros?> mostrarFiltrosCatalogo(
  BuildContext context, {
  required List<Producto> todos,
  required List<Categoria> categorias,
  required String categoriaActual,
  required FiltrosCatalogo actual,
}) {
  final techo = FiltrosCatalogo.techoDe(todos);

  return showModalBottomSheet<ResultadoFiltros>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) {
      var cat = categoriaActual;
      var marcasSel = {...actual.marcas};
      var tiposSel = {...actual.tipos};
      var rango = actual.rango ?? RangeValues(0, techo);

      return StatefulBuilder(
        builder: (context, setSheet) {
          final enCategoria = cat == 'todas'
              ? todos
              : todos.where((p) => p.categoriaId == cat).toList();
          final conteo = <String, int>{};
          for (final p in enCategoria) {
            conteo[p.marca] = (conteo[p.marca] ?? 0) + 1;
          }
          final marcas = conteo.keys.toList()..sort();

          final haciaMas = rango.end >= techo;
          final etiquetaRango =
              'S/ ${_miles(rango.start)}  -  S/ ${_miles(rango.end)}${haciaMas ? '+' : ''}';
          final hayCambios = cat != 'todas' ||
              marcasSel.isNotEmpty ||
              tiposSel.isNotEmpty ||
              rango.start > 0 ||
              rango.end < techo;

          Widget titulo(String numero, String t, {String? nota}) => Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle),
                      child: Text(numero,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.grafito)),
                    ),
                    const SizedBox(width: 10),
                    Text(t,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w900)),
                    if (nota != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(nota,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ),
                    ],
                  ],
                ),
              );

          void mostrarTodo() => setSheet(() {
                cat = 'todas';
                marcasSel = {};
                tiposSel = {};
                rango = RangeValues(0, techo);
              });

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('FILTRAR PRODUCTOS',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: hayCambios ? 1 : 0.45,
                          child: TextButton.icon(
                            onPressed: hayCambios ? mostrarTodo : null,
                            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                            label: const Text('MOSTRAR TODO'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titulo('1', 'CATEGORÍA'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Todas'),
                                selected: cat == 'todas',
                                onSelected: (_) => setSheet(() {
                                  cat = 'todas';
                                }),
                              ),
                              for (final c in categorias)
                                ChoiceChip(
                                  avatar: Icon(c.icono, size: 16, color: c.color),
                                  label: Text(c.nombre),
                                  selected: cat == c.id,
                                  onSelected: (_) => setSheet(() {
                                    cat = c.id;
                                    // Marcas que ya no pertenecen a la categoria.
                                    final validas = todos
                                        .where((p) => p.categoriaId == c.id)
                                        .map((p) => p.marca)
                                        .toSet();
                                    marcasSel = marcasSel.intersection(validas);
                                  }),
                                ),
                            ],
                          ),
                          titulo('2', 'MARCA',
                              nota: cat == 'todas'
                                  ? 'Elige una categoría para acotar'
                                  : '${marcas.length} en esta categoría'),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (w, a) =>
                                  FadeTransition(opacity: a, child: w),
                              child: marcas.isEmpty
                                  ? Padding(
                                      key: const ValueKey('sin-marcas'),
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Text('No hay marcas para mostrar.',
                                          style: TextStyle(color: Colors.grey.shade600)),
                                    )
                                  : Wrap(
                                      key: ValueKey('marcas-$cat'),
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        for (final m in marcas)
                                          FilterChip(
                                            label: Text('$m (${conteo[m]})'),
                                            selected: marcasSel.contains(m),
                                            onSelected: (v) => setSheet(() => v
                                                ? marcasSel.add(m)
                                                : marcasSel.remove(m)),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                          titulo('3', 'PRESUPUESTO (SOLES)'),
                          Center(
                            child: Text(
                              etiquetaRango,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary),
                            ),
                          ),
                          RangeSlider(
                            values: rango,
                            min: 0,
                            max: techo,
                            divisions: (techo / FiltrosCatalogo.paso).round(),
                            labels: RangeLabels(
                              'S/ ${_miles(rango.start)}',
                              'S/ ${_miles(rango.end)}${haciaMas ? '+' : ''}',
                            ),
                            onChanged: (v) => setSheet(() => rango = v),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('S/ 0',
                                  style: TextStyle(
                                      fontSize: 11.5, color: Colors.grey.shade600)),
                              Text('S/ ${_miles(techo)}+',
                                  style: TextStyle(
                                      fontSize: 11.5, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: mostrarTodo,
                            child: const Text('MOSTRAR TODO'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final sinRango =
                                  rango.start <= 0 && rango.end >= techo;
                              Navigator.of(sheet).pop(ResultadoFiltros(
                                cat,
                                FiltrosCatalogo(
                                  marcas: marcasSel,
                                  tipos: tiposSel,
                                  rango: sinRango ? null : rango,
                                ),
                              ));
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('APLICAR FILTROS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
