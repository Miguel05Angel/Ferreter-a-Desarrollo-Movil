import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/material.dart';

/// Alto reservado arriba para la barra de navegación flotante.
const double kNavAlto = 92;

// ===========================================================================
// PALETA Y TEMA
// ===========================================================================

/// Colores de significado. El acento se usa con moderación.
class Tono {
  static const acento = Color(0xFFE8590C);
  static const ok = Color(0xFF2E9E6A);
  static const alerta = Color(0xFFD99A00);
  static const peligro = Color(0xFFD64545);
  static const info = Color(0xFF3B6FD8);
  static const violeta = Color(0xFF7B5CD6);
}

/// Tema del panel. Claro = papel cálido; oscuro = grafito.
ThemeData temaAdmin(bool oscuro) {
  final base = oscuro
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  final fondo = oscuro ? const Color(0xFF0C0C0E) : const Color(0xFFF5F4F0);
  final panel = oscuro ? const Color(0xFF151518) : Colors.white;
  final tinta = oscuro ? const Color(0xFFF1F0EC) : const Color(0xFF121212);
  final tenue = oscuro ? const Color(0xFF8E8C86) : const Color(0xFF75726A);
  final linea = oscuro ? const Color(0xFF26262B) : const Color(0xFFE6E3DC);
  return base.copyWith(
    scaffoldBackgroundColor: fondo,
    dividerColor: linea,
    colorScheme: base.colorScheme.copyWith(
      primary: Tono.acento,
      onPrimary: Colors.white,
      surface: panel,
      onSurface: tinta,
      onSurfaceVariant: tenue,
      outlineVariant: linea,
      error: Tono.peligro,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Tono.acento),
  );
}

extension AdminColores on BuildContext {
  ColorScheme get _esq => Theme.of(this).colorScheme;
  Color get fondo => Theme.of(this).scaffoldBackgroundColor;
  Color get panel => _esq.surface;
  Color get tinta => _esq.onSurface;
  Color get tenue => _esq.onSurfaceVariant;
  Color get linea => _esq.outlineVariant;
  Color get panel2 => Color.alphaBlend(tinta.withOpacity(0.045), panel);
  bool get oscuro => Theme.of(this).brightness == Brightness.dark;
}

/// Números con ancho fijo: las columnas de cifras no "bailan".
TextStyle estiloNum(
  BuildContext c, {
  double size = 14,
  FontWeight peso = FontWeight.w700,
  Color? color,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: peso,
    color: color ?? c.tinta,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

// ===========================================================================
// FORMATOS
// ===========================================================================

String soles(double v) {
  final partes = v.abs().toStringAsFixed(2).split('.');
  final ent = partes[0];
  final buf = StringBuffer();
  for (var i = 0; i < ent.length; i++) {
    if (i > 0 && (ent.length - i) % 3 == 0) buf.write(',');
    buf.write(ent[i]);
  }
  return '${v < 0 ? '-' : ''}S/ $buf.${partes[1]}';
}

String entero(double v) => v.round().toString();

String fechaTxt(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/'
    '${f.month.toString().padLeft(2, '0')}/${f.year}';

String horaTxt(DateTime f) =>
    '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

String inicial(String n) =>
    n.trim().isEmpty ? '?' : n.trim().substring(0, 1).toUpperCase();

// ===========================================================================
// DIÁLOGOS Y AVISOS
// ===========================================================================

/// Diálogo con entrada suave (fundido + escala mínima).
Future<T?> dialogo<T>(BuildContext context, WidgetBuilder builder) {
  // El diálogo vive fuera del árbol del panel: se le pasa el mismo tema.
  final tema = Theme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, __) => Theme(data: tema, child: builder(ctx)),
    transitionBuilder: (ctx, anim, _, child) {
      final c = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(c),
          child: child,
        ),
      );
    },
  );
}

/// Aviso flotante, sobrio y centrado.
void toast(BuildContext context, String texto, {bool error = false}) {
  final ancho = MediaQuery.sizeOf(context).width;
  final lado = math.max(16.0, (ancho - 420) / 2);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.tinta,
        elevation: 6,
        margin: EdgeInsets.fromLTRB(lado, 0, lado, 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: Duration(seconds: error ? 6 : 3),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFFF8A80) : Tono.ok,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: context.fondo,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Ejecuta una escritura a Firestore y traduce los errores a un aviso claro.
/// Devuelve `true` si salió bien. Si falla, [alFallar] recibe el mensaje.
Future<bool> ejecutar(
  Future<void> Function() accion, {
  required String que,
  required void Function(String mensaje) alFallar,
}) async {
  try {
    await accion();
    return true;
  } on FirebaseException catch (e) {
    alFallar(
      e.code == 'permission-denied'
          ? 'Sin permiso para $que. Revisa que tu sesión siga activa y que '
              'tu rol sea Administrador.'
          : 'No se pudo $que (${e.code}).',
    );
    return false;
  } catch (e) {
    alFallar('No se pudo $que: $e');
    return false;
  }
}

class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto, this.error = false});

  final String texto;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Tono.peligro : Tono.ok;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfirmarDialogo extends StatelessWidget {
  const ConfirmarDialogo({
    super.key,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.mensaje,
    required this.textoConfirmar,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String mensaje;
  final String textoConfirmar;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.panel,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: context.linea),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icono, color: color, size: 26),
              ),
              const SizedBox(height: 18),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: context.tinta,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.tenue,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.tinta,
                        side: BorderSide(color: context.linea),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(textoConfirmar),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// CAMPOS
// ===========================================================================

InputDecoration decoCampo(
  BuildContext c,
  String etiqueta,
  IconData icono, {
  String? prefijo,
  String? hint,
  Widget? sufijo,
}) {
  OutlineInputBorder borde(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: col, width: w),
      );
  return InputDecoration(
    labelText: etiqueta,
    hintText: hint,
    labelStyle: TextStyle(color: c.tenue, fontSize: 13.5),
    floatingLabelStyle: const TextStyle(
      color: Tono.acento,
      fontWeight: FontWeight.w700,
    ),
    prefixIcon: Icon(icono, size: 19, color: c.tenue),
    prefixText: prefijo,
    prefixStyle: TextStyle(color: c.tinta, fontWeight: FontWeight.w600),
    suffixIcon: sufijo,
    filled: true,
    fillColor: c.panel2,
    errorMaxLines: 2,
    errorStyle: const TextStyle(
      color: Tono.peligro,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    border: borde(c.linea),
    enabledBorder: borde(c.linea),
    focusedBorder: borde(Tono.acento, 1.6),
    errorBorder: borde(Tono.peligro),
    focusedErrorBorder: borde(Tono.peligro, 1.6),
  );
}

/// Buscador con su propio controlador y botón de limpiar.
class BuscadorCampo extends StatefulWidget {
  const BuscadorCampo({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<BuscadorCampo> createState() => _BuscadorCampoState();
}

class _BuscadorCampoState extends State<BuscadorCampo> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color col, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col, width: w),
        );
    return TextField(
      controller: _c,
      onChanged: (v) {
        setState(() {});
        widget.onChanged(v);
      },
      style: TextStyle(color: context.tinta, fontSize: 14),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: context.tenue),
        prefixIcon: Icon(Icons.search_rounded, color: context.tenue),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                icon: Icon(Icons.close_rounded, size: 18, color: context.tenue),
                onPressed: () {
                  _c.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: context.panel,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: borde(context.linea),
        enabledBorder: borde(context.linea),
        focusedBorder: borde(Tono.acento, 1.6),
      ),
    );
  }
}

// ===========================================================================
// PIEZAS VISUALES
// ===========================================================================

/// Entrada con fundido y desplazamiento corto. `indice` escalona.
class Aparece extends StatefulWidget {
  const Aparece({super.key, required this.child, this.indice = 0});

  final Widget child;
  final int indice;

  @override
  State<Aparece> createState() => _ApareceState();
}

class _ApareceState extends State<Aparece> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curva =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.indice), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curva,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curva.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curva.value) * 14),
          child: child,
        ),
      ),
    );
  }
}

/// Superficie con borde fino. Si tiene `onTap` se eleva al pasar el mouse.
class Tarjeta extends StatefulWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radio = 16,
    this.color,
    this.elevarAlHover = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radio;
  final Color? color;
  final bool elevarAlHover;

  @override
  State<Tarjeta> createState() => _TarjetaState();
}

class _TarjetaState extends State<Tarjeta> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final vivo = _h && widget.onTap != null;
    final sube = vivo && widget.elevarAlHover;
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, sube ? -2 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? context.panel,
            borderRadius: BorderRadius.circular(widget.radio),
            border: Border.all(
              color: vivo ? Tono.acento.withOpacity(0.55) : context.linea,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  sube ? (context.oscuro ? 0.38 : 0.09) : (context.oscuro ? 0.16 : 0.025),
                ),
                blurRadius: sube ? 24 : 8,
                offset: Offset(0, sube ? 12 : 3),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, this.color, {super.key, this.punto = true});

  final String texto;
  final Color color;
  final bool punto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón-píldora de filtro.
class Pildora extends StatelessWidget {
  const Pildora({
    super.key,
    required this.texto,
    required this.activo,
    required this.onTap,
    this.contador,
  });

  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final int? contador;

  @override
  Widget build(BuildContext context) {
    final color = activo ? context.fondo : context.tinta;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? context.tinta : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activo ? context.tinta : context.linea),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (contador != null) ...[
                const SizedBox(width: 7),
                Text(
                  '$contador',
                  style: TextStyle(
                    color: color.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SegItem {
  const SegItem({this.icono, this.texto, this.contador});

  final IconData? icono;
  final String? texto;
  final int? contador;
}

/// Control segmentado con indicador que se desliza.
class Segmentos extends StatelessWidget {
  const Segmentos({
    super.key,
    required this.items,
    required this.indice,
    required this.onCambio,
    this.anchoItem = 120,
    this.alto = 38,
    this.invertido = false,
    this.tooltips,
  });

  final List<SegItem> items;
  final int indice;
  final ValueChanged<int> onCambio;
  final double anchoItem;
  final double alto;
  final bool invertido;
  final List<String>? tooltips;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final pulgar = invertido ? context.tinta : context.panel;
    final sobre = invertido ? context.fondo : context.tinta;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.panel2,
        borderRadius: BorderRadius.circular((alto + 8) / 2),
        border: Border.all(color: context.linea),
      ),
      child: SizedBox(
        width: anchoItem * n,
        height: alto,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * indice / (n - 1), 0),
              child: Container(
                width: anchoItem,
                height: alto,
                decoration: BoxDecoration(
                  color: pulgar,
                  borderRadius: BorderRadius.circular(alto / 2),
                  border: invertido ? null : Border.all(color: context.linea),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++) _segmento(context, i, sobre),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmento(BuildContext context, int i, Color sobre) {
    final it = items[i];
    final color = i == indice ? sobre : context.tenue;
    Widget w = SizedBox(
      width: anchoItem,
      height: alto,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(alto / 2),
          onTap: () => onCambio(i),
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: const Duration(milliseconds: 220),
              builder: (c, col, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (it.icono != null) Icon(it.icono, size: 17, color: col),
                  if (it.icono != null && it.texto != null)
                    const SizedBox(width: 7),
                  if (it.texto != null)
                    Flexible(
                      child: Text(
                        it.texto!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (it.contador != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${it.contador}',
                      style: TextStyle(
                        color: col?.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltips != null) w = Tooltip(message: tooltips![i], child: w);
    return w;
  }
}

class EncabezadoPagina extends StatelessWidget {
  const EncabezadoPagina({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones = const [],
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: context.tinta,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitulo!,
                style: TextStyle(fontSize: 14, color: context.tenue),
              ),
            ],
          ],
        ),
        if (acciones.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 10, children: acciones),
      ],
    );
  }
}

/// Indicador numérico: el valor "sube" hasta su cifra.
class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.titulo,
    required this.valor,
    required this.formato,
    this.nota,
    this.color = Tono.acento,
  });

  final String titulo;
  final double valor;
  final String Function(double) formato;
  final String? nota;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      elevarAlHover: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.tenue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: valor),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => Text(
                formato(v),
                style: estiloNum(c, size: 30, peso: FontWeight.w800)
                    .copyWith(letterSpacing: -1),
              ),
            ),
          ),
          if (nota != null) ...[
            const SizedBox(height: 6),
            Text(nota!, style: TextStyle(fontSize: 12, color: context.tenue)),
          ],
        ],
      ),
    );
  }
}

class Vacio extends StatelessWidget {
  const Vacio({super.key, required this.icono, required this.titulo, this.detalle});

  final IconData icono;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Aparece(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.panel2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.linea),
                  ),
                  child: Icon(icono, size: 30, color: context.tenue),
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.tinta,
                  ),
                ),
                if (detalle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detalle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.tenue,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 34,
        height: 34,
        child: CircularProgressIndicator(strokeWidth: 3, color: Tono.acento),
      ),
    );
  }
}

class ErrorCaja extends StatelessWidget {
  const ErrorCaja({super.key, required this.error, this.explicacion});

  final Object error;
  final String? explicacion;

  @override
  Widget build(BuildContext context) {
    final denegado = error is FirebaseException &&
        (error as FirebaseException).code == 'permission-denied';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Tarjeta(
            elevarAlHover: false,
            radio: 20,
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Tono.peligro.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Tono.peligro),
                ),
                const SizedBox(height: 16),
                Text(
                  denegado
                      ? 'Firestore negó el acceso'
                      : 'No se pudieron cargar los datos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.tinta,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  denegado
                      ? (explicacion ??
                          'Las reglas de ferreteria-db no permiten a este '
                              'usuario leer esta colección.')
                      : 'Revisa tu conexión y la consola del navegador.',
                  style: TextStyle(
                    color: context.tenue,
                    height: 1.5,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$error',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.tenue, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
