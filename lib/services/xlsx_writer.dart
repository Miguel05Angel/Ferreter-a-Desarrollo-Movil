import 'dart:convert';
import 'dart:typed_data';

/// Celda con estilo. Un valor suelto (String o numero) usa el estilo normal.
class Cel {
  final Object? valor;
  final int estilo;
  const Cel(this.valor, [this.estilo = 0]);
}

class XlsxHoja {
  final String nombre;
  final List<List<Object?>> filas;
  final List<double> anchos;
  const XlsxHoja(this.nombre, this.filas, {this.anchos = const []});
}

/// Genera un libro de Excel (.xlsx) con varias hojas, encabezados con color
/// y formato de moneda, sin paquetes externos (ZIP sin compresion).
class XlsxWriter {
  XlsxWriter._();

  static const int sNormal = 0;
  static const int sEncabezado = 1;
  static const int sMoneda = 2;
  static const int sTitulo = 3;
  static const int sNegrita = 4;
  static const int sEntero = 5;

  static const _main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _rel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _cab = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _col(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  static String _nombreHoja(String n) {
    final limpio = n.replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ').trim();
    return limpio.length > 31 ? limpio.substring(0, 31) : limpio;
  }

  static String _xmlHoja(XlsxHoja h) {
    final b = StringBuffer('$_cab<worksheet xmlns="$_main">');
    if (h.anchos.isNotEmpty) {
      b.write('<cols>');
      for (var i = 0; i < h.anchos.length; i++) {
        b.write('<col min="${i + 1}" max="${i + 1}" width="${h.anchos[i]}" customWidth="1"/>');
      }
      b.write('</cols>');
    }
    b.write('<sheetData>');
    for (var r = 0; r < h.filas.length; r++) {
      b.write('<row r="${r + 1}">');
      final fila = h.filas[r];
      for (var c = 0; c < fila.length; c++) {
        final raw = fila[c];
        Object? v = raw;
        var s = 0;
        if (raw is Cel) {
          v = raw.valor;
          s = raw.estilo;
        }
        if (v == null) continue;
        final ref = '${_col(c)}${r + 1}';
        if (v is num) {
          b.write('<c r="$ref" s="$s"><v>$v</v></c>');
        } else {
          b.write('<c r="$ref" s="$s" t="inlineStr"><is>'
              '<t xml:space="preserve">${_esc(v.toString())}</t></is></c>');
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  static const String _estilos = '$_cab<styleSheet xmlns="$_main">'
      '<fonts count="4">'
      '<font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="15"/><color rgb="FFD95800"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="3">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF263238"/><bgColor indexed="64"/></patternFill></fill>'
      '</fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="6">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
      '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
      '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '<xf numFmtId="1" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';

  /// Devuelve los bytes del archivo .xlsx.
  static Uint8List construir(List<XlsxHoja> hojas) {
    final zip = _Zip();
    final tipos = StringBuffer('$_cab<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');
    final libro = StringBuffer('$_cab<workbook xmlns="$_main" xmlns:r="$_rel"><sheets>');
    final rels = StringBuffer('$_cab<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');

    for (var i = 0; i < hojas.length; i++) {
      final n = i + 1;
      tipos.write('<Override PartName="/xl/worksheets/sheet$n.xml" '
          'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
      libro.write('<sheet name="${_esc(_nombreHoja(hojas[i].nombre))}" sheetId="$n" r:id="rId$n"/>');
      rels.write('<Relationship Id="rId$n" Type="$_rel/worksheet" Target="worksheets/sheet$n.xml"/>');
      zip.agregar('xl/worksheets/sheet$n.xml', _xmlHoja(hojas[i]));
    }
    tipos.write('</Types>');
    libro.write('</sheets></workbook>');
    rels.write('<Relationship Id="rId${hojas.length + 1}" Type="$_rel/styles" Target="styles.xml"/></Relationships>');

    zip.agregar('[Content_Types].xml', tipos.toString());
    zip.agregar(
        '_rels/.rels',
        '$_cab<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/></Relationships>');
    zip.agregar('xl/workbook.xml', libro.toString());
    zip.agregar('xl/_rels/workbook.xml.rels', rels.toString());
    zip.agregar('xl/styles.xml', _estilos);
    return zip.cerrar();
  }
}

/// ZIP minimo (metodo "stored", sin compresion): suficiente para un .xlsx.
class _Zip {
  final BytesBuilder _datos = BytesBuilder();
  final BytesBuilder _central = BytesBuilder();
  int _entradas = 0;

  static final List<int> _tabla = List<int>.generate(256, (i) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    return c;
  });

  static int _crc32(List<int> bytes) {
    var c = 0xFFFFFFFF;
    for (final b in bytes) {
      c = _tabla[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  void agregar(String nombre, String contenido) {
    final nom = utf8.encode(nombre);
    final dat = utf8.encode(contenido);
    final crc = _crc32(dat);
    final offset = _datos.length;

    final h = ByteData(30);
    h.setUint32(0, 0x04034b50, Endian.little);
    h.setUint16(4, 20, Endian.little);
    h.setUint16(6, 0x0800, Endian.little); // nombres en UTF-8
    h.setUint16(8, 0, Endian.little); // sin compresion
    h.setUint16(10, 0, Endian.little);
    h.setUint16(12, 0x21, Endian.little); // 1980-01-01
    h.setUint32(14, crc, Endian.little);
    h.setUint32(18, dat.length, Endian.little);
    h.setUint32(22, dat.length, Endian.little);
    h.setUint16(26, nom.length, Endian.little);
    h.setUint16(28, 0, Endian.little);
    _datos.add(h.buffer.asUint8List());
    _datos.add(nom);
    _datos.add(dat);

    final c = ByteData(46);
    c.setUint32(0, 0x02014b50, Endian.little);
    c.setUint16(4, 20, Endian.little);
    c.setUint16(6, 20, Endian.little);
    c.setUint16(8, 0x0800, Endian.little);
    c.setUint16(10, 0, Endian.little);
    c.setUint16(12, 0, Endian.little);
    c.setUint16(14, 0x21, Endian.little);
    c.setUint32(16, crc, Endian.little);
    c.setUint32(20, dat.length, Endian.little);
    c.setUint32(24, dat.length, Endian.little);
    c.setUint16(28, nom.length, Endian.little);
    c.setUint16(30, 0, Endian.little);
    c.setUint16(32, 0, Endian.little);
    c.setUint16(34, 0, Endian.little);
    c.setUint16(36, 0, Endian.little);
    c.setUint32(38, 0, Endian.little);
    c.setUint32(42, offset, Endian.little);
    _central.add(c.buffer.asUint8List());
    _central.add(nom);
    _entradas++;
  }

  Uint8List cerrar() {
    final inicio = _datos.length;
    final central = _central.toBytes();
    _datos.add(central);
    final f = ByteData(22);
    f.setUint32(0, 0x06054b50, Endian.little);
    f.setUint16(4, 0, Endian.little);
    f.setUint16(6, 0, Endian.little);
    f.setUint16(8, _entradas, Endian.little);
    f.setUint16(10, _entradas, Endian.little);
    f.setUint32(12, central.length, Endian.little);
    f.setUint32(16, inicio, Endian.little);
    f.setUint16(20, 0, Endian.little);
    _datos.add(f.buffer.asUint8List());
    return _datos.toBytes();
  }
}
