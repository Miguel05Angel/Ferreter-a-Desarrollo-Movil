import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/producto.dart';
import '../../../providers/media_provider.dart';
import 'galeria_fotos.dart';

class EscenarioProducto extends StatelessWidget {
  const EscenarioProducto({
    super.key,
    required this.producto,
    required this.colorHex,
    required this.acento,
  });

  final Producto producto;
  final int colorHex;
  final Color acento;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final media = provider.de(producto.codigo);
    final respaldo = provider.fotoLocal(producto.codigo);
    final fotos = media?.tieneFotos == true
        ? media!.fotos
        : [if (respaldo != null) respaldo];

    if (fotos.isEmpty) return const SizedBox.expand();
    return GaleriaFotos(
      key: ValueKey(producto.codigo),
      ids: fotos,
      respaldoUrl: respaldo,
      referencial: media?.fotoReferencial ?? false,
    );
  }
}
