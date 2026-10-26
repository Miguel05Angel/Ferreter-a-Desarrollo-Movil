import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/models/venta.dart';

/// Imagen del comprobante ya capturada.
class Captura {
  final Uint8List bytes;
  final int ancho;
  final int alto;
  const Captura(this.bytes, this.ancho, this.alto);
}

/// Convierte el comprobante que se ve en pantalla en una imagen PNG o un
/// PDF y abre el menu de compartir del telefono (WhatsApp, correo, etc.).
class ComprobanteExport {
  ComprobanteExport._();

  /// Captura el widget envuelto por el [RepaintBoundary] de [llave].
  static Future<Captura> capturar(
    GlobalKey llave, {
    double pixelRatio = 3,
    Color fondo = const Color(0xFFF2EFE9),
    double margen = 24,
  }) async {
    final objeto = llave.currentContext?.findRenderObject();
    if (objeto is! RenderRepaintBoundary) {
      throw StateError('El comprobante no esta visible en pantalla.');
    }
    final ui.Image imagen = await objeto.toImage(pixelRatio: pixelRatio);

    final m = margen * pixelRatio;
    final ancho = (imagen.width + m * 2).round();
    final alto = (imagen.height + m * 2).round();

    final grabador = ui.PictureRecorder();
    final lienzo = Canvas(grabador);
    lienzo.drawRect(
      Rect.fromLTWH(0, 0, ancho.toDouble(), alto.toDouble()),
      Paint()..color = fondo,
    );
    lienzo.drawImage(imagen, Offset(m, m), Paint());
    final compuesta = await grabador.endRecording().toImage(ancho, alto);
    final datos = await compuesta.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    compuesta.dispose();
    if (datos == null) throw StateError('No se pudo generar la imagen.');
    return Captura(datos.buffer.asUint8List(), ancho, alto);
  }

  /// PDF de una sola pagina con la misma proporcion que el comprobante.
  static Future<Uint8List> aPdf(Captura c, Venta venta) async {
    final doc = pw.Document(
      title: '${venta.comprobante} ${venta.numero}',
      author: AppConstants.nombreApp,
    );
    const anchoPagina = 420.0;
    final altoPagina = anchoPagina * c.alto / c.ancho;
    final imagen = pw.MemoryImage(c.bytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(anchoPagina, altoPagina),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(imagen, fit: pw.BoxFit.fill),
      ),
    );
    return doc.save();
  }

  static String _nombreBase(Venta v) =>
      '${v.comprobante}_${v.numero}'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');

  static String _texto(Venta v) =>
      '${v.comprobante} ${v.numero} - ${AppConstants.nombreApp}\n'
      'Total: ${Formatters.soles(v.total)}';

  static Future<File> _guardar(String nombre, Uint8List bytes) async {
    final carpeta = await getTemporaryDirectory();
    final archivo = File('${carpeta.path}/$nombre');
    return archivo.writeAsBytes(bytes, flush: true);
  }

  static Future<void> compartirImagen(GlobalKey llave, Venta venta) async {
    final captura = await capturar(llave);
    final archivo = await _guardar('${_nombreBase(venta)}.png', captura.bytes);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'image/png')],
      subject: '${venta.comprobante} ${venta.numero}',
      text: _texto(venta),
    );
  }

  static Future<void> compartirPdf(GlobalKey llave, Venta venta) async {
    final captura = await capturar(llave);
    final pdf = await aPdf(captura, venta);
    final archivo = await _guardar('${_nombreBase(venta)}.pdf', pdf);
    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: '${venta.comprobante} ${venta.numero}',
      text: _texto(venta),
    );
  }
}
