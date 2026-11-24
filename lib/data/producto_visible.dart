/// Los documentos anteriores sin marcas siguen siendo visibles.
bool productoVisible(Map<String, dynamic> datos) =>
    datos['activo'] != false && datos['eliminadoEn'] == null;
