import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/permisos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/cliente_provider.dart';
import '../../widgets/animations/fade_slide.dart';
import '../../widgets/feedback/confirm_dialog.dart';
import '../../widgets/feedback/empty_state.dart';
import '../../widgets/layout/appbar_taller.dart';
import '../../widgets/visual/tilt_3d.dart';
import '../mapa/mapa_screen.dart';
import 'cliente_form_screen.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _busquedaController = TextEditingController();
  String _filtro = 'Todos';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  bool _cumple(Cliente c) {
    switch (_filtro) {
      case 'Con credito':
        return c.credito;
      case 'Empresas':
        return c.tipoDocumento == 'RUC';
      case 'Personas':
        return c.tipoDocumento == 'DNI';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClienteProvider>();
    final puedeEliminar = Permisos.de(context).puedeEliminarClientes;
    final texto = _busquedaController.text.trim().toLowerCase();
    final todos = provider.clientes;
    final filtrados = todos.where((c) {
      final coincide = texto.isEmpty ||
          c.nombre.toLowerCase().contains(texto) ||
          c.documento.contains(texto) ||
          c.telefono.contains(texto);
      return coincide && _cumple(c);
    }).toList();

    final conCredito = todos.where((c) => c.credito).length;
    final empresas = todos.where((c) => c.tipoDocumento == 'RUC').length;

    return Scaffold(
      appBar: AppBarTaller(
        subtitulo: 'Directorio',
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRoutes.push(context, const ClienteFormScreen()),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('NUEVO'),
      ),
      body: Column(
        children: [
          // ---------------------------------------------- buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FadeSlide(
              inicio: const Offset(0, -0.2),
              child: TextField(
                controller: _busquedaController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, documento o telefono',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.primary),
                  suffixIcon: texto.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _busquedaController.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------ filtros
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              children: [
                _ChipFiltro('Todos', todos.length, _filtro, (v) {
                  setState(() => _filtro = v);
                }),
                _ChipFiltro('Con credito', conCredito, _filtro, (v) {
                  setState(() => _filtro = v);
                }),
                _ChipFiltro('Empresas', empresas, _filtro, (v) {
                  setState(() => _filtro = v);
                }),
                _ChipFiltro('Personas', todos.length - empresas, _filtro,
                    (v) {
                  setState(() => _filtro = v);
                }),
              ],
            ),
          ),

          Expanded(
            child: filtrados.isEmpty
                ? EmptyState(
                    icono: Icons.people_alt_outlined,
                    titulo: todos.isEmpty ? 'Sin clientes' : 'Sin resultados',
                    mensaje: todos.isEmpty
                        ? 'Registra a los clientes habituales de la ferreteria.'
                        : 'No se encontraron clientes con ese criterio.',
                    textoBoton: todos.isEmpty ? 'Agregar cliente' : null,
                    onAccion: todos.isEmpty
                        ? () => AppRoutes.push(
                            context, const ClienteFormScreen())
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = filtrados[i];
                      return FadeSlide(
                        key: ValueKey('${_filtro}_${c.id}'),
                        delay: Duration(milliseconds: i < 8 ? i * 70 : 0),
                        child: _FichaCliente(
                          cliente: c,
                          puedeEliminar: puedeEliminar,
                          onMapa: c.direccion.trim().isEmpty
                              ? null
                              : () => AppRoutesMapa.cliente(context, c),
                          onEditar: () => AppRoutes.push(
                              context, ClienteFormScreen(cliente: c)),
                          onEliminar: () {
                            ConfirmDialog.mostrar(
                              context,
                              titulo: 'Eliminar cliente',
                              mensaje: '¿Eliminar a ${c.nombre}?',
                              textoConfirmar: 'Eliminar',
                              onConfirmar: () {
                                provider.eliminar(c.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppTheme.grafito,
                                    content: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: AppTheme.primary,
                                            size: 20),
                                        SizedBox(width: 10),
                                        Text('Cliente eliminado'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String texto;
  final int cantidad;
  final String actual;
  final ValueChanged<String> onTap;

  const _ChipFiltro(this.texto, this.cantidad, this.actual, this.onTap);

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final activo = texto == actual;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(texto),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: activo ? AppTheme.grafito : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activo
                  ? AppTheme.grafito
                  : (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro),
            ),
          ),
          child: Row(
            children: [
              Text(
                texto.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: activo ? AppTheme.primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: activo
                      ? AppTheme.primary
                      : Colors.grey.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: activo ? AppTheme.grafito : Colors.grey.shade600,
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

/// Ficha de cliente: avatar biselado con iniciales, nombre, documento,
/// telefono y sello de credito. Se inclina al tocarla.
class _FichaCliente extends StatelessWidget {
  final Cliente cliente;
  final bool puedeEliminar;
  final VoidCallback? onMapa;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _FichaCliente({
    required this.cliente,
    required this.puedeEliminar,
    required this.onMapa,
    required this.onEditar,
    required this.onEliminar,
  });

  String get _iniciales {
    final partes =
        cliente.nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final l = partes.take(2).map((p) => p[0].toUpperCase()).join();
    return l.isEmpty ? '?' : l;
  }

  @override
  Widget build(BuildContext context) {
    final esEmpresa = cliente.tipoDocumento == 'RUC';
    final color = esEmpresa ? const Color(0xFF0277BD) : AppTheme.primary;
    final gris = Colors.grey.shade600;

    return Tilt3D(
      anguloMax: 0.06,
      radioBorde: 14,
      builder: (context, t) => Card(
        child: InkWell(
          onTap: onEditar,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                  child: Transform.translate(
                    offset: Offset(t.dx * -3, t.dy * -3),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: color.withOpacity(0.14),
                        shape: BeveledRectangleBorder(
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(16)),
                          side: BorderSide(color: color.withOpacity(0.5)),
                        ),
                      ),
                      child: Text(
                        _iniciales,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cliente.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15.5,
                              height: 1.15,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cliente.tipoDocumento,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              cliente.documento,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: gris),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: gris),
                            const SizedBox(width: 5),
                            Text(
                              cliente.telefono,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: gris),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (cliente.credito)
                        Transform.rotate(
                          angle: -0.1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.success, width: 1.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CREDITO',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ),
                      if (onMapa != null)
                        IconButton(
                          tooltip: 'Ver en mapa',
                          icon: const Icon(Icons.map_outlined, size: 21),
                          color: const Color(0xFF0277BD),
                          onPressed: onMapa,
                        ),
                      if (puedeEliminar)
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline, size: 21),
                          color: AppTheme.danger,
                          onPressed: onEliminar,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
