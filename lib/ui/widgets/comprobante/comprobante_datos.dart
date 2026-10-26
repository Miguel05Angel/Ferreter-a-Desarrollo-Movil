import '../../../core/constants/app_constants.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';

/// Cadena que va dentro del QR del comprobante, con el formato de la
/// representacion impresa de SUNAT:
/// RUC | tipo | serie | numero | IGV | total | fecha | tipo doc. cliente | doc. cliente |
String qrSunat(Venta v, Cliente? cliente) {
  final partes = v.numero.split('-');
  final serie = partes.first;
  final numero = partes.length > 1 ? partes.last : '';
  final tipo = v.comprobante == 'Factura' ? '01' : '03';
  final f = v.fecha;
  final fecha =
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
  final tipoDoc = cliente == null
      ? '0'
      : (cliente.tipoDocumento == 'RUC' ? '6' : '1');
  final doc = cliente?.documento ?? '00000000';
  return '${AppConstants.rucFerreteria}|$tipo|$serie|$numero|'
      '${v.igv.toStringAsFixed(2)}|${v.total.toStringAsFixed(2)}|'
      '$fecha|$tipoDoc|$doc|';
}
