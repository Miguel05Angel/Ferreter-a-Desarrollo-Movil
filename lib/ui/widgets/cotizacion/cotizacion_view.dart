import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/cotizacion.dart';
import '../../../services/cotizacion_pdf.dart';
import '../visual/decor_industrial.dart';

/// La cotizacion como documento formal en pantalla (papel blanco, estilo
/// comprobante). Es el mismo documento que se comparte en PDF o imagen.
class CotizacionView extends StatelessWidget {
  final Cotizacion cotizacion;
  final Cliente? cliente;

  const CotizacionView({super.key, required this.cotizacion, this.cliente});

  static const _tinta = Color(0xFF15181B);
  static const _gris = Color(0xFF6B7176);
  static const _encabezado =
      TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900);

  Widget _dato(String etiqueta, String valor, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(etiqueta,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                      color: _gris)),
            ),
            Expanded(
              child: Text(valor.isEmpty ? '-' : valor,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: fuerte ? FontWeight.w900 : FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _fila(String a, String b, {bool total = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a,
                style: TextStyle(
                    fontSize: total ? 15 : 12.5,
                    fontWeight: total ? FontWeight.w900 : FontWeight.w600,
                    color: total ? _tinta : _gris)),
            Text(b,
                style: TextStyle(
                    fontSize: total ? 18 : 12.5,
                    fontWeight: total ? FontWeight.w900 : FontWeight.w700,
                    color: total ? const Color(0xFFD95800) : _tinta)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;
    final tipo = c.tipoDocumento.isNotEmpty
        ? c.tipoDocumento
        : (cliente?.tipoDocumento ?? 'DOC');
    final doc =
        c.documento.isNotEmpty ? c.documento : (cliente?.documento ?? '');

    String? sello;
    const colorSello = AppTheme.danger;
    if (c.vencida && (c.estado == 'Pendiente' || c.estado == 'Rechazada')) {
      sello = 'VENCIDA';
    }

    return DefaultTextStyle(
      style: const TextStyle(color: _tinta, fontSize: 13),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FranjaPeligro(alto: 9),
            _CajaEstado(estado: c.estado),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppConstants.nombreApp.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 14.5, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text(
                              'RUC ${AppConstants.rucFerreteria}\n'
                              '${AppConstants.direccionFerreteria}\n'
                              'Tel. ${AppConstants.telefonoFerreteria}',
                              style: const TextStyle(
                                  fontSize: 10.8, height: 1.4, color: _gris),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: _tinta, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('COTIZACIÓN',
                                style: TextStyle(
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(CotizacionPdf.numero(c),
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD95800))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (sello != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Transform.rotate(
                        angle: -0.05,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorSello, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(sello,
                              style: TextStyle(
                                  color: colorSello,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  const Divider(height: 26, thickness: 1.2, color: _tinta),
                  _dato('FECHA EMISIÓN', Formatters.fechaCorta(c.fecha), fuerte: true),
                  _dato('FECHA VENCIM.', Formatters.fechaCorta(c.fechaVencimiento),
                      fuerte: true),
                  _dato('VALIDEZ', '${c.validezDias} días'),
                  const Divider(height: 22, color: Color(0xFFD8D8D8)),
                  const Text('CLIENTE',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD95800))),
                  const SizedBox(height: 6),
                  _dato('NOMBRE', c.clienteNombre, fuerte: true),
                  _dato(tipo, doc, fuerte: true),
                  if (cliente != null && cliente!.telefono.isNotEmpty)
                    _dato('TELÉFONO', cliente!.telefono),
                  if (cliente != null && cliente!.direccion.isNotEmpty)
                    _dato('DIRECCIÓN', cliente!.direccion),
                  const SizedBox(height: 12),
                  Container(
                    color: _tinta,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: const Row(
                      children: [
                        SizedBox(width: 38, child: Text('CANT.', style: _encabezado)),
                        Expanded(child: Text('DESCRIPCIÓN', style: _encabezado)),
                        SizedBox(
                            width: 62,
                            child: Text('P. UNIT.',
                                textAlign: TextAlign.right, style: _encabezado)),
                        SizedBox(
                            width: 70,
                            child: Text('IMPORTE',
                                textAlign: TextAlign.right, style: _encabezado)),
                      ],
                    ),
                  ),
                  for (var i = 0; i < c.items.length; i++)
                    Container(
                      color: i.isEven ? Colors.white : const Color(0xFFF6F4F0),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 38,
                              child: Text('${c.items[i].cantidad}',
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w800))),
                          Expanded(
                              child: Text(c.items[i].nombre,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600))),
                          SizedBox(
                              width: 62,
                              child: Text(Formatters.soles(c.items[i].precioUnitario),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11.5))),
                          SizedBox(
                              width: 70,
                              child: Text(Formatters.soles(c.items[i].subtotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 11.5, fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ),
                  const Divider(height: 18, thickness: 1.2, color: _tinta),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 210,
                      child: Column(
                        children: [
                          _fila('Subtotal', Formatters.soles(c.subtotal)),
                          _fila('IGV (${(AppConstants.igv * 100).round()}%)',
                              Formatters.soles(c.igv)),
                          const Divider(height: 12, color: Color(0xFFD8D8D8)),
                          _fila('TOTAL', Formatters.soles(c.total), total: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Precios en soles (S/). Sujeto a disponibilidad de stock. '
                    'Esta cotización no es un comprobante de pago.',
                    style: TextStyle(fontSize: 10.2, height: 1.35, color: _gris),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadro informativo con el estado de la cotizacion, arriba del documento.
class _CajaEstado extends StatelessWidget {
  final String estado;
  const _CajaEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    late final String titulo;
    late final String detalle;
    late final IconData icono;
    late final Color color;
    switch (estado) {
      case 'Aceptada':
        titulo = 'APROBADA';
        detalle = 'En espera de pago';
        icono = Icons.verified_outlined;
        color = const Color(0xFF0277BD);
        break;
      case 'Pagada':
        titulo = 'PAGADA';
        detalle = 'Cotización saldada';
        icono = Icons.paid_outlined;
        color = const Color(0xFF2E7D32);
        break;
      case 'Rechazada':
        titulo = 'RECHAZADA';
        detalle = 'No continuará';
        icono = Icons.cancel_outlined;
        color = AppTheme.danger;
        break;
      default:
        titulo = 'PENDIENTE';
        detalle = 'Esperando aprobación';
        icono = Icons.hourglass_top_rounded;
        color = const Color(0xFFB87900);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -10 * (1 - v)), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.75), width: 1.6),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESTADO DE LA COTIZACIÓN',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 17,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                          color: color)),
                ],
              ),
            ),
            Text(detalle,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
