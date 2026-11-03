/// Recursos reales de un producto guardados en Google Drive. Cada valor es
/// el ID del archivo en Drive (la parte entre /d/ y /view de su enlace).
class ProductoMedia {
  final String codigo;

  /// Modelo 3D real (.glb o .gltf), maximo recomendado 15 MB.
  final String? modelo3d;

  /// Fotografias estandar (frontal, posterior, detalles).
  final List<String> fotos;

  /// Secuencia de fotos para la vista 360 (24 a 36 tomas, en orden).
  final List<String> giro360;

  const ProductoMedia({
    required this.codigo,
    this.modelo3d,
    this.fotos = const [],
    this.giro360 = const [],
  });

  bool get tieneModelo => modelo3d != null && modelo3d!.isNotEmpty;
  bool get tieneFotos => fotos.isNotEmpty;
  bool get tieneGiro => giro360.length >= 8;
  bool get tieneAlgo => tieneModelo || tieneFotos || tieneGiro;

  factory ProductoMedia.fromJson(String codigo, Map<String, dynamic> json) {
    List<String> lista(dynamic v) =>
        (v as List? ?? const []).map((e) => '$e').toList();
    return ProductoMedia(
      codigo: codigo,
      modelo3d: (json['modelo3d'] as String?)?.trim(),
      fotos: lista(json['fotos']),
      giro360: lista(json['giro360']),
    );
  }
}
