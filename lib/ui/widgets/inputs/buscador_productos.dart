import 'package:flutter/material.dart';

import '../media/producto_imagen.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../providers/producto_provider.dart';
import '../../screens/productos/producto_detalle_screen.dart';
import '../visual/producto_illustration.dart';

/// Buscador de productos con resultados en vivo. Busca por nombre, codigo,
/// marca o categoria y abre el detalle del producto elegido.
class BuscadorProductos extends StatefulWidget {
  const BuscadorProductos({super.key});

  @override
  State<BuscadorProductos> createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<BuscadorProductos> {
  final _c = TextEditingController();
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _foco.dispose();
    super.dispose();
  }

  List<Producto> _resultados(ProductoProvider prov, String q) {
    final lista = prov.productos.where((p) {
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          p.marca.toLowerCase().contains(q) ||
          prov.categoriaDe(p.categoriaId).nombre.toLowerCase().contains(q);
    }).toList();
    lista.sort((a, b) {
      final sa = a.nombre.toLowerCase().startsWith(q) ? 0 : 1;
      final sb = b.nombre.toLowerCase().startsWith(q) ? 0 : 1;
      return sa.compareTo(sb);
    });
    return lista;
  }

  void _abrir(Producto p) {
    _foco.unfocus();
    AppRoutes.push(context, ProductoDetalleScreen(productoId: p.id));
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final prov = context.watch<ProductoProvider>();
    final q = _c.text.trim().toLowerCase();
    final res = q.isEmpty ? <Producto>[] : _resultados(prov, q);
    final activo = _foco.hasFocus || q.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra oscura con borde naranja: destaca sobre el fondo claro
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(0, activo ? -2 : 0, 0),
          decoration: ShapeDecoration(
            color: AppTheme.grafito,
            shape: BeveledRectangleBorder(
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(20)),
              side: BorderSide(
                color: AppTheme.primary,
                width: activo ? 2.8 : 2.2,
              ),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFFB34700),
                offset: Offset(0, activo ? 7 : 5),
              ),
            ],
          ),
          child: TextField(
            controller: _c,
            focusNode: _foco,
            onChanged: (_) => setState(() {}),
            cursorColor: AppTheme.primary,
            style: const TextStyle(
              color: AppTheme.hueso,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar entre ${prov.productos.length} productos...',
              hintStyle: const TextStyle(
                color: Color(0x99EDE8DF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              filled: false,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(9),
                child: Container(
                  width: 38,
                  decoration: const ShapeDecoration(
                    color: AppTheme.primary,
                    shape: BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(11)),
                    ),
                  ),
                  child: const Icon(Icons.search,
                      color: AppTheme.grafito, size: 24),
                ),
              ),
              suffixIcon: q.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        'NOMBRE - CODIGO - MARCA',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          letterSpacing: 0.6,
                          color: AppTheme.hueso.withOpacity(0.35),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.hueso),
                      onPressed: () {
                        _c.clear();
                        setState(() {});
                      },
                    ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: q.isEmpty
              ? (_foco.hasFocus
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in prov.categorias)
                            GestureDetector(
                              onTap: () {
                                _c.text = c.nombre;
                                _c.selection = TextSelection.collapsed(
                                    offset: _c.text.length);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(
                                  color: c.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: c.color.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(c.icono, size: 15, color: c.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.nombre,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: c.color),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity))
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: res.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: oscuro
                                    ? AppTheme.bordeOscuro
                                    : AppTheme.bordeClaro),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_off,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No hay productos que coincidan con "${_c.text.trim()}".',
                                  style:
                                      TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: oscuro
                                    ? AppTheme.bordeOscuro
                                    : AppTheme.bordeClaro),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < res.length && i < 5; i++) ...[
                                _FilaResultado(
                                  producto: res[i],
                                  color: prov
                                      .categoriaDe(res[i].categoriaId)
                                      .color,
                                  onTap: () => _abrir(res[i]),
                                ),
                                if (i < res.length - 1 && i < 4)
                                  Divider(
                                    height: 1,
                                    color: oscuro
                                        ? AppTheme.bordeOscuro
                                        : AppTheme.bordeClaro,
                                  ),
                              ],
                              if (res.length > 5)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  color: AppTheme.grafito,
                                  child: Text(
                                    '+${res.length - 5} COINCIDENCIAS MAS - AFINA LA BUSQUEDA',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

class _FilaResultado extends StatelessWidget {
  final Producto producto;
  final Color color;
  final VoidCallback onTap;

  const _FilaResultado({
    required this.producto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ProductoImagen(producto: producto, size: 52, sombra: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${producto.codigo}  -  ${producto.marca.toUpperCase()}',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.soles(producto.precioVenta),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900),
                ),
                Text(
                  producto.agotado ? 'AGOTADO' : '${producto.stock} EN STOCK',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: producto.agotado
                        ? AppTheme.danger
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
