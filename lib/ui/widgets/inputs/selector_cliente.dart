import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../../providers/cliente_provider.dart';
import '../../screens/clientes/cliente_form_screen.dart';

const String _publico = '__publico__';

/// Seleccion de cliente para una venta: muestra el cliente elegido y
/// permite buscar uno existente o registrar uno nuevo sin salir del flujo.
class SelectorCliente extends StatelessWidget {
  final String? clienteId;
  final ValueChanged<String?> onCambio;

  const SelectorCliente({
    super.key,
    required this.clienteId,
    required this.onCambio,
  });

  Cliente? _buscar(List<Cliente> lista) {
    if (clienteId == null) return null;
    for (final c in lista) {
      if (c.id == clienteId) return c;
    }
    return null;
  }

  Future<void> _buscarCliente(BuildContext context) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<ClienteProvider>.value(
        value: context.read<ClienteProvider>(),
        child: _HojaClientes(seleccionado: clienteId),
      ),
    );
    if (r != null) onCambio(r == _publico ? null : r);
  }

  Future<void> _nuevoCliente(BuildContext context) async {
    final provider = context.read<ClienteProvider>();
    final antes = provider.clientes.map((c) => c.id).toSet();
    await AppRoutes.push(context, const ClienteFormScreen());
    for (final c in provider.clientes) {
      if (!antes.contains(c.id)) {
        onCambio(c.id);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final cliente = _buscar(context.watch<ClienteProvider>().clientes);
    final esEmpresa = cliente?.tipoDocumento == 'RUC';
    final color = cliente == null
        ? Colors.grey.shade600
        : (esEmpresa ? const Color(0xFF0277BD) : AppTheme.primary);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.15), end: Offset.zero)
                  .animate(a),
              child: c,
            ),
          ),
          child: Container(
            key: ValueKey(cliente?.id ?? _publico),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cliente == null
                    ? (oscuro ? AppTheme.bordeOscuro : AppTheme.bordeClaro)
                    : color.withValues(alpha: 0.7),
                width: cliente == null ? 1.2 : 1.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BeveledRectangleBorder(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(14)),
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: cliente == null
                      ? Icon(Icons.groups_outlined, color: color)
                      : Text(
                          cliente.nombre[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: color),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente?.nombre ?? 'Publico en general',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cliente == null
                            ? 'VENTA SIN DATOS DEL CLIENTE'
                            : '${cliente.tipoDocumento}  ${cliente.documento}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (cliente != null)
                  IconButton(
                    tooltip: 'Quitar cliente',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => onCambio(null),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _buscarCliente(context),
                icon: const Icon(Icons.search, size: 19),
                label: const Text('BUSCAR'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary, width: 1.8),
                  foregroundColor: oscuro
                      ? AppTheme.primary
                      : const Color(0xFFD95800),
                ),
                onPressed: () => _nuevoCliente(context),
                icon: const Icon(Icons.person_add_alt, size: 19),
                label: const Text('NUEVO'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HojaClientes extends StatefulWidget {
  final String? seleccionado;

  const _HojaClientes({required this.seleccionado});

  @override
  State<_HojaClientes> createState() => _HojaClientesState();
}

class _HojaClientesState extends State<_HojaClientes> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final texto = _c.text.trim().toLowerCase();
    final lista = context.watch<ClienteProvider>().clientes.where((c) {
      return texto.isEmpty ||
          c.nombre.toLowerCase().contains(texto) ||
          c.documento.contains(texto);
    }).toList();
    final alto = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: alto * 0.78),
        decoration: ShapeDecoration(
          color: oscuro ? AppTheme.superficieOscura : AppTheme.fondoClaro,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Container(width: 6, height: 20, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'ELEGIR CLIENTE',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _c,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Nombre o documento',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  if (texto.isEmpty)
                    _Fila(
                      titulo: 'Publico en general',
                      detalle: 'VENTA SIN DATOS DEL CLIENTE',
                      inicial: null,
                      color: Colors.grey.shade600,
                      activo: widget.seleccionado == null,
                      onTap: () => Navigator.of(context).pop(_publico),
                    ),
                  for (final c in lista)
                    _Fila(
                      titulo: c.nombre,
                      detalle: '${c.tipoDocumento}  ${c.documento}',
                      inicial: c.nombre[0].toUpperCase(),
                      color: c.tipoDocumento == 'RUC'
                          ? const Color(0xFF0277BD)
                          : AppTheme.primary,
                      activo: widget.seleccionado == c.id,
                      onTap: () => Navigator.of(context).pop(c.id),
                    ),
                  if (lista.isEmpty && texto.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'Sin resultados para "${_c.text.trim()}"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
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

class _Fila extends StatelessWidget {
  final String titulo;
  final String detalle;
  final String? inicial;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  const _Fila({
    required this.titulo,
    required this.detalle,
    required this.inicial,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: activo ? color.withValues(alpha: 0.12) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: activo ? color : Colors.grey.withValues(alpha: 0.25),
                  width: activo ? 1.8 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: const BeveledRectangleBorder(
                      borderRadius:
                          BorderRadius.only(bottomRight: Radius.circular(12)),
                    ),
                  ),
                  child: inicial == null
                      ? Icon(Icons.groups_outlined, color: color, size: 21)
                      : Text(inicial!,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      Text(detalle,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (activo) Icon(Icons.check_circle, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
