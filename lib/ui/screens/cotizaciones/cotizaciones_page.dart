import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/cotizacion.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/cotizacion_provider.dart';
import '../../../services/cotizacion_pdf.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/cotizacion/contacto_cliente_sheet.dart';
import '../../widgets/cotizacion/dialogo_eliminar_cotizacion.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/appbar_taller.dart';
import 'cotizacion_documento_screen.dart';
import 'cotizacion_form_screen.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  final _busqueda = TextEditingController();
  final Set<String> _seleccion = {};
  bool _modoSeleccion = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Aceptada':
        return const Color(0xFF0277BD);
      case 'Pagada':
        return const Color(0xFF2E7D32);
      case 'Rechazada':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFFF9A825);
    }
  }

  /// Documento del cliente: el guardado en la cotizacion o, si es una
  /// cotizacion antigua, el del cliente con el mismo nombre.
  ({String tipo, String numero}) _documento(
      Cotizacion c, List<Cliente> clientes) {
    if (c.documento.isNotEmpty) {
      return (tipo: c.tipoDocumento, numero: c.documento);
    }
    for (final x in clientes) {
      if ((c.clienteId.isNotEmpty && x.id == c.clienteId) ||
          x.nombre.trim().toLowerCase() == c.clienteNombre.trim().toLowerCase()) {
        return (tipo: x.tipoDocumento, numero: x.documento);
      }
    }
    return (tipo: '', numero: '');
  }

  void _salirSeleccion() => setState(() {
        _seleccion.clear();
        _modoSeleccion = false;
      });

  void _alternar(String id) {
    setState(() {
      if (!_seleccion.add(id)) _seleccion.remove(id);
      if (_seleccion.isEmpty) _modoSeleccion = false;
    });
  }

  void _mantener(Cotizacion c) {
    final permisos = Permisos.leer(context);
    if (!permisos.puedeEliminarCotizaciones) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          backgroundColor: AppTheme.grafito,
          content: Text('Solo el administrador puede eliminar cotizaciones'),
        ));
      return;
    }
    if (!_modoSeleccion) {
      setState(() {
        _modoSeleccion = true;
        _seleccion.add(c.id);
      });
    } else {
      _alternar(c.id);
    }
  }

  Future<void> _eliminarSeleccion() async {
    final cantidad = _seleccion.length;
    final provider = context.read<CotizacionProvider>();
    final ok = await DialogoEliminarCotizacion.mostrar(context, cantidad: cantidad);
    if (!ok || !mounted) return;
    provider.eliminarVarias(_seleccion);
    _salirSeleccion();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppTheme.grafito,
        content: Text(cantidad == 1
            ? 'Cotización eliminada'
            : '$cantidad cotizaciones eliminadas'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CotizacionProvider>();
    final clientes = context.watch<ClienteProvider>().clientes;
    final texto = _busqueda.text.trim().toLowerCase();

    final lista = provider.cotizaciones.where((c) {
      if (texto.isEmpty) return true;
      final doc = _documento(c, clientes).numero;
      return doc.contains(texto) || c.clienteNombre.toLowerCase().contains(texto);
    }).toList();

    return PopScope(
      canPop: !_modoSeleccion,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _modoSeleccion) _salirSeleccion();
      },
      child: Scaffold(
        appBar: AppBarTaller(
          mostrarCarrito: !_modoSeleccion,
          subtitulo: _modoSeleccion ? 'Modo selección' : 'Presupuestos',
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              _modoSeleccion
                  ? '${_seleccion.length} seleccionada${_seleccion.length == 1 ? '' : 's'}'
                  : 'Cotizaciones',
              key: ValueKey(_modoSeleccion ? _seleccion.length : -1),
            ),
          ),
          actions: _modoSeleccion
              ? [
                  IconButton(
                    tooltip: 'Seleccionar todas',
                    icon: const Icon(Icons.select_all),
                    onPressed: () => setState(() {
                      _seleccion
                        ..clear()
                        ..addAll(lista.map((c) => c.id));
                    }),
                  ),
                  IconButton(
                    tooltip: 'Cancelar',
                    icon: const Icon(Icons.close),
                    onPressed: _salirSeleccion,
                  ),
                ]
              : null,
        ),
        floatingActionButton: _modoSeleccion
            ? null
            : FloatingActionButton.extended(
                onPressed: () => AppRoutes.push(context, const CotizacionFormScreen()),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Nueva'),
              ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (w, a) => SizeTransition(
            sizeFactor: a,
            axisAlignment: -1,
            child: FadeTransition(opacity: a, child: w),
          ),
          child: _modoSeleccion
              ? Container(
                  key: const ValueKey('barra'),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: const Border(
                        top: BorderSide(color: AppTheme.danger, width: 2)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _seleccion.isEmpty ? null : _eliminarSeleccion,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('ELIMINAR (${_seleccion.length})'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('sin-barra')),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _busqueda,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por DNI o RUC del cliente...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busqueda.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _busqueda.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: provider.cotizaciones.isEmpty
                  ? EmptyState(
                      icono: Icons.request_quote_outlined,
                      titulo: 'Sin cotizaciones',
                      mensaje: 'Crea cotizaciones para tus clientes con precios '
                          'especiales y validez limitada.',
                      textoBoton: 'Crear cotización',
                      onAccion: () =>
                          AppRoutes.push(context, const CotizacionFormScreen()),
                    )
                  : lista.isEmpty
                      ? const EmptyState(
                          icono: Icons.search_off,
                          titulo: 'Sin resultados',
                          mensaje: 'Ninguna cotización coincide con ese DNI o RUC.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final c = lista[i];
                            final doc = _documento(c, clientes);
                            return FadeSlide(
                              key: ValueKey(c.id),
                              delay: Duration(milliseconds: i < 8 ? i * 60 : 0),
                              child: _TarjetaCotizacion(
                                cotizacion: c,
                                tipoDoc: doc.tipo,
                                documento: doc.numero,
                                colorEstado: _colorEstado(c.estado),
                                seleccionando: _modoSeleccion,
                                seleccionada: _seleccion.contains(c.id),
                                onTap: () => _modoSeleccion
                                    ? _alternar(c.id)
                                    : AppRoutes.push(context,
                                        CotizacionDocumentoScreen(cotizacionId: c.id)),
                                onLongPress: () => _mantener(c),
                                onContactar: () => ContactoClienteSheet.mostrar(context, c),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCotizacion extends StatelessWidget {
  final Cotizacion cotizacion;
  final String tipoDoc;
  final String documento;
  final Color colorEstado;
  final bool seleccionando;
  final bool seleccionada;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onContactar;

  const _TarjetaCotizacion({
    required this.cotizacion,
    required this.tipoDoc,
    required this.documento,
    required this.colorEstado,
    required this.seleccionando,
    required this.seleccionada,
    required this.onTap,
    required this.onLongPress,
    required this.onContactar,
  });

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;
    final gris = Colors.grey.shade600;

    return Row(
      children: [
        // Casilla que aparece animada al entrar en modo seleccion.
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: seleccionando
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Checkbox(
                    value: seleccionada,
                    shape: const CircleBorder(),
                    activeColor: AppTheme.primary,
                    onChanged: (_) => onTap(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: seleccionada ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: colorEstado.withOpacity(0.12),
                            child: Icon(Icons.request_quote, color: colorEstado),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.clienteNombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    documento.isEmpty
                                        ? 'SIN DNI / RUC'
                                        : '${tipoDoc.isEmpty ? 'DOC' : tipoDoc}  $documento',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFD95800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              c.estado == 'Aceptada' ? 'Aprobada' : c.estado,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorEstado),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${CotizacionPdf.numero(c)}  |  ${Formatters.fechaCorta(c.fecha)}  |  '
                        'Vence ${Formatters.fechaCorta(c.fechaVencimiento)}  |  '
                        '${c.items.length} productos',
                        style: TextStyle(fontSize: 12, color: gris),
                      ),
                      if (c.vencida)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('VENCIDA',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: AppTheme.danger)),
                        ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Text(
                            Formatters.soles(c.total),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: onContactar,
                            icon: const Icon(Icons.contact_phone_outlined, size: 17),
                            label: const Text('Contactar'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppTheme.primary,
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Spacer(),
                          Text('VER DOCUMENTO',
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                  color: gris)),
                          Icon(Icons.chevron_right, size: 20, color: gris),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
