import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Barras animadas (por hora, dia de la semana o dia del mes). Tocar una
/// barra muestra su detalle.
class GraficoBarras extends StatefulWidget {
  final List<String> etiquetas;
  final List<double> valores;
  final List<int> cantidades;

  const GraficoBarras({
    super.key,
    required this.etiquetas,
    required this.valores,
    required this.cantidades,
  });

  @override
  State<GraficoBarras> createState() => _GraficoBarrasState();
}

class _GraficoBarrasState extends State<GraficoBarras> {
  int? _sel;
  static const double _alto = 210;

  @override
  void didUpdateWidget(GraficoBarras old) {
    super.didUpdateWidget(old);
    if (old.valores.length != widget.valores.length) _sel = null;
  }

  @override
  Widget build(BuildContext context) {
    final firma =
        '${widget.etiquetas.length}-${widget.valores.map((v) => v.round()).join(',')}';
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final sel = _sel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey(sel),
            height: 22,
            alignment: Alignment.centerLeft,
            child: Text(
              sel == null
                  ? 'Toca una barra para ver el detalle'
                  : '${widget.etiquetas[sel]}:  ${Formatters.soles(widget.valores[sel])}'
                      '  |  ${widget.cantidades[sel]} ${widget.cantidades[sel] == 1 ? 'venta' : 'ventas'}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: sel == null ? FontWeight.w500 : FontWeight.w900,
                color: sel == null ? Colors.grey.shade600 : AppTheme.primary,
              ),
            ),
          ),
        ),
        SizedBox(
          height: _alto,
          child: LayoutBuilder(
            builder: (context, caja) {
              final n = widget.valores.length;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final i = (d.localPosition.dx / (caja.maxWidth / n)).floor();
                  if (i < 0 || i >= n) return;
                  setState(() => _sel = _sel == i ? null : i);
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(firma),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CustomPaint(
                    size: Size(caja.maxWidth, _alto),
                    painter: _BarrasPainter(
                      etiquetas: widget.etiquetas,
                      valores: widget.valores,
                      progreso: v,
                      seleccionada: sel,
                      colorTexto: oscuro ? Colors.grey.shade400 : Colors.grey.shade700,
                      colorLinea: oscuro ? AppTheme.bordeOscuro : const Color(0xFFE0DAD0),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BarrasPainter extends CustomPainter {
  final List<String> etiquetas;
  final List<double> valores;
  final double progreso;
  final int? seleccionada;
  final Color colorTexto;
  final Color colorLinea;

  _BarrasPainter({
    required this.etiquetas,
    required this.valores,
    required this.progreso,
    required this.seleccionada,
    required this.colorTexto,
    required this.colorLinea,
  });

  void _texto(Canvas c, String t, Offset centro, double tam, Color color,
      {FontWeight peso = FontWeight.w600}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(fontSize: tam, color: color, fontWeight: peso)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(centro.dx - tp.width / 2, centro.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const abajo = 24.0, arriba = 10.0;
    final altoGrafico = size.height - abajo - arriba;
    final n = valores.length;
    if (n == 0) return;
    final maximo = math.max(valores.reduce(math.max), 1.0);

    final linea = Paint()
      ..color = colorLinea
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = arriba + altoGrafico * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea);
    }

    final ranura = size.width / n;
    final ancho = math.min(ranura * 0.62, 34.0);
    final salto = n > 16 ? 5 : (n > 9 ? 2 : 1);

    for (var i = 0; i < n; i++) {
      final cx = ranura * i + ranura / 2;
      final h = valores[i] / maximo * altoGrafico * progreso;
      final base = arriba + altoGrafico;
      final esSel = seleccionada == i;
      if (valores[i] > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - ancho / 2, base - h, ancho, h),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = esSel ? AppTheme.amarilloSenal : AppTheme.primary,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(cx - ancho / 2, base - 2, ancho, 2),
          Paint()..color = colorTexto.withOpacity(0.35),
        );
      }
      if (i % salto == 0 || esSel) {
        _texto(canvas, etiquetas[i], Offset(cx, size.height - 10), 10.5,
            esSel ? AppTheme.primary : colorTexto,
            peso: esSel ? FontWeight.w900 : FontWeight.w600);
      }
    }
  }

  @override
  bool shouldRepaint(_BarrasPainter old) =>
      old.progreso != progreso ||
      old.seleccionada != seleccionada ||
      old.valores != valores;
}

class SegmentoDona {
  final String nombre;
  final double valor;
  final Color color;
  const SegmentoDona(this.nombre, this.valor, this.color);
}

/// Dona animada con leyenda. Tocar un elemento de la leyenda resalta su
/// segmento.
class GraficoDona extends StatefulWidget {
  final List<SegmentoDona> segmentos;
  final String centroTitulo;

  const GraficoDona({
    super.key,
    required this.segmentos,
    required this.centroTitulo,
  });

  @override
  State<GraficoDona> createState() => _GraficoDonaState();
}

class _GraficoDonaState extends State<GraficoDona> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final segs = widget.segmentos.where((s) => s.valor > 0).toList();
    final total = segs.fold(0.0, (s, e) => s + e.valor);
    if (total <= 0) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('Sin ventas en este periodo')),
      );
    }
    final firma = segs.map((s) => '${s.nombre}${s.valor.round()}').join('|');
    final sel = _sel != null && _sel! < segs.length ? segs[_sel!] : null;

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(firma),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CustomPaint(
                  size: const Size(210, 210),
                  painter: _DonaPainter(segs, total, v, _sel),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(sel?.nombre ?? 'total'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sel?.nombre ?? widget.centroTitulo,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            letterSpacing: 1,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(Formatters.soles(sel?.valor ?? total),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                    if (sel != null)
                      Text('${(sel.valor / total * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: sel.color)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < segs.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _sel = _sel == i ? null : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: _sel == i ? segs[i].color.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: segs[i].color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(segs[i].nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('${(segs[i].valor / total * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Text(Formatters.soles(segs[i].valor),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DonaPainter extends CustomPainter {
  final List<SegmentoDona> segmentos;
  final double total;
  final double progreso;
  final int? seleccionado;

  _DonaPainter(this.segmentos, this.total, this.progreso, this.seleccionado);

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 34.0;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - 22;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    var inicio = -math.pi / 2;
    const hueco = 0.025;

    for (var i = 0; i < segmentos.length; i++) {
      final barrido = segmentos[i].valor / total * 2 * math.pi * progreso;
      final p = Paint()
        ..color = segmentos[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = seleccionado == i ? grosor + 10 : grosor;
      final dibujar = segmentos.length == 1 ? barrido : math.max(barrido - hueco, 0.0);
      if (dibujar > 0) canvas.drawArc(rect, inicio, dibujar, false, p);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(_DonaPainter old) =>
      old.progreso != progreso ||
      old.seleccionado != seleccionado ||
      old.segmentos != segmentos;
}
