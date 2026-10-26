import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/solicitud_cotizacion.dart';
import '../../../providers/compra_provider.dart';
import '../../../services/compra_exportador.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/feedback/acceso_restringido.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/visual/decor_industrial.dart';
import 'registrar_cotizacion_screen.dart';

/// Seguimiento de una solicitud de cotizacion: solicitud -> cotizacion del
/// proveedor -> orden de compra.
class SolicitudDetalleScreen extends StatefulWidget {
  final String solicitudId;

  const SolicitudDetalleScreen({super.key, required this.solicitudId});

  @override
  State<SolicitudDetalleScreen> createState() =>
      _SolicitudDetalleScreenState();
}

class _SolicitudDetalleScreenState extends State<SolicitudDetalleScreen> {
  late final ThemeData _tema = AppTheme.dark;
  bool _ocupado = false;

  Future<void> _pdf(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await accion();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.danger,
            content: Text('No se pudo generar el documento. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _abrir(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!Permisos.de(context).puedeSolicitarReposicion) {
      return const AccesoRestringido(
        titulo: 'Compras',
        detalle: 'Las compras a proveedores son solo para el Administrador.',
      );
    }

    final s = context.watch<CompraProvider>().buscar(widget.solicitudId);
    if (s == null) {
      return Theme(
        data: _tema,
        child: Scaffold(
          appBar: AppBarTaller(
              mostrarCarrito: false, title: const Text('Solicitud')),
          body: const Center(child: Text('La solicitud ya no existe.')),
        ),
      );
    }

    final c = s.cotizacion;

    return Theme(
      data: _tema,
      child: Scaffold(
        appBar: AppBarTaller(
          mostrarCarrito: false,
          subtitulo: s.estado.texto,
          title: Text(s.numero),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          children: [
            FadeSlide(child: _Linea(estado: s.estado)),
            const SizedBox(height: 18),

            // ------------------------------------------------ requerimiento
            FadeSlide(
              delay: const Duration(milliseconds: 100),
              child: _Caja(
                titulo: 'REQUERIMIENTO',
                hijos: [
                  _Dato('PRODUCTO', s.descripcion),
                  _Dato('CODIGO', s.codigo),
                  _Dato('CANTIDAD', '${s.cantidad} ${s.unidad}'),
                  _Dato('PROVEEDOR', s.proveedorNombre),
                  _Dato('RESPONDER ANTES DEL',
                      CompraExportador.fecha(s.respuestaAntes)),
                  if (s.incluirReferencia && s.precioReferencial != null)
                    _Dato('REFERENCIA (INFORMATIVA)',
                        Formatters.soles(s.precioReferencial!)),
                ],
              ),
            ),

            // ------------------------------------------------- cotizacion
            if (c != null) ...[
              const SizedBox(height: 14),
              FadeSlide(
                delay: const Duration(milliseconds: 160),
                child: _Caja(
                  titulo: 'COTIZACION DEL PROVEEDOR',
                  acento: c.vigente
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFFF6E6E),
                  hijos: [
                    _Dato('PRECIO UNITARIO',
                        '${Formatters.soles(c.precioUnitario)} ${c.incluyeIgv ? '(incluye IGV)' : '(mas IGV)'}'),
                    _Dato('PLAZO DE ENTREGA', '${c.plazoEntregaDias} dias'),
                    _Dato('CONDICIONES DE PAGO', c.condicionesPago),
                    _Dato(
                      'VALIDA HASTA',
                      '${CompraExportador.fecha(c.validaHasta)}  ${c.vigente ? '(VIGENTE)' : '(VENCIDA)'}',
                    ),
                    if (c.observaciones.trim().isNotEmpty)
                      _Dato('OBSERVACIONES', c.observaciones),
                    const Divider(color: AppTheme.bordeOscuro, height: 22),
                    _Total('Subtotal', Formatters.soles(c.subtotal(s.cantidad))),
                    _Total('IGV (18%)', Formatters.soles(c.igv(s.cantidad))),
                    _Total('Envio / flete', Formatters.soles(c.envio)),
                    const SizedBox(height: 6),
                    _Total('TOTAL', Formatters.soles(c.total(s.cantidad)),
                        grande: true),
                  ],
                ),
              ),
            ],

            if (s.estado == EstadoCompra.ordenada) ...[
              const SizedBox(height: 14),
              FadeSlide(
                delay: const Duration(milliseconds: 220),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12241A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x8066BB6A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          color: Color(0xFF66BB6A)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Orden de compra ${s.ordenNumero} emitida el ${CompraExportador.fecha(s.fechaOrden ?? DateTime.now())}.',
                          style: const TextStyle(
                              color: AppTheme.hueso, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // --------------------------------------------------- acciones
            const SizedBox(height: 24),
            if (s.estado == EstadoCompra.solicitada) ...[
              AnimatedButton(
                texto: 'Registrar cotizacion del proveedor',
                icono: Icons.price_check,
                ancho: double.infinity,
                onPressed: () => AppRoutes.push(
                    context, RegistrarCotizacionScreen(solicitudId: s.id)),
              ),
              const SizedBox(height: 8),
              _AccionesCompartir(
                ocupado: _ocupado,
                etiquetaPdf: 'COMPARTIR SOLICITUD (PDF)',
                onPdf: () => _pdf(() => CompraExportador.compartirSolicitud(s)),
                onWhatsApp: () => _abrir(Uri.parse(
                    'https://wa.me/51${s.proveedorTelefono}?text=${Uri.encodeComponent(CompraExportador.mensajeSolicitud(s))}')),
                onLlamar: () => _abrir(Uri.parse('tel:${s.proveedorTelefono}')),
              ),
            ] else if (s.estado == EstadoCompra.cotizada) ...[
              AnimatedButton(
                texto: 'Generar orden de compra',
                icono: Icons.assignment_turned_in_outlined,
                ancho: double.infinity,
                onPressed: () {
                  ConfirmDialog.mostrar(
                    context,
                    titulo: 'Generar orden de compra',
                    mensaje:
                        'Se emitira la orden a ${s.proveedorNombre} por ${Formatters.soles(c!.total(s.cantidad))}, con los precios de su cotizacion. ¿Continuar?',
                    textoConfirmar: 'Generar',
                    onConfirmar: () {
                      context.read<CompraProvider>().generarOrden(s.id);
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => AppRoutes.push(
                      context, RegistrarCotizacionScreen(solicitudId: s.id)),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('CORREGIR COTIZACION'),
                ),
              ),
              if (!c!.vigente)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'LA OFERTA ESTA VENCIDA: PIDE AL PROVEEDOR QUE LA ACTUALICE ANTES DE EMITIR LA ORDEN.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.5,
                      color: Color(0xFFFF6E6E),
                    ),
                  ),
                ),
            ] else ...[
              AnimatedButton(
                texto: 'Compartir orden de compra',
                icono: Icons.picture_as_pdf_outlined,
                ancho: double.infinity,
                cargando: _ocupado,
                onPressed: () =>
                    _pdf(() => CompraExportador.compartirOrden(s)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _pdf(() => CompraExportador.compartirSolicitud(s)),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('VER SOLICITUD ORIGINAL (PDF)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccionesCompartir extends StatelessWidget {
  final bool ocupado;
  final String etiquetaPdf;
  final VoidCallback onPdf;
  final VoidCallback onWhatsApp;
  final VoidCallback onLlamar;

  const _AccionesCompartir({
    required this.ocupado,
    required this.etiquetaPdf,
    required this.onPdf,
    required this.onWhatsApp,
    required this.onLlamar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: ocupado ? null : onPdf,
            icon: ocupado
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4))
                : const Icon(Icons.picture_as_pdf_outlined, size: 19),
            label: Text(etiquetaPdf),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('WHATSAPP'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onLlamar,
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('LLAMAR'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Linea de tiempo de tres pasos.
class _Linea extends StatelessWidget {
  final EstadoCompra estado;

  const _Linea({required this.estado});

  @override
  Widget build(BuildContext context) {
    final pasos = [
      ('SOLICITUD', Icons.send_outlined),
      ('COTIZACION', Icons.price_check),
      ('ORDEN', Icons.assignment_turned_in_outlined),
    ];
    final actual = estado.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.superficieOscura,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Row(
        children: [
          for (var i = 0; i < pasos.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 44,
                    height: 44,
                    decoration: ShapeDecoration(
                      color: i <= actual
                          ? AppTheme.primary
                          : const Color(0xFF2A3036),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(14)),
                      ),
                    ),
                    child: Icon(
                      i < actual ? Icons.check : pasos[i].$2,
                      color: i <= actual ? AppTheme.grafito : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    pasos[i].$1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9.5,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                      color: i <= actual
                          ? AppTheme.hueso
                          : const Color(0x66EDE8DF),
                    ),
                  ),
                ],
              ),
            ),
            if (i < pasos.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 3,
                    color: i < actual
                        ? AppTheme.primary
                        : const Color(0xFF2A3036),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  final String titulo;
  final List<Widget> hijos;
  final Color acento;

  const _Caja({
    required this.titulo,
    required this.hijos,
    this.acento = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppTheme.superficieOscura,
        shape: BeveledRectangleBorder(
          borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(22)),
          side: BorderSide(color: acento.withOpacity(0.55), width: 1.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FranjaPeligro(alto: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: acento,
                  ),
                ),
                const SizedBox(height: 10),
                ...hijos,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 0.8,
                color: Color(0x99EDE8DF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.hueso),
            ),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool grande;

  const _Total(this.etiqueta, this.valor, {this.grande = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta.toUpperCase(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: grande ? 13 : 11,
              letterSpacing: 1.2,
              fontWeight: grande ? FontWeight.w900 : FontWeight.w600,
              color: grande ? AppTheme.hueso : const Color(0x99EDE8DF),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: grande ? 24 : 14,
              fontWeight: FontWeight.w900,
              color: grande ? AppTheme.primary : AppTheme.hueso,
            ),
          ),
        ],
      ),
    );
  }
}
