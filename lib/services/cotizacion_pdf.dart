import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/models/cotizacion.dart';

/// Genera la cotizacion como documento formal (estilo comprobante) en PDF
/// y la comparte con las aplicaciones del dispositivo.
class CotizacionPdf {
  CotizacionPdf._();

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String _fecha(DateTime f) => '${_dos(f.day)}/${_dos(f.month)}/${f.year}';

  /// Numero visible: COT-000123 (ultimos digitos del id).
  static String numero(Cotizacion c) {
    final digitos = c.id.replaceAll(RegExp(r'[^0-9]'), '');
    final cola =
        digitos.length > 6 ? digitos.substring(digitos.length - 6) : digitos;
    return 'COT-${cola.padLeft(6, '0')}';
  }

  static pw.Widget _celda(String t,
          {bool cabecera = false,
          pw.TextAlign align = pw.TextAlign.left,
          bool negrita = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          t,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: (cabecera || negrita)
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
            color: cabecera ? PdfColors.white : PdfColors.black,
          ),
        ),
      );

  static pw.Widget _dato(String etiqueta, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 110,
              child: pw.Text(etiqueta,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800)),
            ),
            pw.Expanded(
                child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );

  static pw.Widget _fila(String a, String b, {bool fuerte = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(a,
                style: pw.TextStyle(
                    fontSize: fuerte ? 12 : 10,
                    fontWeight:
                        fuerte ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(b,
                style: pw.TextStyle(
                    fontSize: fuerte ? 12 : 10,
                    fontWeight:
                        fuerte ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  static Future<Uint8List> generar(Cotizacion c) async {
    final doc = pw.Document(
      title: 'Cotizacion ${numero(c)}',
      author: AppConstants.nombreApp,
    );
    const naranja = PdfColor.fromInt(0xFFE65100);
    const grafito = PdfColor.fromInt(0xFF15181B);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${AppConstants.nombreApp}  |  ${AppConstants.eslogan}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
              pw.Text('Pagina ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),
        build: (ctx) => [
          // ------------------------------------------------ cabecera
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppConstants.nombreApp.toUpperCase(),
                        style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: grafito)),
                    pw.SizedBox(height: 4),
                    pw.Text(AppConstants.direccionFerreteria,
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Tel. ${AppConstants.telefonoFerreteria}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Container(
                width: 190,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grafito, width: 1.6),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.fromLTRB(8, 9, 8, 6),
                      child: pw.Text('R.U.C. ${AppConstants.rucFerreteria}',
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Container(
                      width: double.infinity,
                      color: naranja,
                      padding: const pw.EdgeInsets.symmetric(vertical: 7),
                      child: pw.Text('COTIZACIÓN',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 1.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Text('N° ${numero(c)}',
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ------------------------------------------------ fechas
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey500, width: 0.6),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FECHA DE EMISIÓN',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(_fecha(c.fecha),
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FECHA DE VENCIMIENTO',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(_fecha(c.fechaVencimiento),
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: naranja)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('VALIDEZ',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('${c.validezDias} días',
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ------------------------------------------------ cliente
          _dato('Señor(es):', c.clienteNombre),
          if (c.documento.isNotEmpty)
            _dato(
                c.tipoDocumento.isEmpty ? 'Documento:' : '${c.tipoDocumento}:',
                c.documento),
          _dato('Moneda:', 'Soles (PEN)'),
          pw.SizedBox(height: 12),

          // ------------------------------------------------ detalle
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(38),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(70),
              3: const pw.FixedColumnWidth(76),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: grafito),
                children: [
                  _celda('CANT.', cabecera: true, align: pw.TextAlign.center),
                  _celda('DESCRIPCIÓN', cabecera: true),
                  _celda('P. UNIT.',
                      cabecera: true, align: pw.TextAlign.right),
                  _celda('IMPORTE',
                      cabecera: true, align: pw.TextAlign.right),
                ],
              ),
              for (final i in c.items)
                pw.TableRow(
                  children: [
                    _celda('${i.cantidad}', align: pw.TextAlign.center),
                    _celda(i.nombre),
                    _celda(Formatters.soles(i.precioUnitario),
                        align: pw.TextAlign.right),
                    _celda(Formatters.soles(i.subtotal),
                        align: pw.TextAlign.right, negrita: true),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ------------------------------------------------ totales
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border:
                        pw.Border.all(color: PdfColors.grey500, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONDICIONES',
                          style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Cotización válida hasta el ${_fecha(c.fechaVencimiento)}.\n'
                        'Precios expresados en soles e incluyen IGV.\n'
                        'Sujeto a disponibilidad de stock al momento de la compra.',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Container(
                width: 190,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grafito, width: 1),
                ),
                child: pw.Column(
                  children: [
                    _fila('Subtotal', Formatters.soles(c.subtotal)),
                    _fila('IGV (18%)', Formatters.soles(c.igv)),
                    pw.Divider(color: PdfColors.grey500),
                    _fila('TOTAL', Formatters.soles(c.total), fuerte: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Guarda el PDF y abre el menu de compartir del dispositivo.
  static Future<void> compartir(Cotizacion c) async {
    final bytes = await generar(c);
    final carpeta = await getTemporaryDirectory();
    final archivo = File('${carpeta.path}/Cotizacion_${numero(c)}.pdf');
    await archivo.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: 'Cotización ${numero(c)}',
      text: 'Cotización ${numero(c)} - ${AppConstants.nombreApp}. '
          'Válida hasta el ${_fecha(c.fechaVencimiento)}.',
    );
  }
}
