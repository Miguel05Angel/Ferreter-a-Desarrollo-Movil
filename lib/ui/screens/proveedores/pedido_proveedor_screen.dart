import 'package:flutter/material.dart';
import '../../widgets/inputs/editable_cantidad.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contacto_service.dart';
import '../../../core/utils/dinero.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/reposicion.dart';
import '../../../data/models/producto.dart';
import '../../../data/models/proveedor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/proveedor_provider.dart';
import '../../../services/pedido_pdf.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/visual/producto_illustration.dart';

/// Solicitud de reposicion de stock al proveedor correspondiente.
/// Solo el Administrador puede generarla.
class PedidoProveedorScreen extends StatefulWidget {
  final String productoId;

  const PedidoProveedorScreen({super.key, required this.productoId});

  @override
  State<PedidoProveedorScreen> createState() => _PedidoProveedorScreenState();
}

class _PedidoProveedorScreenState extends State<PedidoProveedorScreen> {
  final _notas = TextEditingController();
  late final String _numero;
  int? _cantidad;
  String? _proveedorId;
  bool _generando = false;

  static String _dos(int n) => n.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    final a = DateTime.now();
    _numero = 'PED-${a.year}${_dos(a.month)}${_dos(a.day)}-${_dos(a.hour)}${_dos(a.minute)}';
  }

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  DatosPedido _datos(Producto producto, Proveedor proveedor, int cantidad) {
    final usuario = context.read<AuthProvider>().usuarioActual;
    return DatosPedido(
      numero: _numero,
      fecha: DateTime.now(),
      proveedor: proveedor,
      producto: producto,
      cantidad: cantidad,
      observaciones: _notas.text,
      solicitante: usuario?.nombre ?? 'Administrador',
    );
  }

  Future<void> _generarPdf(
      Producto producto, Proveedor proveedor, int cantidad) async {
    setState(() => _generando = true);
    final mensajes = ScaffoldMessenger.of(context);
    try {
      await PedidoPdf.compartir(_datos(producto, proveedor, cantidad));
    } catch (_) {
      mensajes.showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el reporte. Intenta de nuevo.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  void _whatsapp(Producto producto, Proveedor proveedor, int cantidad) {
    final usuario = context.read<AuthProvider>().usuarioActual;
    ContactoService.whatsapp(
      context,
      proveedor.telefono,
      Reposicion.mensajePedido(
        numero: _numero,
        solicitante: usuario?.nombre ?? 'Administrador',
        producto: producto,
        cantidad: cantidad,
        observaciones: _notas.text,
      ),
    );
  }

  Future<void> _registrarIngreso(Producto producto, int sugerida) async {
    final controlador = TextEditingController(text: '$sugerida');
    final unidades = await showDialog<int>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Registrar ingreso de stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuando llegue la mercaderia de ${producto.nombre}, '
                'indica cuantas unidades recibiste.'),
            const SizedBox(height: 14),
            TextField(
              controller: controlador,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: Formatos.digitos(5),
              decoration: const InputDecoration(
                labelText: 'Unidades recibidas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogo)
                .pop(int.tryParse(controlador.text.trim()) ?? 0),
            child: const Text('CONFIRMAR INGRESO'),
          ),
        ],
      ),
    );
    controlador.dispose();
    if (unidades == null || unidades <= 0 || !mounted) return;

    try {
      await context.read<ProductoProvider>().reponer(producto.id, unidades);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el ingreso de stock.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2E7D32),
        content: Text('Ingreso registrado: +$unidades ${producto.unidad}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permisos.de(context).puedeVerProveedores) {
      return const AccesoRestringido(titulo: 'Pedidos a proveedores');
    }

    final productos = context.watch<ProductoProvider>();
    final producto = productos.buscarPorId(widget.productoId);
    if (producto == null) {
      return const Scaffold(
        appBar: AppBarTaller(title: Text('Pedido')),
        body: Center(child: Text('El producto ya no existe.')),
      );
    }

    final todos = context.watch<ProveedorProvider>().proveedores;
    final sugeridos = Reposicion.proveedoresPara(producto, todos);
    final sugerida = Reposicion.cantidadSugerida(producto);
    _cantidad ??= sugerida;
    _proveedorId ??= sugeridos.isNotEmpty
        ? sugeridos.first.id
        : (todos.isNotEmpty ? todos.first.id : null);

    final elegidos = todos.where((p) => p.id == _proveedorId).toList();
    final proveedor = elegidos.isEmpty ? null : elegidos.first;
    final esSugerido =
        proveedor != null && sugeridos.any((p) => p.id == proveedor.id);
    final cantidad = _cantidad!;
    final costo = Dinero.r2(producto.precioCompra * cantidad);
    final categoria = productos.categoriaDe(producto.categoriaId);
    final colorStock = producto.agotado
        ? AppTheme.danger
        : (producto.stockBajo ? const Color(0xFFE0A100) : AppTheme.success);

    return Scaffold(
      appBar: const AppBarTaller(
        subtitulo: 'Reposicion de stock',
        title: Text('Pedido a proveedor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          // ------------------------------------------------ producto
          FadeSlide(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: categoria.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: ProductoEstatico(
                          tipo: producto.tipoVisual,
                          colorHex: producto.colorHex,
                          size: 50,
                          sombra: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('${producto.codigo}  ·  ${producto.marca}',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorStock.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: colorStock.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              producto.agotado
                                  ? 'AGOTADO'
                                  : 'STOCK ACTUAL: ${producto.stock}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w900,
                                color: colorStock,
                              ),
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
          const SizedBox(height: 14),

          // ------------------------------------------------ proveedor
          FadeSlide(
            delay: const Duration(milliseconds: 90),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiqueta('PROVEEDOR CORRESPONDIENTE'),
                    const SizedBox(height: 8),
                    if (todos.isEmpty)
                      const Text('Aun no hay proveedores registrados.')
                    else ...[
                      if (esSugerido)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SUGERIDO PARA ${categoria.nombre.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.success,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'No hay un proveedor registrado para esta linea. '
                            'Elige uno de la lista.',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.orange.shade800),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: _proveedorId,
                        isExpanded: true,
                        items: [
                          for (final p in todos)
                            DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nombre,
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _proveedorId = v),
                      ),
                    ],
                    if (proveedor != null) ...[
                      const SizedBox(height: 12),
                      _Fila(Icons.badge_outlined, 'RUC', proveedor.ruc),
                      _Fila(Icons.phone_outlined, 'TELEFONO',
                          proveedor.telefono),
                      _Fila(Icons.place_outlined, 'DIRECCION',
                          proveedor.direccion),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ContactoService.llamar(
                                  context, proveedor.telefono),
                              icon: const Icon(Icons.call_outlined, size: 18),
                              label: const Text('LLAMAR'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _whatsapp(producto, proveedor, cantidad),
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('WHATSAPP'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ------------------------------------------------ cantidad
          FadeSlide(
            delay: const Duration(milliseconds: 180),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Etiqueta('CANTIDAD A SOLICITAR'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BotonRedondo(
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
                          width: 110,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '$cantidad',
                              key: ValueKey(cantidad),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w900),
                            ),
                          ),
                        )),
                        _BotonRedondo(
                          icono: Icons.add,
                          onTap: cantidad < 9999
                              ? () => setState(() => _cantidad = cantidad + 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        for (final n in [10, 20, 50])
                          ActionChip(
                            label: Text('+$n'),
                            onPressed: () => setState(
                                () => _cantidad = (cantidad + n).clamp(1, 9999)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _Fila(Icons.auto_awesome_outlined, 'SUGERIDA',
                        '$sugerida ${producto.unidad.toLowerCase()}'),
                    _Fila(Icons.payments_outlined, 'COSTO ESTIMADO',
                        '${Formatters.soles(costo)}  (${Formatters.soles(producto.precioCompra)} c/u)'),
                    _Fila(Icons.inventory_2_outlined, 'STOCK RESULTANTE',
                        '${producto.stock + cantidad}'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ------------------------------------------------ observaciones
          FadeSlide(
            delay: const Duration(milliseconds: 270),
            child: TextField(
              controller: _notas,
              maxLength: 120,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'Ej: entrega urgente, marca preferida...',
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ------------------------------------------------ acciones
          FadeSlide(
            delay: const Duration(milliseconds: 340),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedButton(
                  texto: 'Generar reporte de pedido',
                  icono: Icons.picture_as_pdf_outlined,
                  cargando: _generando,
                  ancho: double.infinity,
                  onPressed: proveedor == null
                      ? null
                      : () => _generarPdf(producto, proveedor, cantidad),
                ),
                const SizedBox(height: 6),
                Text(
                  'El reporte incluye N.° de pedido, datos del proveedor, '
                  'detalle, motivo y espacio para firmas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: proveedor == null
                      ? null
                      : () => _whatsapp(producto, proveedor, cantidad),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('SOLICITAR POR WHATSAPP'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _registrarIngreso(producto, cantidad),
                  icon: const Icon(Icons.move_to_inbox_outlined),
                  label: const Text('REGISTRAR INGRESO DE STOCK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  const _Etiqueta(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10.5,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const _Fila(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 17, color: AppTheme.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: Text(
              etiqueta,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  const _BotonRedondo({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    return Material(
      color: activo ? AppTheme.primary : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icono,
              color: activo ? AppTheme.grafito : Colors.grey.shade500),
        ),
      ),
    );
  }
}
