import '../../data/models/producto.dart';

/// Una recomendacion: el producto y el motivo por el que se sugiere.
class Recomendacion {
  final Producto producto;
  final String motivo;

  const Recomendacion(this.producto, this.motivo);
}

/// Sugiere productos que se usan junto con el que se esta viendo.
/// Por ejemplo, con un martillo recomienda clavos, tornillos y una cinta
/// metrica; con una pintura recomienda rodillos, brochas y cinta.
class Recomendador {
  Recomendador._();

  /// tipo visual -> tipos que lo complementan, en orden de importancia.
  static const Map<String, List<String>> _complementos = {
    'martillo': ['clavos', 'tornillos', 'cinta', 'llaves'],
    'clavos': ['martillo', 'tornillos', 'cinta'],
    'tornillos': ['taladro', 'llaves', 'clavos'],
    'taladro': ['tornillos', 'llaves', 'cable', 'cinta'],
    'llaves': ['tornillos', 'martillo', 'cinta'],
    'pistola': ['cinta', 'pega', 'cable'],
    'cinta': ['martillo', 'llaves', 'clavos', 'tornillos'],
    'pintura': ['rodillo', 'brocha', 'cinta', 'pega'],
    'rodillo': ['pintura', 'brocha', 'cinta'],
    'brocha': ['pintura', 'rodillo', 'cinta'],
    'tubo': ['codo', 'pega', 'llaves', 'cinta'],
    'codo': ['tubo', 'pega', 'llaves'],
    'pega': ['tubo', 'codo', 'manguera'],
    'manguera': ['codo', 'pega', 'llaves'],
    'cable': ['interruptor', 'foco', 'cinta', 'llaves'],
    'interruptor': ['cable', 'foco', 'cinta'],
    'foco': ['interruptor', 'cable'],
    'cemento': ['fierro', 'clavos', 'llaves', 'manguera'],
    'fierro': ['cemento', 'clavos', 'cinta', 'llaves'],
  };

  /// Etiqueta corta segun para que sirve el producto recomendado.
  static const Map<String, String> _motivos = {
    'martillo': 'Para golpear',
    'clavos': 'Para fijar',
    'tornillos': 'Para fijar',
    'taladro': 'Para perforar',
    'llaves': 'Para ajustar',
    'pistola': 'Acabados',
    'cinta': 'Para medir',
    'pintura': 'Para pintar',
    'rodillo': 'Para aplicar',
    'brocha': 'Para aplicar',
    'tubo': 'Para conducir',
    'codo': 'Para unir tubos',
    'pega': 'Para pegar',
    'manguera': 'Para conducir',
    'cable': 'Instalacion',
    'interruptor': 'Instalacion',
    'foco': 'Iluminacion',
    'cemento': 'Para construir',
    'fierro': 'Refuerzo',
  };

  static List<Recomendacion> para(
    Producto actual,
    List<Producto> todos, {
    int maximo = 8,
  }) {
    final tipos = _complementos[actual.tipoVisual] ?? const <String>[];
    final resultado = <Recomendacion>[];
    final usados = <String>{actual.id};

    // 1) Complementos por tipo, respetando el orden de importancia
    for (final tipo in tipos) {
      final candidatos = todos
          .where((p) =>
              p.tipoVisual == tipo && !usados.contains(p.id) && !p.agotado)
          .toList()
        // mismo grupo de producto primero, luego los de mayor stock
        ..sort((a, b) {
          final ca = a.categoriaId == actual.categoriaId ? 0 : 1;
          final cb = b.categoriaId == actual.categoriaId ? 0 : 1;
          if (ca != cb) return ca.compareTo(cb);
          return b.stock.compareTo(a.stock);
        });
      // Hasta 2 por tipo para que la lista sea variada
      for (final p in candidatos.take(2)) {
        usados.add(p.id);
        resultado.add(Recomendacion(p, _motivos[tipo] ?? 'Complemento'));
        if (resultado.length >= maximo) return resultado;
      }
    }

    // 2) Si faltan, completar con productos de la misma categoria
    if (resultado.length < maximo) {
      for (final p in todos) {
        if (usados.contains(p.id) || p.agotado) continue;
        if (p.categoriaId != actual.categoriaId) continue;
        usados.add(p.id);
        resultado.add(Recomendacion(p, 'Misma linea'));
        if (resultado.length >= maximo) break;
      }
    }
    return resultado;
  }
}
