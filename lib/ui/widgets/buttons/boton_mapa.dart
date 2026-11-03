import 'package:flutter/material.dart';

import '../../../core/utils/mapas_service.dart';

/// Icono que abre las opciones de Google Maps para una direccion:
/// ver la ubicacion o trazar la ruta hasta ella.
class BotonMapa extends StatelessWidget {
  final String direccion;
  final String nombre;
  final Color color;

  const BotonMapa({
    super.key,
    required this.direccion,
    required this.nombre,
    this.color = const Color(0xFF0277BD),
  });

  void _abrirMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.map_outlined, color: color),
              title: Text(nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(direccion),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: const Text('Ver ubicacion en Google Maps'),
              onTap: () {
                Navigator.of(sheet).pop();
                MapasService.verDireccion(context, direccion);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_outlined),
              title: const Text('Como llegar (ruta)'),
              subtitle: const Text('Traza la ruta desde donde estas'),
              onTap: () {
                Navigator.of(sheet).pop();
                MapasService.comoLlegar(context, direccion);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Google Maps',
      icon: const Icon(Icons.map_outlined, size: 21),
      visualDensity: VisualDensity.compact,
      color: color,
      onPressed: direccion.trim().isEmpty ? null : () => _abrirMenu(context),
    );
  }
}
