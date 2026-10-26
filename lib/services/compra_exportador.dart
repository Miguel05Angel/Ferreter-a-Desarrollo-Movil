import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../data/models/solicitud_cotizacion.dart';

/// Documentos de compra:
/// - Solicitud de cotizacion (RFQ): neutra, SIN precios.
/// - Orden de compra: con los precios y condiciones que cotizo el proveedor.
class CompraExportador {
  CompraExportador._();

  static String _a(String t) {
    const de = 'áéíóúÁÉÍÓÚñÑüÜ';
    const a = 'aeiouAEIOUnNuU';
    var r = t;
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], a[i]);
    }
    return r;
  }

  static String fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

  static String _soles(double v) => 'S/ ${v.toStringAsFixed(2)}';

  // ------------------------------------------------------------- mensaje

  /// Mensaje formal para WhatsApp o correo. No incluye precios.
  static String mensajeSolicitud(SolicitudCotizacion s) {
    return 'Estimados ${s.proveedorNombre}:\n\n'
        'Les saludamos de Ferreteria El Constructor (RUC ${AppConstants.rucFerreteria}). '
        'Solicitamos su cotizacion para el siguiente requerimiento:\n\n'
        '- Solicitud N. ${s.numero}\n'
        '- Producto: ${s.descripcion} (${s.codigo})\n'
        '- Cantidad requerida: ${s.cantidad} ${s.unidad.toLowerCase()}\n\n'
        'Por favor indicar en su respuesta: precio unitario (precisando si '
        'incluye IGV), gastos de envio, plazo de entrega, condiciones de pago '
        'y fecha de validez de la oferta.\n'
        'Agradeceremos responder antes del ${fecha(s.respuestaAntes)}.\n\n'
        'Atentamente,\n${s.solicitante}\nFerreteria El Constructor\n'
        'Tel: ${AppConstants.telefonoFerreteria}';
  }

  // ------------------------------------------------------ piezas del PDF

  static final PdfColor _tinta = PdfColors.grey900;
  static final PdfColor _gris = PdfColors.grey700;

  static pw.Widget _cabecera(String titulo, String numero, String fechaTxt) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('EL CONSTRUCTOR',
                  style:
                      pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('FERRETERIA - MATERIALES - HERRAMIENTAS',
                  style: pw.TextStyle(fontSize: 7.5, color: _gris)),
              pw.SizedBox(height: 4),
              pw.Text('RUC ${AppConstants.rucFerreteria}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(_a(AppConstants.direccionFerreteria),
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Tel: ${AppConstants.telefonoFerreteria}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _tinta, width: 1.6),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(titulo,
                    style: pw.TextStyle(
                        fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(numero,
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.Text(fechaTxt,
                    style: pw.TextStyle(fontSize: 8.5, color: _gris)),
              ],
            ),
          ),
        ],
      );

  static pw.Widget _barra(String t) => pw.Container(
        width: double.infinity,
        color: _tinta,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _fila(String e, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 92,
              child: pw.Text(e,
                  style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
                child:
                    pw.Text(_a(v), style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );

  static pw.Widget _celda(String t,
          {bool der = false, bool negrita = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          _a(t),
          textAlign: der ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: color ?? _tinta,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  static pw.Widget _firmas(String izquierda, String derecha) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(children: [
            pw.Container(width: 150, height: 0.8, color: _tinta),
            pw.SizedBox(height: 4),
            pw.Text(_a(izquierda), style: const pw.TextStyle(fontSize: 8.5)),
          ]),
          pw.Column(children: [
            pw.Container(width: 150, height: 0.8, color: _tinta),
            pw.SizedBox(height: 4),
            pw.Text(_a(derecha), style: const pw.TextStyle(fontSize: 8.5)),
          ]),
        ],
      );

  static pw.Widget _proveedor(SolicitudCotizacion s) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _barra('PROVEEDOR'),
          pw.SizedBox(height: 6),
          _fila('RAZON SOCIAL', s.proveedorNombre),
          _fila('RUC', s.proveedorRuc),
          _fila('TELEFONO', s.proveedorTelefono),
          _fila('DIRECCION', s.proveedorDireccion),
        ],
      );

  // ------------------------------------------- solicitud de cotizacion

  /// RFQ: solo items y cantidades. El precio de referencia aparece unicamente
  /// si el usuario lo activo y se marca como informativo.
  static Future<Uint8List> solicitudPdf(SolicitudCotizacion s) async {
    final conRef = s.incluirReferencia && s.precioReferencial != null;
    final doc = pw.Document(
      title: 'Solicitud de cotizacion ${s.numero}',
      author: 'Ferreteria El Constructor',
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _cabecera('SOLICITUD DE COTIZACION', s.numero, fecha(s.fecha)),
          pw.SizedBox(height: 20),
          _proveedor(s),
          pw.SizedBox(height: 16),
          _barra('ITEMS SOLICITADOS'),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(62),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(58),
              3: const pw.FixedColumnWidth(72),
              if (conRef) 4: const pw.FixedColumnWidth(96),
            },
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _celda('CODIGO', negrita: true),
                  _celda('DESCRIPCION', negrita: true),
                  _celda('UNIDAD', negrita: true),
                  _celda('CANTIDAD', der: true, negrita: true),
                  if (conRef)
                    _celda('P. REF. (INFORMATIVO)', der: true, negrita: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _celda(s.codigo),
                  _celda(s.descripcion),
                  _celda(s.unidad),
                  _celda('${s.cantidad}', der: true, negrita: true),
                  if (conRef)
                    _celda(_soles(s.precioReferencial!), der: true),
                ],
              ),
            ],
          ),
          if (conRef) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'El precio de referencia corresponde al ultimo costo registrado y es solo informativo; no constituye una oferta ni un precio acordado.',
              style: pw.TextStyle(fontSize: 7.5, color: _gris),
            ),
          ],
          pw.SizedBox(height: 18),
          _barra('INFORMACION QUE SOLICITAMOS EN SU COTIZACION'),
          pw.SizedBox(height: 8),
          for (final t in const [
            'Precio unitario vigente (indicar si incluye IGV)',
            'Gastos de envio o flete',
            'Plazo de entrega',
            'Condiciones de pago',
            'Fecha de validez de la oferta',
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
              child: pw.Row(children: [
                pw.Container(
                  width: 9,
                  height: 9,
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _tinta, width: 0.8)),
                ),
                pw.SizedBox(width: 8),
                pw.Text(t, style: const pw.TextStyle(fontSize: 10)),
              ]),
            ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Responder antes del ${fecha(s.respuestaAntes)} al telefono ${AppConstants.telefonoFerreteria}.',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Este documento es una solicitud de cotizacion. No constituye una orden de compra ni un compromiso de adquisicion. '
            'Los precios y condiciones seran los que el proveedor indique en su cotizacion.',
            style: pw.TextStyle(fontSize: 8.5, color: _gris),
          ),
          pw.SizedBox(height: 50),
          _firmas('Solicitado por: ${s.solicitante}', 'Recibido por el proveedor'),
        ],
      ),
    );
    return doc.save();
  }

  // --------------------------------------------------- orden de compra

  static Future<Uint8List> ordenCompraPdf(SolicitudCotizacion s) async {
    final c = s.cotizacion!;
    final doc = pw.Document(
      title: 'Orden de compra ${s.ordenNumero}',
      author: 'Ferreteria El Constructor',
    );
    pw.Widget total(String e, String v, {bool grande = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(e,
                    style: pw.TextStyle(
                        fontSize: grande ? 11 : 9,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(
                width: 90,
                child: pw.Text(v,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        fontSize: grande ? 14 : 10,
                        fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        );

    final precioSinIgv =
        c.incluyeIgv ? c.subtotal(s.cantidad) / s.cantidad : c.precioUnitario;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _cabecera('ORDEN DE COMPRA', s.ordenNumero ?? '-',
              fecha(s.fechaOrden ?? DateTime.now())),
          pw.SizedBox(height: 6),
          pw.Text('Referencia: solicitud de cotizacion ${s.numero}',
              style: pw.TextStyle(fontSize: 9, color: _gris)),
          pw.SizedBox(height: 16),
          _proveedor(s),
          pw.SizedBox(height: 16),
          _barra('DETALLE DE LA ORDEN'),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: const pw.FixedColumnWidth(58),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(48),
              3: const pw.FixedColumnWidth(66),
              4: const pw.FixedColumnWidth(76),
            },
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _celda('CODIGO', negrita: true),
                  _celda('DESCRIPCION', negrita: true),
                  _celda('CANT.', der: true, negrita: true),
                  _celda('P. UNIT.', der: true, negrita: true),
                  _celda('IMPORTE', der: true, negrita: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _celda(s.codigo),
                  _celda(s.descripcion),
                  _celda('${s.cantidad} ${s.unidad}', der: true),
                  _celda(precioSinIgv.toStringAsFixed(2), der: true),
                  _celda(c.subtotal(s.cantidad).toStringAsFixed(2),
                      der: true, negrita: true),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          total('SUBTOTAL', _soles(c.subtotal(s.cantidad))),
          total('IGV (18%)', _soles(c.igv(s.cantidad))),
          total('ENVIO / FLETE', _soles(c.envio)),
          pw.SizedBox(height: 4),
          total('TOTAL', _soles(c.total(s.cantidad)), grande: true),
          pw.SizedBox(height: 18),
          _barra('CONDICIONES ACORDADAS'),
          pw.SizedBox(height: 6),
          _fila('VALIDEZ OFERTA', 'Hasta el ${fecha(c.validaHasta)}'),
          _fila('PLAZO ENTREGA', '${c.plazoEntregaDias} dias'),
          _fila('PAGO', c.condicionesPago),
          if (c.observaciones.trim().isNotEmpty)
            _fila('OBSERVACIONES', c.observaciones),
          pw.SizedBox(height: 50),
          _firmas('Autorizado por: ${s.solicitante}', 'Conforme del proveedor'),
        ],
      ),
    );
    return doc.save();
  }

  // ------------------------------------------------------- compartir

  static Future<void> compartir(
      Uint8List bytes, String nombre, String asunto) async {
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/$nombre');
    await archivo.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: asunto,
      text: asunto,
    );
  }

  static Future<void> compartirSolicitud(SolicitudCotizacion s) async =>
      compartir(await solicitudPdf(s), '${s.numero}.pdf',
          'Solicitud de cotizacion ${s.numero}');

  static Future<void> compartirOrden(SolicitudCotizacion s) async =>
      compartir(await ordenCompraPdf(s), '${s.ordenNumero}.pdf',
          'Orden de compra ${s.ordenNumero}');
}
