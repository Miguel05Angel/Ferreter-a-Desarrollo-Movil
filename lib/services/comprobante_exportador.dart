import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/cliente.dart';
import '../data/models/venta.dart';
import '../ui/widgets/comprobante/codigos_painter.dart';
import '../ui/widgets/comprobante/comprobante_datos.dart';
import '../ui/widgets/comprobante/numero_a_letras.dart';

/// Genera el comprobante como PDF o como imagen y lo comparte (WhatsApp,
/// correo, Drive, etc.) usando el menu de compartir del telefono.
class ComprobanteExportador {
  ComprobanteExportador._();

  static String _nombre(Venta v, String extension) =>
      '${v.comprobante}_${v.numero}.$extension';

  static Future<File> _guardar(String nombre, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/$nombre');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo;
  }

  // ------------------------------------------------------------ imagen

  /// Captura el widget envuelto en el [RepaintBoundary] de [llave].
  static Future<Uint8List> capturarPng(GlobalKey llave,
      {double pixelRatio = 3}) async {
    final contexto = llave.currentContext;
    if (contexto == null) throw StateError('El comprobante no esta visible');
    final caja = contexto.findRenderObject() as RenderRepaintBoundary;
    final imagen = await caja.toImage(pixelRatio: pixelRatio);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    if (datos == null) throw StateError('No se pudo generar la imagen');
    return datos.buffer.asUint8List();
  }

  static Future<void> compartirImagen(GlobalKey llave, Venta venta) async {
    final bytes = await capturarPng(llave);
    final archivo = await _guardar(_nombre(venta, 'png'), bytes);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'image/png')],
      subject: '${venta.comprobante} ${venta.numero}',
      text: 'Comprobante ${venta.numero} - Ferreteria El Constructor',
    );
  }

  // --------------------------------------------------------------- PDF

  static Future<void> compartirPdf(
    Venta venta,
    Cliente? cliente,
    String vendedor,
  ) async {
    final bytes = await generarPdf(venta, cliente, vendedor);
    final archivo = await _guardar(_nombre(venta, 'pdf'), bytes);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: '${venta.comprobante} ${venta.numero}',
      text: 'Comprobante ${venta.numero} - Ferreteria El Constructor',
    );
  }

  /// El PDF usa fuentes estandar, asi que se quitan tildes y enes.
  static String _a(String t) {
    const de = 'áéíóúÁÉÍÓÚñÑüÜ¿¡';
    const a = 'aeiouAEIOUnNuU  ';
    var r = t;
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], a[i]);
    }
    return r.trim();
  }

  static String _soles(double v) => 'S/ ${v.toStringAsFixed(2)}';

  static Future<Uint8List> generarPdf(
    Venta v,
    Cliente? cliente,
    String vendedor,
  ) async {
    final esFactura = v.comprobante == 'Factura';
    final titulo =
        esFactura ? 'FACTURA ELECTRONICA' : 'BOLETA DE VENTA ELECTRONICA';
    final f = v.fecha;
    String d(int n) => n.toString().padLeft(2, '0');
    final fecha = '${d(f.day)}/${d(f.month)}/${f.year}';
    final hora = '${d(f.hour)}:${d(f.minute)}:${d(f.second)}';
    final doc = cliente != null && cliente.documento.isNotEmpty
        ? '${cliente.tipoDocumento}: ${cliente.documento}'
        : 'DNI: 00000000';

    final tinta = PdfColors.grey900;
    final gris = PdfColors.grey700;
    final linea = PdfColors.grey400;

    pw.Widget dato(String e, String valor) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 58,
                child: pw.Text(e,
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                  child: pw.Text(_a(valor),
                      style: const pw.TextStyle(fontSize: 9.5))),
            ],
          ),
        );

    pw.Widget celda(String t,
            {bool derecha = false, bool negrita = false, PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: pw.Text(
            _a(t),
            textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8.5,
              color: color ?? tinta,
              fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    pw.Widget total(String e, String valor) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(e,
                  style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text(valor,
                  style: pw.TextStyle(
                      fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    final doc2 = pw.Document(
      title: '${v.comprobante} ${v.numero}',
      author: 'Ferreteria El Constructor',
    );

    doc2.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(26),
        build: (ctx) => [
          // ------------------------------------------------ cabecera
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('EL CONSTRUCTOR',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('FERRETERIA - MATERIALES - HERRAMIENTAS',
                    style: pw.TextStyle(fontSize: 7, color: gris)),
                pw.SizedBox(height: 5),
                pw.Text(_a(AppConstants.direccionFerreteria),
                    style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text('Tel: ${AppConstants.telefonoFerreteria}',
                    style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ---------------------------------------------- caja RUC
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: tinta, width: 1.6),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text('R.U.C. ${AppConstants.rucFerreteria}',
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  width: double.infinity,
                  color: tinta,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(titulo,
                      style: pw.TextStyle(
                          fontSize: 10.5,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text(v.numero,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ------------------------------------------------- datos
          dato('FECHA', '$fecha     HORA  $hora'),
          dato('CLIENTE', v.clienteNombre),
          dato('DOCUMENTO', doc),
          if (esFactura && cliente != null && cliente.direccion.isNotEmpty)
            dato('DIRECCION', cliente.direccion),
          dato('PAGO', v.metodoPago),
          dato('VENDEDOR', vendedor.isEmpty ? 'Caja 01' : vendedor),
          pw.SizedBox(height: 10),

          // ----------------------------------------------- detalle
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(52),
              3: const pw.FixedColumnWidth(58),
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: linea, width: 0.5),
              bottom: pw.BorderSide(color: linea, width: 0.5),
            ),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: tinta),
                children: [
                  celda('CANT', negrita: true, color: PdfColors.white),
                  celda('DESCRIPCION', negrita: true, color: PdfColors.white),
                  celda('P. UNIT', derecha: true, negrita: true, color: PdfColors.white),
                  celda('IMPORTE', derecha: true, negrita: true, color: PdfColors.white),
                ],
              ),
              for (final i in v.items)
                pw.TableRow(
                  children: [
                    celda('${i.cantidad}', negrita: true),
                    celda(i.nombre),
                    celda(i.precioUnitario.toStringAsFixed(2), derecha: true),
                    celda(i.subtotal.toStringAsFixed(2),
                        derecha: true, negrita: true),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 10),

          // ----------------------------------------------- totales
          total('OP. GRAVADA', _soles(v.subtotal)),
          total('IGV (18%)', _soles(v.igv)),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: tinta, width: 1.6),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text(_soles(v.total),
                    style: pw.TextStyle(
                        fontSize: 17, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          if (v.redondeo > 0) ...[
            pw.SizedBox(height: 6),
            total('REDONDEO (EFECTIVO)', '- ${_soles(v.redondeo)}'),
            total('COBRADO EN EFECTIVO', _soles(v.total - v.redondeo)),
          ],
          pw.SizedBox(height: 7),
          pw.Text('SON: ${montoEnLetras(v.total)}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),

          // ------------------------------------------ QR y barras
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: linea, width: 0.6)),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrSunat(v, cliente),
                  width: 82,
                  height: 82,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('HASH',
                        style: pw.TextStyle(
                            fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(hashVisual(v.id),
                        style: pw.TextStyle(fontSize: 7, color: gris)),
                    pw.SizedBox(height: 8),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: v.numero,
                      height: 30,
                      drawText: false,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(v.numero,
                        style: pw.TextStyle(fontSize: 7.5, color: gris)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              'Representacion impresa de la ${esFactura ? 'factura' : 'boleta de venta'} electronica. '
              'Conserve este comprobante para cualquier cambio o reclamo.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7.5, color: gris),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('Gracias por su preferencia',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );

    return doc2.save();
  }
}
