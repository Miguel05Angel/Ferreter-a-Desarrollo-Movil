import 'package:flutter/material.dart';
import '../../widgets/inputs/editable_cantidad.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permisos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/proveedor_provider.dart';
import '../../../providers/compra_provider.dart';
import '../compras/solicitud_detalle_screen.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/producto_illustration.dart';
import '../mapa/mapa_screen.dart';

/// Pedido de reposicion de stock al proveedor correspondiente: se puede
/// generar el reporte de pedido en PDF, enviar la solicitud por WhatsApp o
/// llamar al proveedor.
class ReposicionScreen extends StatefulWidget {
  final String productoId;

  const ReposicionScreen({super.key, required this.productoId});

  @override
  State<ReposicionScreen> createState() => _ReposicionScreenState();
}

class _ReposicionScreenState extends State<ReposicionScreen> {
  late final ThemeData _tema = AppTheme.dark;
  int? _cantidad;
  DateTime _respuestaAntes = DateTime.now().add(const Duration(days: 3));
  bool _incluirReferencia = false;

  int _sugerida(Producto p) => (60 - p.stock).clamp(10, 300).toInt();

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _respuestaAntes,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'RESPONDER ANTES DEL',
    );
    if (f != null) setState(() => _respuestaAntes = f);
  }

  @override
  Widget build(BuildContext context) {
    final permisos = Permisos.de(context);
    if (!permisos.puedeSolicitarReposicion) {
      return const AccesoRestringido(
        titulo: 'Reposicion',
        detalle:
            'Solo el Administrador puede solicitar reposicion a proveedores. '
            'Avisale que este producto esta por agotarse.',
      );
    }

    final prov = context.watch<ProductoProvider>();
    final producto = prov.buscarPorId(widget.productoId);
    if (producto == null) {
      return Theme(
        data: _tema,
        child: const Scaffold(
          appBar: AppBarTaller(
              mostrarCarrito: false, title: Text('Reposicion')),
          body: Center(child: Text('El producto ya no existe.')),
        ),
      );
    }

    final categoria = prov.categoriaDe(producto.categoriaId);
    final proveedor = context
        .watch<ProveedorProvider>()
        .paraProducto(producto, categoria.nombre);
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final solicitante = usuario?.nombre ?? 'Administrador';
    final cantidad = _cantidad ?? _sugerida(producto);
    final color = producto.agotado
        ? const Color(0xFFFF6E6E)
        : AppTheme.amarilloSenal;

    return Theme(
      data: _tema,
      child: Scaffold(
        appBar: const AppBarTaller(
          mostrarCarrito: false,
          subtitulo: 'Compras',
          title: Text('Solicitud de cotizacion'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          children: [
            // ------------------------------------------------ producto
            FadeSlide(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: ShapeDecoration(
                  color: AppTheme.superficieOscura,
                  shape: BeveledRectangleBorder(
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(22)),
                    side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: categoria.color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ProductoEstatico(
                        tipo: producto.tipoVisual,
                        colorHex: producto.colorHex,
                        size: 78,
                        sombra: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.hueso,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${producto.codigo}  -  ${producto.marca.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: Color(0x99EDE8DF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: color),
                              const SizedBox(width: 6),
                              Text(
                                producto.agotado
                                    ? 'AGOTADO'
                                    : 'QUEDAN ${producto.stock} ${producto.unidad.toUpperCase()}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            FadeSlide(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2233),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x6664B5F6)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: Color(0xFF64B5F6)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Una solicitud de cotizacion no lleva precios: solo el '
                        'producto y la cantidad. El proveedor responde con su '
                        'cotizacion y, con esos precios, generas la orden de compra.',
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Color(0xCCEDE8DF)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------- proveedor
            const _Titulo('PROVEEDOR ASIGNADO'),
            FadeSlide(
              delay: const Duration(milliseconds: 120),
              child: proveedor == null
                  ? const Text('No hay proveedores registrados.')
                  : _TarjetaProveedor(
                      proveedor: proveedor,
                      onLlamar: () => launchUrl(Uri.parse('tel:${proveedor.telefono}')),
                      onMapa: () => AppRoutesMapa.abrir(context, proveedor),
                    ),
            ),

            // ------------------------------------------------ cantidad
            const _Titulo('CANTIDAD A SOLICITAR'),
            FadeSlide(
              delay: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.superficieOscura,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.bordeOscuro),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BotonCantidad(
                          icono: Icons.remove,
                          onTap: cantidad > 1
                              ? () => setState(() => _cantidad = cantidad - 1)
                              : null,
                        ),
                        EditableCantidad(
                          valor: cantidad,
                          maximo: 99999,
                          onCambio: (n) => setState(() => _cantidad = n),
                          child: SizedBox(
                          width: 130,
                          child: Column(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (c, a) => ScaleTransition(
                                    scale: a,
                                    child: FadeTransition(opacity: a, child: c)),
                                child: Text(
                                  '$cantidad',
                                  key: ValueKey(cantidad),
                                  style: const TextStyle(
                                    fontSize: 42,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              Text(
                                producto.unidad.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  letterSpacing: 1.6,
                                  color: Color(0x99EDE8DF),
                                ),
                              ),
                            ],
                          ),
                        )),
                        _BotonCantidad(
                          icono: Icons.add,
                          onTap: cantidad < 999
                              ? () => setState(() => _cantidad = cantidad + 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final n in [10, 25, 50, 100])
                          ActionChip(
                            label: Text('+$n'),
                            onPressed: () => setState(
                                () => _cantidad = (cantidad + n).clamp(1, 999)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.bordeOscuro),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _elegirFecha,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined,
                                size: 20, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'RESPONDER ANTES DEL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  color: Color(0x99EDE8DF),
                                ),
                              ),
                            ),
                            Text(
                              '${_respuestaAntes.day.toString().padLeft(2, '0')}/${_respuestaAntes.month.toString().padLeft(2, '0')}/${_respuestaAntes.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.hueso,
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0x99EDE8DF)),
                          ],
                        ),
                      ),
                    ),
                    if (permisos.puedeVerCostos && producto.precioCompra > 0)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Incluir ultimo costo como referencia',
                          style: TextStyle(fontSize: 13, color: AppTheme.hueso),
                        ),
                        subtitle: Text(
                          'Solo informativo: ${Formatters.soles(producto.precioCompra)} por ${producto.unidad.toLowerCase()}. No es un precio acordado.',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0x99EDE8DF)),
                        ),
                        value: _incluirReferencia,
                        onChanged: (v) => setState(() => _incluirReferencia = v),
                      ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------- acciones
            const SizedBox(height: 24),
            AnimatedButton(
              texto: 'Generar solicitud de cotizacion',
              icono: Icons.request_quote_outlined,
              ancho: double.infinity,
              onPressed: proveedor == null
                  ? null
                  : () {
                      final s = context.read<CompraProvider>().crear(
                            productoId: producto.id,
                            codigo: producto.codigo,
                            descripcion: producto.nombre,
                            unidad: producto.unidad,
                            cantidad: cantidad,
                            proveedorId: proveedor.id,
                            proveedorNombre: proveedor.nombre,
                            proveedorRuc: proveedor.ruc,
                            proveedorTelefono: proveedor.telefono,
                            proveedorDireccion: proveedor.direccion,
                            respuestaAntes: _respuestaAntes,
                            solicitante: solicitante,
                            precioReferencial: producto.precioCompra > 0
                                ? producto.precioCompra
                                : null,
                            incluirReferencia: _incluirReferencia,
                          );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              SolicitudDetalleScreen(solicitudId: s.id),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 6),
            const Text(
              'EL SIGUIENTE PASO: COMPARTIR LA SOLICITUD, REGISTRAR LA COTIZACION DEL PROVEEDOR Y RECIEN ENTONCES GENERAR LA ORDEN DE COMPRA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                height: 1.5,
                letterSpacing: 0.6,
                color: Color(0x80EDE8DF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
      child: Row(
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
              child: Divider(height: 1, color: AppTheme.bordeOscuro)),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;

  const _BotonCantidad({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: ShapeDecoration(
          color: onTap == null ? const Color(0xFF2E353B) : AppTheme.primary,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
          ),
        ),
        child: Icon(icono,
            color: onTap == null ? Colors.grey : AppTheme.grafito, size: 26),
      ),
    );
  }
}

class _TarjetaProveedor extends StatelessWidget {
  final Proveedor proveedor;
  final VoidCallback onLlamar;
  final VoidCallback onMapa;

  const _TarjetaProveedor({
    required this.proveedor,
    required this.onLlamar,
    required this.onMapa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficieOscura,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const ShapeDecoration(
                  color: Color(0x240277BD),
                  shape: BeveledRectangleBorder(
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(14)),
                    side: BorderSide(color: Color(0x800277BD)),
                  ),
                ),
                child: const Icon(Icons.local_shipping_outlined,
                    color: Color(0xFF64B5F6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.hueso,
                      ),
                    ),
                    Text(
                      'RUC ${proveedor.ruc}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0x99EDE8DF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 16, color: Color(0x99EDE8DF)),
              const SizedBox(width: 6),
              Text(proveedor.telefono,
                  style: const TextStyle(
                      fontFamily: 'monospace', color: AppTheme.hueso)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 16, color: Color(0x99EDE8DF)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(proveedor.direccion,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xCCEDE8DF))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLlamar,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('LLAMAR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMapa,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('VER EN MAPA'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
