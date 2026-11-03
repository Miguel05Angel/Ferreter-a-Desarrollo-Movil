import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/asistente_tareas.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/producto.dart';
import '../../../providers/carrito_provider.dart';
import '../../../providers/cotizacion_borrador_provider.dart';
import '../../../providers/producto_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/buttons/animated_button.dart';
import '../../widgets/media/producto_imagen.dart';
import '../../widgets/visual/decor_industrial.dart';
import '../../widgets/visual/escala_grises.dart';
import '../cotizaciones/cotizacion_form_screen.dart';

/// Pantalla inicial despues de iniciar sesion: asistente que entiende la
/// tarea del usuario y arma la lista de herramientas y productos.
/// Solo recomienda productos con precio verificado en tiendas reales.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _tarea = TextEditingController();
  PlanTarea? _plan;
  bool _noEntendido = false;
  int _version = 0;
  bool _seleccionando = false;
  final Set<String> _marcados = {};
  final Map<String, int> _sumados = {}; // productos sumados con el "+"

  @override
  void dispose() {
    _tarea.dispose();
    super.dispose();
  }

  void _recomendar([String? texto]) {
    if (texto != null) _tarea.text = texto;
    FocusScope.of(context).unfocus();
    final catalogo = context.read<ProductoProvider>().productos;
    final tarea = AsistenteTareas.entender(_tarea.text);
    setState(() {
      _version++;
      _seleccionando = false;
      _marcados.clear();
      _sumados.clear();
      if (tarea != null) {
        _noEntendido = false;
        _plan = AsistenteTareas.armar(tarea, catalogo);
      } else {
        // No hay una tarea conocida: se interpretan las palabras y se
        // buscan los productos del catalogo que encajan con lo escrito.
        final libre = AsistenteTareas.armarLibre(_tarea.text, catalogo);
        _plan = libre;
        _noEntendido = libre == null && _tarea.text.trim().isNotEmpty;
      }
    });
  }

  /// Devuelve true si se agrego. El boton "+" confirma con su animacion;
  /// solo se muestra mensaje cuando hay un problema (por ejemplo, stock).
  bool _agregar(Producto p) {
    final error = context.read<CarritoProvider>().agregar(p, 1);
    if (error != null) {
      final mensajes = ScaffoldMessenger.of(context);
      mensajes.hideCurrentSnackBar();
      mensajes.showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text(error),
        duration: const Duration(seconds: 2),
      ));
    }
    if (error == null) {
      setState(() => _sumados[p.id] = (_sumados[p.id] ?? 0) + 1);
    }
    return error == null;
  }

  /// Todos los productos sugeridos (la mejor opcion de cada necesidad).
  List<Producto> _sugeridos(PlanTarea plan) =>
      [for (final p in plan.pasos) if (p.principal != null) p.principal!];

  /// Productos con casilla marcada, tomados de todas las opciones mostradas.
  List<Producto> _seleccionados(PlanTarea plan) => [
        for (final paso in plan.pasos)
          for (final o in paso.opciones)
            if (_marcados.contains(o.id)) o,
      ];

  void _elegirManualmente(PlanTarea plan) {
    setState(() {
      _marcados.clear();
      _seleccionando = true;
    });
  }

  /// Total de lo que el usuario realmente eligio (casillas o "+"). Empieza
  /// en S/ 0.00 y sube a medida que selecciona.
  double _totalElegido(PlanTarea plan) {
    var total = 0.0;
    for (final paso in plan.pasos) {
      for (final o in paso.opciones) {
        var cant = _sumados[o.id] ?? 0;
        if (cant == 0 && _marcados.contains(o.id)) cant = 1;
        total += cant * o.precioVenta;
      }
    }
    return total;
  }

  void _marcar(Producto p) => setState(() {
        if (!_marcados.add(p.id)) _marcados.remove(p.id);
      });

  /// Pasa los productos al listado de cotizacion (no al carrito de compras)
  /// y abre el borrador para revisarlo.
  void _agregarACotizacion(List<Producto> productos) {
    if (productos.isEmpty) return;
    final borrador = context.read<CotizacionBorradorProvider>();
    for (final p in productos) {
      borrador.agregar(p, 1);
    }
    setState(() {
      _seleccionando = false;
      _marcados.clear();
    });
    AppRoutes.push(context, const CotizacionFormScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grafito,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: PlanoPainter())),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                    child: IconButton(
                      tooltip: 'Volver',
                      icon: const Icon(Icons.arrow_back, color: AppTheme.hueso),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FadeSlide(child: _Cabecera()),
                          const SizedBox(height: 22),
                          FadeSlide(
                            delay: const Duration(milliseconds: 120),
                            child: _CajaTarea(
                              controlador: _tarea,
                              onEnviar: _recomendar,
                              onCambio: () => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: AnimatedButton(
                                texto: 'Recomiéndame',
                                icono: Icons.auto_awesome,
                                ancho: double.infinity,
                                onPressed: _tarea.text.trim().isEmpty
                                    ? null
                                    : _recomendar,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: KeyedSubtree(
                              key: ValueKey(_version),
                              child: _resultado(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultado() {
    if (_noEntendido) {
      return const _Aviso(
        icono: Icons.help_outline,
        titulo: 'No encontre productos para eso',
        texto: 'Cuentame con mas detalle que quieres hacer o que necesitas '
            'arreglar, y buscare lo adecuado en el catalogo.',
      );
    }
    final plan = _plan;
    if (plan == null) return const SizedBox.shrink();

    final conProducto = plan.pasos.where((p) => p.principal != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.tarea.titulo.toUpperCase(),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary)),
              const SizedBox(height: 6),
              Text(plan.tarea.resumen,
                  style: const TextStyle(
                      color: AppTheme.hueso, height: 1.4, fontSize: 13.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Guía rápida de materiales y herramientas sugeridas:',
            style: TextStyle(
                color: AppTheme.hueso, fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (var i = 0; i < plan.pasos.length; i++)
          FadeSlide(
            delay: Duration(milliseconds: 80 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaPaso(
                paso: plan.pasos[i],
                onAgregar: _agregar,
                seleccionando: _seleccionando,
                marcados: _marcados,
                onMarcar: _marcar,
              ),
            ),
          ),
        if (conProducto > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL ESTIMADO',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 1.4,
                      color: Color(0x99EDE8DF))),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _totalElegido(plan)),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: v <= 0
                        ? const Color(0x55EDE8DF)
                        : AppTheme.primary,
                  ),
                  child: Text(Formatters.soles(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
              child: _seleccionando
                  ? Column(
                      key: const ValueKey('seleccion'),
                      children: [
                        AnimatedButton(
                          texto:
                              'Agregar seleccionados (${_marcados.length}) a la cotización',
                          icono: Icons.request_quote_outlined,
                          ancho: double.infinity,
                          onPressed: _marcados.isEmpty
                              ? null
                              : () => _agregarACotizacion(_seleccionados(plan)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _seleccionando = false;
                            _marcados.clear();
                          }),
                          child: const Text('Cancelar selección',
                              style: TextStyle(color: AppTheme.hueso)),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('normal'),
                      children: [
                        AnimatedButton(
                          texto: 'Agregar todo a la cotización',
                          icono: Icons.request_quote_outlined,
                          ancho: double.infinity,
                          onPressed: () => _agregarACotizacion(_sugeridos(plan)),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _elegirManualmente(plan),
                            icon: const Icon(Icons.checklist_rtl),
                            label: const Text('Elegir productos manualmente'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.hueso,
                              side: const BorderSide(color: AppTheme.primary, width: 1.6),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Se sugieren los productos con mejor relación calidad-precio disponibles en '
          'inventario. Confirma disponibilidad y precio final en tu tienda de Huancayo.',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0x80EDE8DF)),
        ),
      ],
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: ColoredBox(color: AppTheme.primary),
            ),
            SizedBox(width: 10),
            Text('EL CONSTRUCTOR',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 3,
                    color: Color(0xB3EDE8DF))),
          ],
        ),
        const SizedBox(height: 26),
        const Text('Asistente ferretero',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.05,
                color: AppTheme.hueso)),
        const SizedBox(height: 8),
        const Text('¿Qué proyecto o tarea deseas realizar hoy?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppTheme.primary)),
      ],
    );
  }
}

class _CajaTarea extends StatelessWidget {
  final TextEditingController controlador;
  final VoidCallback onEnviar;
  final VoidCallback onCambio;

  const _CajaTarea({
    required this.controlador,
    required this.onEnviar,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFF1D2226),
        shape: BeveledRectangleBorder(
          borderRadius:
              const BorderRadius.only(bottomRight: Radius.circular(18)),
          side: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        shadows: [
          BoxShadow(
              color: AppTheme.primary.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: controlador,
        minLines: 2,
        maxLines: 3,
        maxLength: 140,
        textInputAction: TextInputAction.done,
        onChanged: (_) => onCambio(),
        onSubmitted: (_) => onEnviar(),
        cursorColor: AppTheme.primary,
        style: const TextStyle(
            color: AppTheme.hueso, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          hintText: 'Cuéntame qué proyecto harás (ej: "Instalación de lavadero" o "Pintar una sala de 4x4")',
          hintStyle: TextStyle(color: Color(0xFF9AA2A9), fontSize: 14.5),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 12, right: 4, bottom: 28),
            child: Icon(Icons.edit_note, color: AppTheme.primary, size: 28),
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  const _Aviso({required this.icono, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppTheme.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: AppTheme.hueso,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(texto,
                    style: const TextStyle(
                        color: Color(0xB3EDE8DF), height: 1.4, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  final PasoRecomendado paso;
  final bool Function(Producto) onAgregar;
  final bool seleccionando;
  final Set<String> marcados;
  final void Function(Producto) onMarcar;
  const _TarjetaPaso({
    required this.paso,
    required this.onAgregar,
    required this.seleccionando,
    required this.marcados,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final n = paso.necesidad;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2226),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bordeOscuro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(n.etiqueta,
                    style: const TextStyle(
                        color: AppTheme.hueso,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5)),
              ),
              if (n.opcional)
                const Text('OPCIONAL',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: Color(0x99EDE8DF))),
            ],
          ),
          const SizedBox(height: 4),
          Text(n.consejo,
              style: const TextStyle(
                  color: Color(0xB3EDE8DF), fontSize: 12.5, height: 1.35)),
          const SizedBox(height: 10),
          if (paso.opciones.isNotEmpty)
            for (var i = 0; i < paso.opciones.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: _FilaProducto(
                  producto: paso.opciones[i],
                  etiqueta: i == 0
                      ? (paso.opciones[i].calidad > 0
                          ? 'MEJOR PRECIO-CALIDAD'
                          : 'MAS ECONOMICA VERIFICADA')
                      : 'ALTERNATIVA MAS ECONOMICA',
                  motivo: paso.motivo(i),
                  destacada: i == 0,
                  onAgregar: () => onAgregar(paso.opciones[i]),
                  seleccionando: seleccionando,
                  marcado: marcados.contains(paso.opciones[i].id),
                  onMarcar: () => onMarcar(paso.opciones[i]),
                ),
              )
          else if (paso.noDisponibles.isNotEmpty)
            for (var i = 0; i < paso.noDisponibles.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: _FilaNoDisponible(producto: paso.noDisponibles[i]),
              )
          else
            _FilaAusente(nombre: n.etiqueta),
        ],
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  final Producto producto;
  final String etiqueta;
  final String motivo;
  final bool destacada;
  final bool Function() onAgregar;
  final bool seleccionando;
  final bool marcado;
  final VoidCallback onMarcar;

  const _FilaProducto({
    required this.producto,
    required this.etiqueta,
    required this.motivo,
    required this.destacada,
    required this.onAgregar,
    required this.seleccionando,
    required this.marcado,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final color = destacada ? AppTheme.primary : const Color(0xFF8D979E);
    final fila = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: ProductoImagen(producto: producto, size: 46)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w900,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.hueso,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          height: 1.15)),
                  const SizedBox(height: 2),
                  Text(
                    producto.precioVerificado
                        ? '${producto.marca}  ·  Precio verificado'
                        : producto.marca,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0x99EDE8DF)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.soles(producto.precioVenta),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary)),
                const SizedBox(height: 6),
                _BotonSuma(onAgregar: onAgregar),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(motivo,
              style: const TextStyle(
                  color: Color(0xCCEDE8DF), fontSize: 11.8, height: 1.35)),
        ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: seleccionando
              ? Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Checkbox(
                    value: marcado,
                    activeColor: AppTheme.primary,
                    checkColor: AppTheme.grafito,
                    side: const BorderSide(color: AppTheme.hueso, width: 1.6),
                    shape: const CircleBorder(),
                    onChanged: (_) => onMarcar(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: fila),
      ],
    );
  }
}

/// Boton "+" : rebota y se transforma en un check verde para confirmar que
/// el producto se sumo; luego vuelve a ser "+".
class _BotonSuma extends StatefulWidget {
  final bool Function() onAgregar;
  const _BotonSuma({required this.onAgregar});

  @override
  State<_BotonSuma> createState() => _BotonSumaState();
}

class _BotonSumaState extends State<_BotonSuma>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 18),
    TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 32),
    TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50),
  ]).animate(_c);
  bool _ok = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tocar() {
    final agregado = widget.onAgregar();
    if (!agregado) return;
    setState(() => _ok = true);
    _c.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _ok = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.scale(scale: _escala.value, child: child),
      child: Tooltip(
        message: 'Sumar',
        child: Material(
          color: _ok ? AppTheme.success : AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _tocar,
            child: SizedBox(
              width: 38,
              height: 38,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (w, a) => RotationTransition(
                  turns: Tween(begin: 0.5, end: 1.0).animate(a),
                  child: ScaleTransition(scale: a, child: w),
                ),
                child: Icon(
                  _ok ? Icons.check : Icons.add,
                  key: ValueKey(_ok),
                  size: 24,
                  color: _ok ? Colors.white : AppTheme.grafito,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Producto real del catalogo que NO se puede recomendar ahora. Si esta
/// agotado la tarjeta pasa a gris plomo con "SIN STOCK" en rojo sobre la
/// imagen; si solo falta confirmar el precio se avisa claramente.
class _FilaNoDisponible extends StatelessWidget {
  final Producto producto;
  const _FilaNoDisponible({required this.producto});

  @override
  Widget build(BuildContext context) {
    final agotado = producto.agotado;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: agotado ? const Color(0xFF4A5056) : const Color(0xFF262C31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: agotado ? const Color(0xFF6A727A) : AppTheme.bordeOscuro),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  EscalaGrises(
                    activo: agotado,
                    child: ProductoImagen(producto: producto, size: 52),
                  ),
                  if (agotado)
                    Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xE6FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.danger, width: 1.5),
                        ),
                        child: const Text('SIN STOCK',
                            style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 9.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.hueso,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          height: 1.15)),
                  const SizedBox(height: 2),
                  Text(producto.marca,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Color(0x99EDE8DF))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                          agotado
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.info_outline,
                          size: 15,
                          color: agotado
                              ? const Color(0xFFFF8A80)
                              : AppTheme.amarilloSenal),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Stock bajo pedido — Consultar disponibilidad con almacén',
                          style: TextStyle(
                              color: agotado
                                  ? const Color(0xFFFF8A80)
                                  : AppTheme.amarilloSenal,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ningun producto del catalogo cubre esta necesidad: se avisa con el nombre
/// de lo que se necesita.
class _FilaAusente extends StatelessWidget {
  final String nombre;
  const _FilaAusente({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5056),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A727A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: Color(0xFFFF8A80), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: nombre,
                      style: const TextStyle(
                          color: AppTheme.hueso, fontWeight: FontWeight.w900)),
                  const TextSpan(
                      text: ': stock bajo pedido — consultar disponibilidad con almacén.',
                      style: TextStyle(
                          color: Color(0xFFFF8A80), fontWeight: FontWeight.w700)),
                ],
              ),
              style: const TextStyle(fontSize: 12.8, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
