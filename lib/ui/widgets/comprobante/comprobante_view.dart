import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';
import 'codigos_painter.dart';
import 'numero_a_letras.dart';

/// Comprobante electronico (boleta o factura) con aspecto de papel
/// termico: bordes dentados, cabecera con caja de RUC, tabla de detalle,
/// totales, importe en letras, QR y codigo de barras.
class ComprobanteView extends StatelessWidget {
  final Venta venta;
  final Cliente? cliente;
  final String vendedor;

  const ComprobanteView({
    super.key,
    required this.venta,
    this.cliente,
    this.vendedor = 'Caja 01',
  });

  static const Color _tinta = Color(0xFF1B1B1B);
  static const Color _papel = Color(0xFFFCFBF7);

  bool get _esFactura => venta.comprobante == 'Factura';

  String get _titulo => _esFactura
      ? 'FACTURA ELECTRONICA'
      : 'BOLETA DE VENTA ELECTRONICA';

  String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final f = venta.fecha;
    final fecha =
        '${_dosDigitos(f.day)}/${_dosDigitos(f.month)}/${f.year}';
    final hora =
        '${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}:${_dosDigitos(f.second)}';
    final doc = cliente != null && cliente!.documento.isNotEmpty
        ? '${cliente!.tipoDocumento}: ${cliente!.documento}'
        : 'DNI: 00000000';

    return PhysicalShape(
      clipper: _PapelClipper(),
      color: _papel,
      elevation: 8,
      shadowColor: Colors.black,
      child: DefaultTextStyle(
        style: const TextStyle(color: _tinta, fontSize: 12.5, height: 1.3),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----------------------------------------------- cabecera
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const ShapeDecoration(
                    color: _tinta,
                    shape: BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(14)),
                    ),
                  ),
                  child: const Icon(Icons.hardware,
                      color: Color(0xFFFF6D00), size: 26),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'EL CONSTRUCTOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
              const Text(
                'FERRETERIA  -  MATERIALES  -  HERRAMIENTAS',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                AppConstants.direccionFerreteria,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
              const Text(
                'Tel: ${AppConstants.telefonoFerreteria}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 14),

              // ------------------------------------------- caja del RUC
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _tinta, width: 1.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'R.U.C. ${AppConstants.rucFerreteria}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                    Container(
                      color: _tinta,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Text(
                        _titulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        venta.numero,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ------------------------------------------ datos de venta
              _Dato('FECHA', fecha, 'HORA', hora),
              _Dato('CLIENTE', venta.clienteNombre),
              _Dato('DOC.', doc.replaceFirst(': ', '  ')),
              if (_esFactura &&
                  cliente != null &&
                  cliente!.direccion.isNotEmpty)
                _Dato('DIREC.', cliente!.direccion),
              _Dato('PAGO', venta.metodoPago, 'CAJERO', vendedor),
              const SizedBox(height: 12),

              // ------------------------------------------------- detalle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: _tinta,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 34, child: _Cab('CANT')),
                    Expanded(child: _Cab('DESCRIPCION')),
                    SizedBox(width: 56, child: _Cab('P.UNIT', der: true)),
                    SizedBox(width: 64, child: _Cab('IMPORTE', der: true)),
                  ],
                ),
              ),
              ...venta.items.map(
                (i) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 7),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFCFC9BC)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text('${i.cantidad}',
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800)),
                      ),
                      Expanded(
                        child: Text(i.nombre,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          i.precioUnitario.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 11.5),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          i.subtotal.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ------------------------------------------------ totales
              _Total('OP. GRAVADA', Formatters.soles(venta.subtotal)),
              _Total('IGV (18%)', Formatters.soles(venta.igv)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: _tinta, width: 1.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                    Text(
                      Formatters.soles(venta.total),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'SON: ${montoEnLetras(venta.total)}',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              const _Corte(),
              const SizedBox(height: 14),

              // ------------------------------------------- QR y codigos
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCFC9BC)),
                    ),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: QrIlustrativoPainter(
                          semilla:
                              '${AppConstants.rucFerreteria}|${venta.numero}|${venta.total}',
                          color: _tinta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HASH',
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        Text(
                          hashVisual(venta.id),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 9.5),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: CodigoBarrasPainter(venta.numero),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          venta.numero,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.5,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Representacion impresa de la ${_esFactura ? 'factura' : 'boleta de venta'} '
                'electronica. Conserve este comprobante para cualquier cambio o reclamo.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, height: 1.35),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gracias por su preferencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800),
              ),
              const Text(
                'Vuelva pronto',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cab extends StatelessWidget {
  final String texto;
  final bool der;

  const _Cab(this.texto, {this.der = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: der ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String e1;
  final String v1;
  final String? e2;
  final String? v2;

  const _Dato(this.e1, this.v1, [this.e2, this.v2]);

  Widget _par(String e, String v) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$e  ',
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900),
            ),
            TextSpan(text: v, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: e2 == null
          ? _par(e1, v1)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_par(e1, v1), _par(e2!, v2!)],
            ),
    );
  }
}

class _Total extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Total(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          Text(valor,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Corte extends StatelessWidget {
  const _Corte();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(
                width: 4, height: 1.4, color: const Color(0xFF8C8577)),
          ),
        );
      },
    );
  }
}

/// Bordes superior e inferior dentados, como un ticket cortado.
class _PapelClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const diente = 9.0;
    const prof = 6.0;
    final p = Path()..moveTo(0, prof);
    var x = 0.0;
    var abajo = false;
    while (x < size.width) {
      x += diente;
      p.lineTo(x > size.width ? size.width : x, abajo ? prof : 0);
      abajo = !abajo;
    }
    p.lineTo(size.width, size.height - prof);
    x = size.width;
    abajo = false;
    while (x > 0) {
      x -= diente;
      p.lineTo(x < 0 ? 0 : x, abajo ? size.height - prof : size.height);
      abajo = !abajo;
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_PapelClipper oldClipper) => false;
}
