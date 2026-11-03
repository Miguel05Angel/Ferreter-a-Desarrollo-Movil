import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/cotizacion.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../services/comprobante_exportador.dart';
import '../../../services/cotizacion_pdf.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/cotizacion/contacto_cliente_sheet.dart';
import '../../widgets/cotizacion/cotizacion_view.dart';
import '../../widgets/cotizacion/dialogo_eliminar_cotizacion.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/feedback/verificacion_clave_dialog.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../carrito/carrito_page.dart';
import 'cotizacion_form_screen.dart';

/// Documento final de la cotizacion. Desde aqui se comparte (PDF o imagen,
/// igual que las boletas) y se puede Editar, Aprobar o Eliminar.
class CotizacionDocumentoScreen extends StatefulWidget {
  final String cotizacionId;

  /// 'imagen' o 'pdf': comparte automaticamente al abrir (lo usa la alerta
  /// de cotizacion confirmada).
  final String? compartirAlAbrir;

  const CotizacionDocumentoScreen({
    super.key,
    required this.cotizacionId,
    this.compartirAlAbrir,
  });

  @override
  State<CotizacionDocumentoScreen> createState() =>
      _CotizacionDocumentoScreenState();
}

class _CotizacionDocumentoScreenState extends State<CotizacionDocumentoScreen> {
  final GlobalKey _llave = GlobalKey();
  String? _ocupado; // 'pdf' | 'imagen'

  @override
  void initState() {
    super.initState();
    final auto = widget.compartirAlAbrir;
    if (auto != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        final c = context.read<CotizacionProvider>().buscarPorId(widget.cotizacionId);
        if (c != null) _compartir(auto, c);
      });
    }
  }

  Future<void> _compartir(String tipo, Cotizacion c) async {
    if (_ocupado != null) return;
    setState(() => _ocupado = tipo);
    try {
      if (tipo == 'pdf') {
        await CotizacionPdf.compartir(c);
      } else {
        final bytes = await ComprobanteExportador.capturarPng(_llave);
        final dir = await getTemporaryDirectory();
        final archivo = File('${dir.path}/Cotizacion_${CotizacionPdf.numero(c)}.png');
        await archivo.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(archivo.path, mimeType: 'image/png')],
          subject: 'Cotización ${CotizacionPdf.numero(c)}',
          text: 'Cotización ${CotizacionPdf.numero(c)}',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('No se pudo compartir la cotización. Intenta de nuevo.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _ocupado = null);
    }
  }

  Cliente? _cliente(Cotizacion c, List<Cliente> clientes) {
    for (final x in clientes) {
      if ((c.clienteId.isNotEmpty && x.id == c.clienteId) ||
          x.nombre.trim().toLowerCase() == c.clienteNombre.trim().toLowerCase()) {
        return x;
      }
    }
    return null;
  }

  /// Aprobar exige la contrasena del usuario. Si es correcta se aprueba la
  /// cotizacion y se abre el pago con sus productos.
  Future<void> _aprobar(Cotizacion c) async {
    final autorizado = await VerificacionClaveDialog.mostrar(context);
    if (!autorizado || !mounted) return;
    context.read<CotizacionProvider>().cambiarEstado(c.id, 'Aceptada');
    await _irAlPago(c);
  }

  /// Carga la cotizacion en el carrito (modo "pago de cotizacion") y abre el
  /// carrito. Las compras normales no pasan por aqui.
  Future<void> _irAlPago(Cotizacion c) async {
    final carrito = context.read<CarritoProvider>();
    final productos = context.read<ProductoProvider>();
    carrito.iniciarCotizacion(c.id, c.items.map((i) => i.productoId));

    final pendientes = <String>[];
    for (final it in c.items) {
      final p = productos.buscarPorId(it.productoId);
      if (p == null) {
        pendientes.add('${it.nombre}: ya no esta en el catalogo');
        continue;
      }
      final error = carrito.agregar(p, it.cantidad);
      if (error != null) pendientes.add('${it.nombre}: $error');
    }
    if (!mounted) return;

    if (pendientes.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Revisa estos productos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No se pudieron pasar completos al pago:'),
              const SizedBox(height: 8),
              for (final x in pendientes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $x', style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(d).pop(),
                child: const Text('Continuar')),
          ],
        ),
      );
      if (!mounted) return;
    }
    AppRoutes.push(context, const CarritoPage());
  }

  Future<void> _eliminar(Cotizacion c) async {
    final provider = context.read<CotizacionProvider>();
    final ok = await DialogoEliminarCotizacion.mostrar(context);
    if (!ok || !mounted) return;
    final numero = CotizacionPdf.numero(c);
    final mensajes = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    provider.eliminar(c.id);
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppTheme.grafito,
        content: Text('$numero eliminada'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CotizacionProvider>();
    final clientes = context.watch<ClienteProvider>().clientes;
    final permisos = Permisos.de(context);
    final c = provider.buscarPorId(widget.cotizacionId);

    if (c == null) {
      return Scaffold(
        appBar: AppBarTaller(
            mostrarCarrito: false,
            subtitulo: 'Presupuesto',
            title: const Text('Cotización')),
        body: const EmptyState(
          icono: Icons.search_off,
          titulo: 'Cotización no encontrada',
          mensaje: 'Es posible que ya haya sido eliminada.',
        ),
      );
    }

    final editable = c.estado == 'Pendiente' || c.estado == 'Rechazada';
    final pendiente = c.estado == 'Pendiente';
    final aprobada = c.estado == 'Aceptada';
    final pagada = c.estado == 'Pagada';

    return Scaffold(
      appBar: AppBarTaller(
        mostrarCarrito: false,
        subtitulo: CotizacionPdf.numero(c),
        title: const Text('Cotización'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          FadeSlide(
            child: RepaintBoundary(
              key: _llave,
              child: Container(
                color: const Color(0xFFEDE8DF),
                padding: const EdgeInsets.all(14),
                child: CotizacionView(
                  cotizacion: c,
                  cliente: _cliente(c, clientes),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  texto: 'PDF',
                  icono: Icons.picture_as_pdf_outlined,
                  cargando: _ocupado == 'pdf',
                  onPressed: _ocupado == null ? () => _compartir('pdf', c) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedButton(
                  texto: 'Imagen',
                  icono: Icons.image_outlined,
                  color: const Color(0xFF263238),
                  cargando: _ocupado == 'imagen',
                  onPressed: _ocupado == null ? () => _compartir('imagen', c) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'COMPARTE POR WHATSAPP, CORREO O GUÁRDALO EN TU TELÉFONO',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                letterSpacing: 0.8,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          const Text('ACCIONES',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          FadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ContactoClienteSheet.mostrar(context, c),
                  icon: const Icon(Icons.contact_phone_outlined),
                  label: const Text('CONTACTAR CLIENTE'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                ),
                const SizedBox(height: 10),
                if (aprobada)
                  FilledButton.icon(
                    onPressed: () => _irAlPago(c),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('CONTINUAR AL PAGO'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                if (aprobada) const SizedBox(height: 10),
                if (pendiente)
                  FilledButton.icon(
                    onPressed: () => _aprobar(c),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('APROBAR Y PROCESAR PAGO'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                if (pendiente) const SizedBox(height: 10),
                if (editable)
                  OutlinedButton.icon(
                    onPressed: () =>
                        AppRoutes.push(context, CotizacionFormScreen(cotizacion: c)),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('EDITAR COTIZACIÓN'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                if (editable) const SizedBox(height: 10),
                if (permisos.puedeEliminarCotizaciones)
                  OutlinedButton.icon(
                    onPressed: () => _eliminar(c),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ELIMINAR'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                  )
                else
                  Text(
                    'Solo el administrador puede eliminar cotizaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                if (!editable)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      pagada
                          ? 'Esta cotización ya fue pagada.'
                          : 'Una cotización aprobada ya no se puede editar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
