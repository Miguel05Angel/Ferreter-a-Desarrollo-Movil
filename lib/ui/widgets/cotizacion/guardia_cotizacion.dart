import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/venta.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../providers/producto_provider.dart';
import '../carrito/carrito_flotante.dart';
import '../visual/decor_industrial.dart';

/// Vigila el carrito mientras se paga una cotizacion. Si el usuario agrega
/// un producto que no estaba cotizado, muestra una alerta flotante con dos
/// salidas: actualizar la cotizacion o seguir comprando fuera de ella.
/// Se coloca una sola vez, en el `builder` del MaterialApp.
class GuardiaCotizacion extends StatefulWidget {
  final Widget child;
  const GuardiaCotizacion({super.key, required this.child});

  @override
  State<GuardiaCotizacion> createState() => _GuardiaCotizacionState();
}

class _GuardiaCotizacionState extends State<GuardiaCotizacion> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    if (carrito.consultasPendientes.isNotEmpty && !_abierta) {
      _abierta = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolver());
    }
    return widget.child;
  }

  Future<T?> _dialogo<T>(BuildContext ctx, Widget Function(BuildContext) b) {
    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: false,
      barrierLabel: 'Cotizacion',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (c, __, ___) => b(c),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.10), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _resolver() async {
    while (mounted) {
      final carrito = context.read<CarritoProvider>();
      final productos = context.read<ProductoProvider>();
      final ids = carrito.consultasPendientes;
      final nav = navegadorGlobal.currentContext;
      if (ids.isEmpty || nav == null) break;

      final nombres = [
        for (final id in ids) productos.buscarPorId(id)?.nombre ?? 'Producto',
      ];
      final accion = await _dialogo<String>(
        nav,
        (_) => _AlertaProductoNuevo(nombres: nombres),
      );
      if (!mounted) break;

      if (accion == 'editar') {
        final nuevos = [
          for (final id in ids)
            if (carrito.items.any((i) => i.producto.id == id))
              carrito.items.firstWhere((i) => i.producto.id == id),
        ];
        final cot = context
            .read<CotizacionProvider>()
            .buscarPorId(carrito.cotizacionId ?? '');
        final ctx2 = navegadorGlobal.currentContext;
        if (cot == null || ctx2 == null) {
          carrito.resolverContinuar();
          break;
        }
        final sumaNuevos = nuevos.fold(0.0, (s, i) => s + i.subtotal);
        final ok = await _dialogo<bool>(
          ctx2,
          (_) => _ConfirmarActualizacion(
            numero: cot.id,
            lineas: [
              for (final i in nuevos)
                '${i.cantidad} x ${i.producto.nombre}  '
                    '${Formatters.soles(i.subtotal)}',
            ],
            totalAntes: cot.total,
            totalDespues: cot.total + sumaNuevos * (1 + AppConstants.igv),
          ),
        );
        if (!mounted) break;
        if (ok == true) {
          final aAgregar = carrito.resolverEditar();
          final cotizaciones = context.read<CotizacionProvider>();
          cotizaciones.actualizar(
            id: cot.id,
            clienteNombre: cot.clienteNombre,
            validezDias: cot.validezDias,
            clienteId: cot.clienteId,
            tipoDocumento: cot.tipoDocumento,
            documento: cot.documento,
            items: [
              ...cot.items,
              for (final i in aAgregar)
                ItemVenta(
                  productoId: i.producto.id,
                  nombre: i.producto.nombre,
                  cantidad: i.cantidad,
                  precioUnitario: i.producto.precioVenta,
                ),
            ],
          );
          final mensajes = ScaffoldMessenger.maybeOf(navegadorGlobal.currentContext ?? context);
          mensajes
            ?..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              backgroundColor: AppTheme.grafito,
              content: Text('Cotización actualizada con los nuevos productos'),
            ));
        }
        // Si cancelo la confirmacion se vuelve a preguntar.
      } else {
        final ctx3 = navegadorGlobal.currentContext;
        if (ctx3 != null) {
          await _dialogo<void>(ctx3, (_) => const _AlertaFueraDeCotizacion());
        }
        if (!mounted) break;
        carrito.resolverContinuar();
      }
    }
    _abierta = false;
  }
}

class _Marco extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final List<Widget> cuerpo;
  final List<Widget> botones;

  const _Marco({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.cuerpo,
    required this.botones,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaPeligro(alto: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Icon(icono, size: 46, color: color),
                ),
                const SizedBox(height: 10),
                Text(titulo.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 10),
                ...cuerpo,
                const SizedBox(height: 18),
                ...botones,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaProductoNuevo extends StatelessWidget {
  final List<String> nombres;
  const _AlertaProductoNuevo({required this.nombres});

  @override
  Widget build(BuildContext context) {
    return _Marco(
      icono: Icons.warning_amber_rounded,
      color: AppTheme.amarilloSenal,
      titulo: 'Producto fuera de la cotización',
      cuerpo: [
        const Text(
          'Estás agregando un producto nuevo fuera de la cotización original.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        for (final n in nombres)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('+ $n',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
      ],
      botones: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop('editar'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Editar Cotización'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop('continuar'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Continuar Comprando'),
        ),
      ],
    );
  }
}

class _ConfirmarActualizacion extends StatelessWidget {
  final String numero;
  final List<String> lineas;
  final double totalAntes;
  final double totalDespues;

  const _ConfirmarActualizacion({
    required this.numero,
    required this.lineas,
    required this.totalAntes,
    required this.totalDespues,
  });

  @override
  Widget build(BuildContext context) {
    return _Marco(
      icono: Icons.edit_note,
      color: AppTheme.primary,
      titulo: 'Confirmar cambios',
      cuerpo: [
        const Text(
          '¿Estás seguro de actualizar esta cotización con los nuevos productos?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SE AGREGARÁN',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              for (final l in lineas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(l, style: const TextStyle(fontSize: 12.5)),
                ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total antes ${Formatters.soles(totalAntes)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(Formatters.soles(totalDespues),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
      ],
      botones: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Sí, estoy seguro'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}

class _AlertaFueraDeCotizacion extends StatelessWidget {
  const _AlertaFueraDeCotizacion();

  @override
  Widget build(BuildContext context) {
    return _Marco(
      icono: Icons.info_outline,
      color: AppTheme.danger,
      titulo: 'Atención',
      cuerpo: const [
        Text(
          'Estos productos no figurarán en la cotización actual.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.4),
        ),
      ],
      botones: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Seguir Comprando'),
        ),
      ],
    );
  }
}
