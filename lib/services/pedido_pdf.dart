import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/dinero.dart';
import '../core/utils/formatters.dart';
import '../data/models/producto.dart';
import '../data/models/proveedor.dart';

class DatosPedido {
  final String numero;
  final DateTime fecha;
  final Proveedor proveedor;
  final Producto producto;
  final int cantidad;
  final String observaciones;
  final String solicitante;

  const DatosPedido({
    required this.numero,
    required this.fecha,
    required this.proveedor,
    required this.producto,
    required this.cantidad,
    required this.observaciones,
    required this.solicitante,
  });
}

/// Genera el reporte "Solicitud de reposicion" en PDF y lo comparte.
class PedidoPdf {
  PedidoPdf._();

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String _fecha(DateTime f) =>
      '${_dos(f.day)}/${_dos(f.month)}/${f.year} ${_dos(f.hour)}:${_dos(f.minute)}';

  static pw.Widget _dato(String etiqueta, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 80,
              child: pw.Text(etiqueta,
                  style: const pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700)),
            ),
            pw.Expanded(
                child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );

  static pw.Widget _titulo(String t) => pw.Container(
        width: double.infinity,
        color: PdfColors.grey200,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: pw.Text(t,
            style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1)),
      );

  static pw.Widget _celda(String t,
          {bool cabecera = false, pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          t,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: cabecera ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: cabecera ? PdfColors.white : PdfColors.black,
          ),
        ),
      );

  static Future<Uint8List> generar(DatosPedido d) async {
    final doc = pw.Document(
      title: 'Solicitud de reposicion ${d.numero}',
      author: AppConstants.nombreApp,
    );
    final costo = d.producto.precioCompra;
    final total = Dinero.r2(costo * d.cantidad);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(AppConstants.nombreApp,
                          style: const pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Text('RUC ${AppConstants.rucFerreteria}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(AppConstants.direccionFerreteria,
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Tel. ${AppConstants.telefonoFerreteria}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1.5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('SOLICITUD DE REPOSICION',
                          style: const pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Pedido No. ${d.numero}',
                          style: const pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Fecha: ${_fecha(d.fecha)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            _titulo('PROVEEDOR'),
            pw.SizedBox(height: 6),
            _dato('Razon social', d.proveedor.nombre),
            _dato('RUC', d.proveedor.ruc),
            _dato('Telefono', d.proveedor.telefono),
            _dato('Direccion', d.proveedor.direccion),
            pw.SizedBox(height: 14),
            _titulo('DETALLE DEL PEDIDO'),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.3),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(0.9),
                5: const pw.FlexColumnWidth(1.3),
                6: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  children: [
                    _celda('Codigo', cabecera: true),
                    _celda('Descripcion', cabecera: true),
                    _celda('Marca', cabecera: true),
                    _celda('Unidad', cabecera: true),
                    _celda('Cant.', cabecera: true, align: pw.TextAlign.right),
                    _celda('Costo unit.',
                        cabecera: true, align: pw.TextAlign.right),
                    _celda('Subtotal',
                        cabecera: true, align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _celda(d.producto.codigo),
                    _celda(d.producto.nombre),
                    _celda(d.producto.marca),
                    _celda(d.producto.unidad),
                    _celda('${d.cantidad}', align: pw.TextAlign.right),
                    _celda(Formatters.soles(costo), align: pw.TextAlign.right),
                    _celda(Formatters.soles(total), align: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total estimado (referencial): ${Formatters.soles(total)}',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 14),
            _titulo('MOTIVO Y OBSERVACIONES'),
            pw.SizedBox(height: 6),
            pw.Text(
              'Stock actual al momento del pedido: ${d.producto.stock} unidad(es). '
              'Se solicita reposicion para evitar quiebre de stock.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (d.observaciones.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text('Observaciones: ${d.observaciones.trim()}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              'Favor confirmar disponibilidad, precio final y plazo de entrega.',
              style: const pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700),
            ),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Container(width: 160, height: 0.8, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Solicitado por: ${d.solicitante}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(AppConstants.nombreApp,
                      style: const pw.TextStyle(fontSize: 8)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 160, height: 0.8, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Recibido por el proveedor',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Firma y sello',
                      style: const pw.TextStyle(fontSize: 8)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Genera el PDF y abre el menu de compartir (WhatsApp, correo, etc.).
  static Future<void> compartir(DatosPedido d) async {
    final bytes = await generar(d);
    final carpeta = await getTemporaryDirectory();
    final archivo = File('${carpeta.path}/Pedido_${d.numero}.pdf');
    await archivo.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: 'Solicitud de reposicion ${d.numero}',
      text: 'Solicitud de reposicion ${d.numero} - ${AppConstants.nombreApp}',
    );
  }
}
