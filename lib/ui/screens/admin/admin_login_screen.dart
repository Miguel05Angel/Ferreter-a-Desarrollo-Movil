import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// Acceso al panel web con el mismo DNI y contraseña que la app del teléfono.
///
/// Reusa AuthProvider.iniciarSesion(), que ya traduce el DNI al correo
/// interno y comprueba el perfil en la coleccion usuarios.
///
/// Validaciones:
///  - DNI: solo dígitos, exactamente 8.
///  - Contraseña: obligatoria, mínimo 6 caracteres (mínimo de Firebase Auth).
///  - Tras 5 intentos fallidos el botón se bloquea 30 segundos.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  static const _naranja = Color(0xFFF57C00);
  static const _naranjaClaro = Color(0xFFFFA726);
  static const _maxIntentos = 5;
  static const _segundosBloqueo = 30;

  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _password = TextEditingController();
  final _passwordFoco = FocusNode();

  late final AnimationController _fondo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final AnimationController _sacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  Timer? _timer;
  bool _cargando = false;
  bool _verPassword = false;
  String? _error;
  int _intentos = 0;
  int _bloqueoSeg = 0;

  bool get _bloqueado => _bloqueoSeg > 0;

  @override
  void initState() {
    super.initState();
    _entrada.forward();
    _dni.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fondo.dispose();
    _pulso.dispose();
    _sacudida.dispose();
    _entrada.dispose();
    _dni.dispose();
    _password.dispose();
    _passwordFoco.dispose();
    super.dispose();
  }

  void _iniciarBloqueo() {
    _bloqueoSeg = _segundosBloqueo;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _bloqueoSeg--;
        if (_bloqueoSeg <= 0) {
          t.cancel();
          _intentos = 0;
          _error = null;
        }
      });
    });
  }

  void _fallo(String mensaje) {
    HapticFeedback.mediumImpact();
    _sacudida.forward(from: 0);
    setState(() {
      _error = mensaje;
      _intentos++;
      if (_intentos >= _maxIntentos) _iniciarBloqueo();
    });
  }

  Future<void> _entrar() async {
    if (_cargando || _bloqueado) return;
    if (!(_form.currentState?.validate() ?? false)) {
      HapticFeedback.selectionClick();
      _sacudida.forward(from: 0);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().iniciarSesion(
            _dni.text.trim(),
            _password.text,
          );
      // Si sale bien no hace falta navegar: _PuertaAdmin escucha el provider
      // y cambia sola a la pantalla del panel.
      _intentos = 0;
    } on AuthError catch (e) {
      if (!mounted) return;
      _fallo(e.mensaje);
    } catch (e) {
      if (!mounted) return;
      _fallo('No se pudo entrar. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ---------------------------------------------------------------------
  // Utilidades de estilo
  // ---------------------------------------------------------------------

  bool get _oscuro => Theme.of(context).brightness == Brightness.dark;
  Color get _superficie => _oscuro ? const Color(0xFF151E2E) : Colors.white;
  Color get _texto => _oscuro ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
  Color get _suave => _oscuro ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _relleno =>
      _oscuro ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  OutlineInputBorder _borde(Color color, [double ancho = 1.2]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }

  InputDecoration _decoracion({
    required String etiqueta,
    required IconData icono,
    Widget? sufijo,
  }) {
    final borde = _oscuro ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: TextStyle(color: _suave),
      prefixIcon: Icon(icono, color: _suave),
      suffixIcon: sufijo,
      filled: true,
      fillColor: _relleno,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: _borde(borde),
      enabledBorder: _borde(borde),
      focusedBorder: _borde(_naranja, 2),
      errorBorder: _borde(const Color(0xFFDC2626)),
      focusedErrorBorder: _borde(const Color(0xFFDC2626), 2),
    );
  }

  /// Aparición escalonada ligada al controlador de entrada.
  Widget _escalonado(int indice, Widget hijo) {
    final inicio = math.min(0.08 * indice, 0.55);
    final fin = math.min(inicio + 0.45, 1.0);
    final curva = Interval(inicio, fin, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _entrada,
      child: hijo,
      builder: (context, child) {
        final v = curva.transform(_entrada.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Construcción
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          Positioned.fill(child: _FondoAnimado(animacion: _fondo)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, caja) {
                final ancho = caja.maxWidth >= 920;
                final tarjeta = _tarjeta();
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ancho ? 1020 : 440),
                      child: ancho
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _promocional()),
                                const SizedBox(width: 56),
                                SizedBox(width: 430, child: tarjeta),
                              ],
                            )
                          : tarjeta,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _promocional() {
    Widget punto(IconData icono, String titulo, String detalle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icono, color: _naranjaClaro, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _escalonado(
          0,
          const Text(
            'EL CONSTRUCTOR',
            style: TextStyle(
              color: _naranjaClaro,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _escalonado(
          1,
          const Text(
            'Tu ferretería,\ncontrolada desde\ncualquier lugar.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 42,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _escalonado(
          2,
          const Text(
            'Gestiona el catálogo, revisa las ventas y vigila el stock en '
            'tiempo real. Todo se sincroniza con la app de los teléfonos.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _escalonado(
          3,
          punto(Icons.inventory_2_outlined, 'Inventario en vivo',
              'Productos, precios y alertas de stock bajo al instante.'),
        ),
        _escalonado(
          4,
          punto(Icons.insights_outlined, 'Ventas y reportes',
              'Resumen diario, gráficos y detalle de cada comprobante.'),
        ),
        _escalonado(
          5,
          punto(Icons.sync_alt_rounded, 'Siempre sincronizado',
              'Lo que cambias aquí se ve en el teléfono, y al revés.'),
        ),
      ],
    );
  }

  Widget _tarjeta() {
    final restantes = _maxIntentos - _intentos;

    final contenido = Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.07).animate(
                CurvedAnimation(parent: _pulso, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_naranjaClaro, _naranja],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _naranja.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.handyman_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bienvenido de nuevo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _texto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa con tu DNI para abrir el panel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: _suave),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _dni,
            enabled: !_cargando,
            style: TextStyle(color: _texto, fontWeight: FontWeight.w600),
            decoration: _decoracion(
              etiqueta: 'DNI',
              icono: Icons.badge_outlined,
              sufijo: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _dni.text.length == 8
                    ? const Icon(Icons.check_circle,
                        key: ValueKey('ok'), color: Color(0xFF16A34A))
                    : Text(
                        '${_dni.text.length}/8',
                        key: const ValueKey('contador'),
                        style: TextStyle(color: _suave, fontSize: 12),
                      ),
              ),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            autofillHints: const [AutofillHints.username],
            onFieldSubmitted: (_) => _passwordFoco.requestFocus(),
            validator: (v) {
              final dni = (v ?? '').trim();
              if (dni.isEmpty) return 'Escribe tu DNI';
              if (dni.length != 8) return 'El DNI tiene 8 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            focusNode: _passwordFoco,
            enabled: !_cargando,
            style: TextStyle(color: _texto, fontWeight: FontWeight.w600),
            decoration: _decoracion(
              etiqueta: 'Contraseña',
              icono: Icons.lock_outline_rounded,
              sufijo: IconButton(
                tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey(_verPassword),
                    color: _suave,
                  ),
                ),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            obscureText: !_verPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _entrar(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Escribe tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _error == null
                  ? const SizedBox(width: double.infinity, key: ValueKey('sin'))
                  : Container(
                      key: ValueKey(_error),
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 19, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                if (!_bloqueado && _intentos >= 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      restantes == 1
                                          ? 'Te queda 1 intento antes del bloqueo temporal.'
                                          : 'Te quedan $restantes intentos antes del bloqueo temporal.',
                                      style: TextStyle(
                                          color: _suave, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _botonEntrar(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 15, color: _suave),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Solo cuentas con rol Administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _suave),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final tarjeta = Container(
      padding: const EdgeInsets.fromLTRB(32, 34, 32, 26),
      decoration: BoxDecoration(
        color: _superficie,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _oscuro ? const Color(0xFF243044) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: contenido),
    );

    // Entrada con escala + sacudida cuando hay un error.
    return AnimatedBuilder(
      animation: Listenable.merge([_entrada, _sacudida]),
      child: tarjeta,
      builder: (context, child) {
        final v = Curves.easeOutBack
            .transform(Interval(0.05, 0.75).transform(_entrada.value));
        final s = _sacudida.value;
        final dx = math.sin(s * math.pi * 7) * 11 * (1 - s);
        return Opacity(
          opacity: Interval(0.05, 0.5).transform(_entrada.value),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
          ),
        );
      },
    );
  }

  Widget _botonEntrar() {
    final habilitado = !_cargando && !_bloqueado;
    final Widget contenido;
    if (_cargando) {
      contenido = const SizedBox(
        key: ValueKey('cargando'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
    } else if (_bloqueado) {
      contenido = Row(
        key: const ValueKey('bloqueado'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Reintenta en ${_bloqueoSeg}s',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      );
    } else {
      contenido = const Row(
        key: ValueKey('normal'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Entrar al panel',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: habilitado || _cargando
              ? const [_naranjaClaro, _naranja]
              : const [Color(0xFF94A3B8), Color(0xFF64748B)],
        ),
        boxShadow: habilitado
            ? [
                BoxShadow(
                  color: _naranja.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: habilitado ? _entrar : null,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: contenido,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FONDO ANIMADO
// ---------------------------------------------------------------------------

class _FondoAnimado extends StatelessWidget {
  const _FondoAnimado({required this.animacion});

  final Animation<double> animacion;

  static const _iconos = [
    Icons.hardware,
    Icons.build_circle_outlined,
    Icons.handyman_outlined,
    Icons.construction,
    Icons.plumbing,
    Icons.electrical_services,
  ];
  static const _x = [-0.88, 0.78, -0.62, 0.92, 0.12, -0.25];
  static const _y = [-0.82, -0.62, 0.72, 0.58, -0.92, 0.92];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, _) {
        final t = animacion.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 0.4 * math.sin(t), -1),
              end: Alignment(1, 1 + 0.4 * math.cos(t)),
              colors: const [
                Color(0xFF0B1220),
                Color(0xFF15203A),
                Color(0xFF3B1D08),
              ],
            ),
          ),
          child: Stack(
            children: [
              _burbuja(t, 0.0, 420, 0.9),
              _burbuja(t, 2.1, 300, 0.7),
              _burbuja(t, 4.2, 220, 0.6),
              for (var i = 0; i < _iconos.length; i++)
                Align(
                  alignment: Alignment(
                    _x[i] + 0.04 * math.sin(t * 2 + i),
                    _y[i] + 0.04 * math.cos(t * 2 + i),
                  ),
                  child: Opacity(
                    opacity: 0.07,
                    child: Transform.rotate(
                      angle: 0.35 * math.sin(t + i),
                      child: Icon(_iconos[i], size: 58, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _burbuja(double t, double fase, double tam, double radio) {
    return Align(
      alignment: Alignment(
        radio * math.sin(t + fase),
        radio * math.cos(t * 0.8 + fase),
      ),
      child: Container(
        width: tam,
        height: tam,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF57C00).withOpacity(0.28),
              const Color(0xFFF57C00).withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}
