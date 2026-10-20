import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/venta.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../../providers/venta_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/carrito/carrito_flotante.dart';
import '../../widgets/comprobante/codigos_painter.dart';
import '../../widgets/comprobante/comprobante_view.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/tilt_3d.dart';
import '../main/main_shell_screen.dart';

/// Flujo de pago en tres fases: elegir metodo (con su panel propio), procesar
/// y confirmacion con el comprobante. El pago es simulado: no se cobra ni se
/// guarda ningun dato de tarjeta.
class PagoScreen extends StatefulWidget {
  final Cliente? cliente;
  final String comprobante;

  const PagoScreen({super.key, required this.cliente, required this.comprobante});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  late final ThemeData _tema = AppTheme.dark;
  late final int _articulos;
  late final int _unidades;
  late final double _subtotal;
  late final double _igv;
  late final double _total;

  String? _metodo;
  int _fase = 0; // 0 elegir, 1 procesando, 2 listo
  String _mensaje = '';
  Venta? _venta;

  static const _metodos = <_Metodo>[
    _Metodo('Efectivo', Icons.payments_outlined, 'EN CAJA', Color(0xFF43A047)),
    _Metodo('Yape', Icons.qr_code_2, 'ESCANEAR QR', Color(0xFFA23BC2)),
    _Metodo('Plin', Icons.qr_code_scanner, 'ESCANEAR QR', Color(0xFF00B4C8)),
    _Metodo('Tarjeta', Icons.credit_card, 'DEBITO / CREDITO', Color(0xFFFFC400)),
  ];

  @override
  void initState() {
    super.initState();
    final c = context.read<CarritoProvider>();
    _articulos = c.items.length;
    _unidades = c.items.fold<int>(0, (a, i) => a + i.cantidad);
    _subtotal = c.subtotal;
    _igv = _subtotal * AppConstants.igv;
    _total = _subtotal + _igv;
    CarritoFlotante.bloquear();
  }

  @override
  void dispose() {
    CarritoFlotante.desbloquear();
    super.dispose();
  }

  Future<void> _pagar() async {
    setState(() {
      _fase = 1;
      _mensaje = 'VALIDANDO PAGO';
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _mensaje = 'EMITIENDO COMPROBANTE');
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final carrito = context.read<CarritoProvider>();
    final venta = context.read<VentaProvider>().registrar(
          clienteNombre: widget.cliente?.nombre ?? 'Publico en general',
          items: carrito.aItemsVenta(),
          metodoPago: _metodo!,
          comprobante: widget.comprobante,
        );
    context.read<ProductoProvider>().descontarStock(
          carrito.items
              .map((i) => (productoId: i.producto.id, cantidad: i.cantidad))
              .toList(),
        );
    carrito.limpiar();

    setState(() {
      _venta = venta;
      _fase = 2;
    });
  }

  void _irA(int pestana) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    ShellNavegacion.irA(pestana);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;

    return Theme(
      data: _tema,
      child: PopScope(
        canPop: _fase != 1,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: _fase != 1,
            title: Text(_fase == 2 ? 'Pago completado' : 'Pagar'),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
                child: child,
              ),
            ),
            child: switch (_fase) {
              0 => _fase0(),
              1 => _Procesando(key: const ValueKey('p'), mensaje: _mensaje),
              _ => _Exito(
                  key: const ValueKey('e'),
                  venta: _venta!,
                  cliente: widget.cliente,
                  vendedor: usuario?.nombre.split(' ').first ?? 'Caja 01',
                  onNuevaVenta: () => _irA(1),
                  onHistorial: () => _irA(2),
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _fase0() {
    return ListView(
      key: const ValueKey('f0'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        // ------------------------------------------------- total
        FadeSlide(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const ShapeDecoration(
              color: AppTheme.superficieOscura,
              shape: BeveledRectangleBorder(
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(22)),
                side: BorderSide(color: AppTheme.bordeOscuro),
              ),
            ),
            child: Column(
              children: [
                const FranjaPeligro(alto: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Mono('TOTAL A PAGAR', Color(0x99EDE8DF)),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _total),
                              duration: const Duration(milliseconds: 1100),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  Formatters.soles(v),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Mono('$_unidades UND  /  $_articulos ART.',
                              AppTheme.hueso),
                          const SizedBox(height: 4),
                          _Mono(widget.comprobante.toUpperCase(),
                              AppTheme.amarilloSenal),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 26),
        const _Mono('¿CON QUE QUIERES PAGAR?', AppTheme.hueso, grande: true),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            for (var i = 0; i < _metodos.length; i++)
              FadeSlide(
                delay: Duration(milliseconds: 150 + i * 90),
                child: _TileMetodo(
                  metodo: _metodos[i],
                  activo: _metodo == _metodos[i].nombre,
                  onTap: () => setState(() => _metodo = _metodos[i].nombre),
                ),
              ),
          ],
        ),

        const SizedBox(height: 18),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: AnimatedBuilder(
                animation: anim,
                child: child,
                builder: (context, hijo) {
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX((1 - anim.value) * -0.5);
                  return Transform(
                    alignment: Alignment.topCenter,
                    transform: m,
                    child: hijo,
                  );
                },
              ),
            ),
            child: _panel(),
          ),
        ),
      ],
    );
  }

  Widget _panel() {
    switch (_metodo) {
      case 'Yape':
        return _PanelQr(
          key: const ValueKey('yape'),
          nombre: 'Yape',
          color: const Color(0xFFA23BC2),
          monto: _total,
          onConfirmar: _pagar,
        );
      case 'Plin':
        return _PanelQr(
          key: const ValueKey('plin'),
          nombre: 'Plin',
          color: const Color(0xFF00B4C8),
          monto: _total,
          onConfirmar: _pagar,
        );
      case 'Tarjeta':
        return _PanelTarjeta(
          key: const ValueKey('tarjeta'),
          monto: _total,
          onPagar: _pagar,
        );
      case 'Efectivo':
        return _PanelEfectivo(
          key: const ValueKey('efectivo'),
          total: _total,
          onPagar: _pagar,
        );
      default:
        return const Padding(
          key: ValueKey('nada'),
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: _Mono('ELIGE UN METODO PARA CONTINUAR', Color(0x99EDE8DF)),
          ),
        );
    }
  }
}

// ======================================================================
// Metodos
// ======================================================================

class _Metodo {
  final String nombre;
  final IconData icono;
  final String detalle;
  final Color color;

  const _Metodo(this.nombre, this.icono, this.detalle, this.color);
}

class _TileMetodo extends StatelessWidget {
  final _Metodo metodo;
  final bool activo;
  final VoidCallback onTap;

  const _TileMetodo({
    required this.metodo,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tilt3D(
      anguloMax: 0.16,
      radioBorde: 14,
      builder: (context, t) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: ShapeDecoration(
            color: activo
                ? metodo.color.withOpacity(0.16)
                : AppTheme.superficieOscura,
            shape: BeveledRectangleBorder(
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(16)),
              side: BorderSide(
                color: activo ? metodo.color : AppTheme.bordeOscuro,
                width: activo ? 2.2 : 1.2,
              ),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Transform.translate(
                    offset: Offset(t.dx * -5, t.dy * -5),
                    child: Icon(metodo.icono, color: metodo.color, size: 30),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metodo.nombre,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.hueso),
                      ),
                      _Mono(metodo.detalle, const Color(0x99EDE8DF)),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: AnimatedScale(
                  scale: activo ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: metodo.color, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        size: 15, color: AppTheme.grafito),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- QR

class _PanelQr extends StatefulWidget {
  final String nombre;
  final Color color;
  final double monto;
  final VoidCallback onConfirmar;

  const _PanelQr({
    super.key,
    required this.nombre,
    required this.color,
    required this.monto,
    required this.onConfirmar,
  });

  @override
  State<_PanelQr> createState() => _PanelQrState();
}

class _PanelQrState extends State<_PanelQr>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lado = 196.0;
    return _Caja(
      color: widget.color,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  widget.nombre[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paga con ${widget.nombre}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.hueso),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color, width: 3),
            ),
            child: SizedBox(
              width: lado,
              height: lado,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size.square(lado),
                    painter: QrIlustrativoPainter(
                      semilla:
                          '${widget.nombre}|${AppConstants.celularYapePlin}|${widget.monto}',
                      color: const Color(0xFF16181B),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Text(
                        widget.nombre[0],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20),
                      ),
                    ),
                  ),
                  // Linea de escaneo
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) => Align(
                        alignment: Alignment(
                            0, -1 + 2 * Curves.easeInOut.transform(_scan.value)),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: widget.color.withOpacity(0.8),
                                  blurRadius: 12,
                                  spreadRadius: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Mono('ESCANEA EL QR DESDE TU APP', Color(0x99EDE8DF)),
          const SizedBox(height: 6),
          Text(
            'o envia al ${AppConstants.celularYapePlin}',
            style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.hueso),
          ),
          const _Mono(AppConstants.titularYapePlin, Color(0x99EDE8DF)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const _Mono('MONTO EXACTO', Color(0x99EDE8DF)),
                Text(
                  Formatters.soles(widget.monto),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.hueso),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedButton(
            texto: 'Ya realice el pago',
            icono: Icons.check_circle_outline,
            ancho: double.infinity,
            onPressed: widget.onConfirmar,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ tarjeta

class _FormatoNumeroTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    final d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final corto = d.length > 16 ? d.substring(0, 16) : d;
    final b = StringBuffer();
    for (var i = 0; i < corto.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(corto[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _FormatoVence extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    final d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final corto = d.length > 4 ? d.substring(0, 4) : d;
    final t = corto.length > 2
        ? '${corto.substring(0, 2)}/${corto.substring(2)}'
        : corto;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _PanelTarjeta extends StatefulWidget {
  final double monto;
  final VoidCallback onPagar;

  const _PanelTarjeta({super.key, required this.monto, required this.onPagar});

  @override
  State<_PanelTarjeta> createState() => _PanelTarjetaState();
}

class _PanelTarjetaState extends State<_PanelTarjeta> {
  final _numero = TextEditingController();
  final _nombre = TextEditingController();
  final _vence = TextEditingController();
  final _cvv = TextEditingController();
  final _cvvFoco = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_numero, _nombre, _vence, _cvv]) {
      c.addListener(() => setState(() {}));
    }
    _cvvFoco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numero.dispose();
    _nombre.dispose();
    _vence.dispose();
    _cvv.dispose();
    _cvvFoco.dispose();
    super.dispose();
  }

  void _validar() {
    final digitos = _numero.text.replaceAll(' ', '');
    String? error;
    if (digitos.length != 16) {
      error = 'El numero de tarjeta debe tener 16 digitos';
    } else if (_nombre.text.trim().length < 3) {
      error = 'Escribe el nombre que aparece en la tarjeta';
    } else {
      final partes = _vence.text.split('/');
      final mes = partes.length == 2 ? int.tryParse(partes[0]) : null;
      final anio = partes.length == 2 ? int.tryParse(partes[1]) : null;
      final hoy = DateTime.now();
      if (mes == null || anio == null || mes < 1 || mes > 12) {
        error = 'Fecha de vencimiento invalida (MM/AA)';
      } else if (2000 + anio < hoy.year ||
          (2000 + anio == hoy.year && mes < hoy.month)) {
        error = 'La tarjeta esta vencida';
      } else if (_cvv.text.length != 3) {
        error = 'El CVV debe tener 3 digitos';
      }
    }
    setState(() => _error = error);
    if (error == null) widget.onPagar();
  }

  InputDecoration _deco(String etiqueta, IconData icono) => InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, size: 20),
        labelStyle: const TextStyle(
            fontFamily: 'monospace', fontSize: 12.5, letterSpacing: 1),
      );

  @override
  Widget build(BuildContext context) {
    return _Caja(
      color: AppTheme.amarilloSenal,
      child: Column(
        children: [
          _TarjetaVisual(
            numero: _numero.text,
            nombre: _nombre.text,
            vence: _vence.text,
            cvv: _cvv.text,
            reverso: _cvvFoco.hasFocus,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _numero,
            keyboardType: TextInputType.number,
            inputFormatters: [_FormatoNumeroTarjeta()],
            decoration: _deco('NUMERO DE TARJETA', Icons.credit_card),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.characters,
            decoration: _deco('NOMBRE EN LA TARJETA', Icons.person_outline),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vence,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_FormatoVence()],
                  decoration: _deco('VENCE MM/AA', Icons.event_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvv,
                  focusNode: _cvvFoco,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: _deco('CVV', Icons.lock_outline),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6E6E)),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          AnimatedButton(
            texto: 'Pagar ${Formatters.soles(widget.monto)}',
            icono: Icons.lock,
            ancho: double.infinity,
            onPressed: _validar,
          ),
          const SizedBox(height: 4),
          const _Mono('PAGO SIMULADO - NO SE GUARDAN DATOS', Color(0x80EDE8DF)),
        ],
      ),
    );
  }
}

/// Tarjeta que gira en 3D hacia su reverso cuando se escribe el CVV.
class _TarjetaVisual extends StatelessWidget {
  final String numero;
  final String nombre;
  final String vence;
  final String cvv;
  final bool reverso;

  const _TarjetaVisual({
    required this.numero,
    required this.nombre,
    required this.vence,
    required this.cvv,
    required this.reverso,
  });

  String get _numeroMostrado {
    final d = numero.replaceAll(' ', '');
    final rellena = d.padRight(16, '•');
    return [
      for (var i = 0; i < 16; i += 4) rellena.substring(i, i + 4),
    ].join('  ');
  }

  Widget _marca() {
    final d = numero.replaceAll(' ', '');
    if (d.startsWith('4')) {
      return const Text('VISA',
          style: TextStyle(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              color: Colors.white));
    }
    if (d.startsWith('5') || d.startsWith('2')) {
      return SizedBox(
        width: 44,
        height: 28,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFFE53935), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.9),
                    shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      );
    }
    return const Icon(Icons.contactless, color: Colors.white70, size: 28);
  }

  Widget _frente() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E353C), Color(0xFF14181B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF454E57)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                ),
              ),
              _marca(),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _numeroMostrado,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 21,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre.isEmpty ? 'NOMBRE APELLIDO' : nombre.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      letterSpacing: 1,
                      color: Colors.white70),
                ),
              ),
              Text(
                vence.isEmpty ? 'MM/AA' : vence,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reverso() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1B2024),
        border: Border.all(color: const Color(0xFF454E57)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 26),
          Container(height: 42, color: Colors.black),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    color: const Color(0xFFEDE8DF),
                  ),
                ),
                Container(
                  width: 62,
                  height: 36,
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: Text(
                    cvv.isEmpty ? '•••' : cvv.replaceAll(RegExp(r'.'), '•'),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Mono('CVV', Color(0x99EDE8DF)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: reverso ? math.pi : 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      builder: (context, a, _) {
        final atras = a > math.pi / 2;
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(a);
        return AspectRatio(
          aspectRatio: 1.62,
          child: Transform(
            alignment: Alignment.center,
            transform: m,
            child: atras
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _reverso(),
                  )
                : _frente(),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------- efectivo

class _PanelEfectivo extends StatefulWidget {
  final double total;
  final VoidCallback onPagar;

  const _PanelEfectivo({super.key, required this.total, required this.onPagar});

  @override
  State<_PanelEfectivo> createState() => _PanelEfectivoState();
}

class _PanelEfectivoState extends State<_PanelEfectivo> {
  final _recibido = TextEditingController();

  double get _monto => double.tryParse(_recibido.text.replaceAll(',', '.')) ?? 0;
  double get _vuelto => _monto - widget.total;
  bool get _alcanza => _monto + 0.0001 >= widget.total;

  @override
  void initState() {
    super.initState();
    _recibido.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recibido.dispose();
    super.dispose();
  }

  void _poner(double v) {
    _recibido.text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    _recibido.selection =
        TextSelection.collapsed(offset: _recibido.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final rapidos = <double>[
      for (final v in [50.0, 100.0, 200.0])
        if (v >= widget.total) v,
    ];

    return _Caja(
      color: const Color(0xFF43A047),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Mono('MONTO RECIBIDO', AppTheme.hueso, grande: true),
          const SizedBox(height: 10),
          TextField(
            controller: _recibido,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(
              prefixText: 'S/  ',
              hintText: '0.00',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipRapido('EXACTO', () => _poner(widget.total)),
              for (final v in rapidos)
                _ChipRapido('S/ ${v.toStringAsFixed(0)}', () => _poner(v)),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: (_alcanza ? const Color(0xFF43A047) : AppTheme.danger)
                  .withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _Mono(_alcanza ? 'VUELTO' : 'FALTAN',
                    const Color(0x99EDE8DF)),
                const SizedBox(height: 2),
                Text(
                  Formatters.soles(_monto == 0
                      ? widget.total
                      : _vuelto.abs()),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _monto == 0
                        ? const Color(0x66EDE8DF)
                        : (_alcanza
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFFF6E6E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedButton(
            texto: 'Cobrar ${Formatters.soles(widget.total)}',
            icono: Icons.payments_outlined,
            ancho: double.infinity,
            onPressed: _alcanza ? widget.onPagar : null,
          ),
        ],
      ),
    );
  }
}

class _ChipRapido extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _ChipRapido(this.texto, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.grafito,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.bordeOscuro),
        ),
        child: Text(
          texto,
          style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppTheme.hueso),
        ),
      ),
    );
  }
}

// ======================================================================
// Procesando y exito
// ======================================================================

class _Procesando extends StatefulWidget {
  final String mensaje;

  const _Procesando({super.key, required this.mensaje});

  @override
  State<_Procesando> createState() => _ProcesandoState();
}

class _ProcesandoState extends State<_Procesando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _giro;

  @override
  void initState() {
    super.initState();
    _giro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _giro,
            builder: (context, _) => Engranaje3D(
              size: 150,
              angulo: _giro.value * 2 * math.pi,
              inclX: 0.8,
              inclY: -0.3,
            ),
          ),
          const SizedBox(height: 30),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.mensaje,
              key: ValueKey(widget.mensaje),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Exito extends StatefulWidget {
  final Venta venta;
  final Cliente? cliente;
  final String vendedor;
  final VoidCallback onNuevaVenta;
  final VoidCallback onHistorial;

  const _Exito({
    super.key,
    required this.venta,
    required this.cliente,
    required this.vendedor,
    required this.onNuevaVenta,
    required this.onHistorial,
  });

  @override
  State<_Exito> createState() => _ExitoState();
}

class _ExitoState extends State<_Exito> with SingleTickerProviderStateMixin {
  late final AnimationController _confeti;
  late final List<_Particula> _particulas;

  @override
  void initState() {
    super.initState();
    final r = math.Random(11);
    const colores = [
      AppTheme.primary,
      AppTheme.amarilloSenal,
      AppTheme.hueso,
      Color(0xFF66BB6A),
    ];
    _particulas = List.generate(
      46,
      (_) => _Particula(
        x: r.nextDouble(),
        retardo: r.nextDouble() * 0.45,
        velocidad: 0.7 + r.nextDouble() * 0.8,
        ancho: 5 + r.nextDouble() * 6,
        giro: r.nextDouble() * 6,
        color: colores[r.nextInt(colores.length)],
      ),
    );
    _confeti = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..forward();
  }

  @override
  void dispose() {
    _confeti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, v, child) {
                  final m = Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY((1 - v) * 3.3);
                  return Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: Transform.scale(
                        scale: v.clamp(0.0, 1.2).toDouble(), child: child),
                  );
                },
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: const ShapeDecoration(
                    color: Color(0xFF43A047),
                    shape: BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(28)),
                    ),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 56),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlide(
              delay: const Duration(milliseconds: 300),
              child: const Text(
                'MUCHAS GRACIAS\nPOR SU COMPRA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppTheme.hueso,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeSlide(
              delay: const Duration(milliseconds: 450),
              child: const Text(
                'Aqui esta su comprobante.\nQue tenga un buen dia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, height: 1.45, color: Color(0xCCEDE8DF)),
              ),
            ),
            const SizedBox(height: 24),
            FadeSlide(
              delay: const Duration(milliseconds: 650),
              inicio: const Offset(0, 0.3),
              duracion: const Duration(milliseconds: 900),
              child: ComprobanteView(
                venta: widget.venta,
                cliente: widget.cliente,
                vendedor: widget.vendedor,
              ),
            ),
            const SizedBox(height: 26),
            FadeSlide(
              delay: const Duration(milliseconds: 1000),
              child: Column(
                children: [
                  AnimatedButton(
                    texto: 'Nueva venta',
                    icono: Icons.add_shopping_cart,
                    ancho: double.infinity,
                    onPressed: widget.onNuevaVenta,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onHistorial,
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: const Text('VER HISTORIAL'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confeti,
              builder: (context, _) => CustomPaint(
                painter: _ConfetiPainter(_particulas, _confeti.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particula {
  final double x;
  final double retardo;
  final double velocidad;
  final double ancho;
  final double giro;
  final Color color;

  const _Particula({
    required this.x,
    required this.retardo,
    required this.velocidad,
    required this.ancho,
    required this.giro,
    required this.color,
  });
}

class _ConfetiPainter extends CustomPainter {
  final List<_Particula> particulas;
  final double t;

  _ConfetiPainter(this.particulas, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particulas) {
      final u = ((t - p.retardo) / (1 - p.retardo)).clamp(0.0, 1.0).toDouble();
      if (u <= 0 || u >= 1) continue;
      final y = -20 + u * p.velocidad * (size.height + 40);
      final x = p.x * size.width + math.sin(u * 8 + p.giro) * 24;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(u * 9 + p.giro);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.ancho, height: p.ancho * 0.45),
        Paint()..color = p.color.withOpacity(1 - u * 0.6),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfetiPainter old) => old.t != t;
}

// ======================================================================
// Piezas comunes
// ======================================================================

class _Caja extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Caja({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: AppTheme.superficieOscura,
        shape: BeveledRectangleBorder(
          borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(24)),
          side: BorderSide(color: color.withOpacity(0.7), width: 1.6),
        ),
      ),
      child: child,
    );
  }
}

class _Mono extends StatelessWidget {
  final String texto;
  final Color color;
  final bool grande;

  const _Mono(this.texto, this.color, {this.grande = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: grande ? 13 : 10.5,
        letterSpacing: grande ? 2 : 1.6,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}
