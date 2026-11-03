import '../../data/models/producto.dart';

/// Lo que se necesita comprar para una tarea y como encontrarlo en el
/// catalogo (por tipo de producto o por palabras del nombre).
class Necesidad {
  final String etiqueta;
  final String consejo;
  final List<String> tipos;
  final List<String> palabras;
  final bool opcional;

  const Necesidad(
    this.etiqueta, {
    required this.consejo,
    this.tipos = const [],
    this.palabras = const [],
    this.opcional = false,
  });
}

class Tarea {
  final String titulo;
  final String resumen;
  final List<String> claves;
  final List<Necesidad> necesidades;

  const Tarea({
    required this.titulo,
    required this.resumen,
    required this.claves,
    required this.necesidades,
  });
}

/// Una necesidad con los productos del catalogo que la cubren.
class PasoRecomendado {
  final Necesidad necesidad;

  /// Primera opcion = mejor relacion precio-calidad; segunda = la mas barata.
  final List<Producto> opciones;

  /// Productos reales del catalogo que encajan pero NO se pueden recomendar
  /// ahora (sin stock o con precio por confirmar). Se muestran con su nombre
  /// real y una advertencia clara; nunca se oculta el producto.
  final List<Producto> noDisponibles;

  /// Cuantas opciones recomendables habia para comparar.
  final int candidatos;

  const PasoRecomendado(
    this.necesidad,
    this.opciones, {
    this.noDisponibles = const [],
    this.candidatos = 0,
  });

  Producto? get principal => opciones.isEmpty ? null : opciones.first;

  static String _s(double v) => 'S/ ${v.toStringAsFixed(2)}';

  /// Por que se recomienda la opcion [i]: breve y basado en calidad-precio.
  String motivo(int i) {
    final p = opciones[i];
    final cierre = p.critico ? ' Quedan pocas unidades (${p.stock}).' : '';
    if (i == 0) {
      if (p.calidad > 0) {
        return 'Mejor relación calidad-precio: calificación '
            '${p.calidad.toStringAsFixed(1)}/5 a ${_s(p.precioVenta)}, la que más '
            'calidad ofrece por cada sol entre $candidatos opciones disponibles '
            'en inventario.$cierre';
      }
      return 'Es la opción más económica (${_s(p.precioVenta)}) entre $candidatos '
          'disponibles en inventario. Aún no tiene calificación de calidad, por '
          'eso el precio es el criterio principal.$cierre';
    }
    final base = opciones.first;
    final ahorro = base.precioVenta - p.precioVenta;
    final pct = base.precioVenta == 0 ? 0 : (ahorro / base.precioVenta * 100).round();
    final menorCalidad = p.calidad > 0 && base.calidad > 0 && p.calidad < base.calidad
        ? ', aunque con menor calificación (${p.calidad.toStringAsFixed(1)}/5 frente a '
            '${base.calidad.toStringAsFixed(1)}/5)'
        : '';
    return 'Alternativa para ahorrar: cuesta ${_s(ahorro)} menos ($pct%) que la '
        'recomendada$menorCalidad. Elígela si priorizas el presupuesto.$cierre';
  }
}

class PlanTarea {
  final Tarea tarea;
  final List<PasoRecomendado> pasos;
  const PlanTarea(this.tarea, this.pasos);

  List<Producto> get productos =>
      [for (final p in pasos) if (p.principal != null && !p.necesidad.opcional) p.principal!];

  double get total => productos.fold(0.0, (s, p) => s + p.precioVenta);
}

/// Asistente: entiende la tarea escrita por el usuario y arma la lista de
/// herramientas y materiales. SOLO recomienda productos con precio
/// verificado (fuente + fecha): nunca inventa productos ni precios.
class AsistenteTareas {
  AsistenteTareas._();

  static const List<Tarea> tareas = [
    Tarea(
      titulo: 'Cambiar un foco',
      resumen: 'Apaga la llave general, deja enfriar el foco y reemplazalo por uno de la misma base.',
      claves: ['foco', 'bombilla', 'bombillo', 'lampara', 'luz', 'iluminacion', 'led', 'alumbrado'],
      necesidades: [
        Necesidad('Foco LED',
            consejo: 'Revisa la base (E27, G9...) y la potencia que indica tu portalampara.',
            tipos: ['foco']),
        Necesidad('Cinta aislante',
            consejo: 'Para proteger empalmes si el cable esta pelado.',
            tipos: ['cinta'],
            palabras: ['aislante'],
            opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Reparar una fuga de agua',
      resumen: 'Cierra la llave de paso, seca la zona y sella la union o cambia la pieza danada.',
      claves: ['fuga', 'gotea', 'goteo', 'filtracion', 'tuberia', 'caneria', 'agua', 'grifo', 'caño', 'pvc'],
      necesidades: [
        Necesidad('Cinta de teflon',
            consejo: 'Se enrolla en la rosca antes de ajustar la union.',
            tipos: ['cinta'],
            palabras: ['teflon']),
        Necesidad('Pegamento o sellador',
            consejo: 'Para uniones PVC o para rellenar fisuras pequenas.',
            tipos: ['pega']),
        Necesidad('Tuberia o accesorio de repuesto',
            consejo: 'Solo si la pieza esta rota y no basta con sellar.',
            tipos: ['tubo', 'codo'],
            opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Pintar una habitacion',
      resumen: 'Lija, protege los bordes, aplica una mano de base y luego la pintura.',
      claves: ['pintar', 'pintura', 'pared', 'paredes', 'habitacion', 'cuarto', 'dormitorio', 'muro', 'brocha', 'rodillo'],
      necesidades: [
        Necesidad('Pintura latex', consejo: 'Calcula el rendimiento por metro cuadrado.', tipos: ['pintura']),
        Necesidad('Rodillo', consejo: 'Para cubrir paredes rapido y parejo.', tipos: ['rodillo']),
        Necesidad('Brocha', consejo: 'Para esquinas y bordes.', tipos: ['brocha']),
        Necesidad('Cinta de enmascarar',
            consejo: 'Protege marcos, enchufes y zocalos.',
            tipos: ['cinta'],
            palabras: ['enmascarar'],
            opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Colgar un cuadro o instalar una repisa',
      resumen: 'Marca los puntos, perfora la pared, coloca tarugos y fija con tornillos.',
      claves: ['colgar', 'cuadro', 'repisa', 'estante', 'taladrar', 'perforar', 'fijar', 'soporte', 'tarugo'],
      necesidades: [
        Necesidad('Taladro', consejo: 'Con broca para pared (concreto o ladrillo).', tipos: ['taladro']),
        Necesidad('Tarugos y tornillos', consejo: 'Del diametro adecuado al peso que vas a colgar.', tipos: ['tornillos']),
        Necesidad('Cinta metrica', consejo: 'Para medir y nivelar la altura.', tipos: ['cinta'], palabras: ['metrica', 'flexometro']),
        Necesidad('Martillo', consejo: 'Para asentar los tarugos.', tipos: ['martillo'], opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Instalar un enchufe o interruptor',
      resumen: 'Corta la energia en el tablero, verifica sin voltaje y conecta respetando los colores.',
      claves: ['enchufe', 'tomacorriente', 'interruptor', 'switch', 'electrico', 'electricidad', 'cable', 'instalar luz'],
      necesidades: [
        Necesidad('Interruptor o tomacorriente', consejo: 'Elige segun la carga y el numero de salidas.', tipos: ['interruptor']),
        Necesidad('Cable', consejo: 'Seccion adecuada a la corriente del circuito.', tipos: ['cable']),
        Necesidad('Cinta aislante', consejo: 'Para aislar los empalmes.', tipos: ['cinta'], palabras: ['aislante']),
      ],
    ),
    Tarea(
      titulo: 'Reparar madera o una puerta',
      resumen: 'Ajusta bisagras, rellena orificios y fija con clavos o tornillos.',
      claves: ['madera', 'puerta', 'ventana', 'mueble', 'clavo', 'clavar', 'bisagra', 'carpinteria'],
      necesidades: [
        Necesidad('Martillo', consejo: 'De cabeza adecuada al clavo que usaras.', tipos: ['martillo']),
        Necesidad('Clavos', consejo: 'Longitud tres veces el grosor de la madera.', tipos: ['clavos']),
        Necesidad('Tornillos', consejo: 'Mejor agarre que el clavo en uniones que se mueven.', tipos: ['tornillos']),
      ],
    ),
    Tarea(
      titulo: 'Construir o reparar un muro',
      resumen: 'Prepara la mezcla, arma el refuerzo y vacia por capas.',
      claves: ['muro', 'construir', 'construccion', 'ladrillo', 'cemento', 'mezcla', 'columna', 'losa', 'obra'],
      necesidades: [
        Necesidad('Cemento', consejo: 'Tipo segun la obra (uso general o estructural).', tipos: ['cemento']),
        Necesidad('Fierro o alambre', consejo: 'Para el refuerzo estructural.', tipos: ['fierro']),
        Necesidad('Clavos', consejo: 'Para el encofrado.', tipos: ['clavos'], opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Reparar o cambiar un techo',
      resumen: 'Revisa el estado de la cobertura, retira lo danado, fija el material nuevo y sella las uniones. Trabaja con arnes y nunca subas con lluvia.',
      claves: ['techo', 'techar', 'tejado', 'calamina', 'gotera', 'goteras', 'cobertura', 'cubierta', 'aligerado', 'losa', 'impermeabilizar'],
      necesidades: [
        Necesidad('Clavos o tornillos para techo',
            consejo: 'Para fijar calaminas, madera o planchas. Elige la longitud segun el grosor.',
            tipos: ['clavos', 'tornillos']),
        Necesidad('Martillo', consejo: 'Para clavar y retirar piezas.', tipos: ['martillo']),
        Necesidad('Cinta metrica',
            consejo: 'Para medir el area y cortar el material.',
            tipos: ['cinta'],
            palabras: ['metrica', 'flexometro']),
        Necesidad('Cemento',
            consejo: 'Solo si hay que reparar una losa o un aligerado.',
            tipos: ['cemento'],
            opcional: true),
        Necesidad('Pintura',
            consejo: 'Para proteger la superficie; verifica que sea apta para exteriores.',
            tipos: ['pintura'],
            opcional: true),
      ],
    ),
    Tarea(
      titulo: 'Reparar un desague o instalar un tubo',
      resumen: 'Cierra el agua, retira el tramo danado, limpia las uniones y pega la pieza nueva.',
      claves: ['desague', 'atoro', 'atascado', 'tapado', 'inodoro', 'wc', 'lavadero', 'lavatorio', 'ducha', 'gasfiteria', 'instalar tubo'],
      necesidades: [
        Necesidad('Tuberia', consejo: 'Del mismo diametro que la existente.', tipos: ['tubo']),
        Necesidad('Codo o union', consejo: 'Para cambios de direccion.', tipos: ['codo']),
        Necesidad('Pegamento para PVC', consejo: 'Aplicalo en ambas superficies.', tipos: ['pega']),
      ],
    ),
  ];

  static String _norm(String t) => t
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Palabras que no dicen nada de la tarea.
  static const Set<String> _vacias = {
    'quiero', 'quisiera', 'necesito', 'deseo', 'voy', 'tengo', 'hacer',
    'como', 'para', 'que', 'con', 'mi', 'mis', 'un', 'una', 'unos', 'unas',
    'el', 'la', 'los', 'las', 'de', 'del', 'al', 'en', 'por', 'se', 'me',
    'lo', 'es', 'y', 'o', 'a', 'ya', 'hoy', 'favor', 'ayuda', 'ayudame',
    'puedo', 'debo', 'hay', 'esta', 'este', 'esto', 'mas', 'muy', 'algo',
    'cambiar', 'arreglar', 'reparar', 'instalar', 'poner', 'colocar',
    'comprar', 'buscar', 'hacerle', 'nuevo', 'nueva', 'casa', 'mio', 'mia',
  };

  /// Reduce una palabra a su raiz (plural, verbo conjugado, genero).
  static String _raiz(String w) {
    var r = w;
    const sufijos = [
      'aciones', 'acion', 'amientos', 'amiento', 'ando', 'iendo', 'ados',
      'adas', 'ado', 'ada', 'idos', 'idas', 'ido', 'ida', 'ares', 'ar',
      'er', 'ir', 'es', 's',
    ];
    for (final suf in sufijos) {
      if (r.length - suf.length >= 4 && r.endsWith(suf)) {
        r = r.substring(0, r.length - suf.length);
        break;
      }
    }
    if (r.length > 4 && 'aeiou'.contains(r[r.length - 1])) {
      r = r.substring(0, r.length - 1);
    }
    return r;
  }

  static int _distancia(String a, String b) {
    if (a == b) return 0;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var anterior = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final temp = prev[j];
        final costo = a[i - 1] == b[j - 1] ? 0 : 1;
        prev[j] = [prev[j] + 1, prev[j - 1] + 1, anterior + costo]
            .reduce((x, y) => x < y ? x : y);
        anterior = temp;
      }
    }
    return prev[b.length];
  }

  /// Dos raices "son la misma palabra": iguales, una prefijo de la otra o
  /// con un error de tipeo.
  static bool _parecidas(String a, String b) {
    if (a == b) return true;
    final m = a.length < b.length ? a.length : b.length;
    if (m < 4) return false;
    if (a.startsWith(b) || b.startsWith(a)) return true;
    return m >= 5 && _distancia(a, b) <= 1;
  }

  static List<String> _raices(String texto) => _norm(texto)
      .split(' ')
      .where((w) => w.length > 1 && !_vacias.contains(w))
      .map(_raiz)
      .toList();

  /// Tarea que mejor coincide con la intencion escrita; null si no se
  /// entiende. Analiza palabra por palabra (plurales, conjugaciones, errores
  /// de tipeo) y tambien frases completas.
  static Tarea? entender(String descripcion) {
    final tokens = _raices(descripcion);
    final frase = ' ${_norm(descripcion)} ';
    if (tokens.isEmpty) return null;

    Tarea? mejor;
    var mejorPuntos = 0.0;
    for (final t in tareas) {
      var puntos = 0.0;
      for (final c in t.claves) {
        final cn = _norm(c);
        if (cn.contains(' ')) {
          if (frase.contains(' $cn ')) puntos += 3;
          continue;
        }
        final rc = _raiz(cn);
        for (final tk in tokens) {
          if (_parecidas(tk, rc)) {
            puntos += cn.length > 4 ? 2 : 1;
            break;
          }
        }
      }
      // El titulo de la tarea tambien cuenta
      for (final tk in tokens) {
        for (final w in _norm(t.titulo).split(' ')) {
          if (w.length > 3 && _parecidas(tk, _raiz(w))) puntos += 1.5;
        }
      }
      if (puntos > mejorPuntos) {
        mejorPuntos = puntos;
        mejor = t;
      }
    }
    return mejorPuntos >= 1 ? mejor : null;
  }

  static const Map<String, String> _etiquetaTipo = {
    'foco': 'Focos',
    'cinta': 'Cintas',
    'pega': 'Pegamentos y selladores',
    'tubo': 'Tuberias',
    'codo': 'Codos y uniones',
    'pintura': 'Pinturas',
    'rodillo': 'Rodillos',
    'brocha': 'Brochas',
    'taladro': 'Taladros',
    'tornillos': 'Tornillos',
    'clavos': 'Clavos',
    'martillo': 'Martillos',
    'llaves': 'Llaves y alicates',
    'cable': 'Cables',
    'interruptor': 'Interruptores y tomacorrientes',
    'cemento': 'Cementos',
    'fierro': 'Fierro y acero',
    'manguera': 'Mangueras',
    'pistola': 'Pistolas',
  };

  /// Se recomienda lo que hay en inventario (con stock y precio de venta).
  static bool _recomendable(Producto p) => !p.agotado && p.precioVenta > 0;

  /// Productos del catalogo que encajan pero estan agotados (se avisan con su
  /// nombre real y "stock bajo pedido").
  static List<Producto> _noDisponibles(List<Producto> l) {
    final c = [...l]..sort((a, b) {
        if (a.agotado != b.agotado) return a.agotado ? -1 : 1;
        return a.precioVenta.compareTo(b.precioVenta);
      });
    return c.take(2).toList();
  }

  static double _valor(Producto p) =>
      p.calidad > 0 ? p.calidad / p.precioVenta : 1 / p.precioVenta;

  /// Mejor relacion precio-calidad + la mas economica distinta.
  static List<Producto> _opciones(List<Producto> buenos) {
    final c = [...buenos]..sort((a, b) => _valor(b).compareTo(_valor(a)));
    final baratos = [...c]..sort((a, b) => a.precioVenta.compareTo(b.precioVenta));
    final opciones = <Producto>[c.first];
    if (baratos.first.id != c.first.id) opciones.add(baratos.first);
    return opciones;
  }

  /// Cuando no se reconoce una tarea concreta: busca en el catalogo los
  /// productos que coinciden con las palabras escritas (nombre, marca, tipo).
  static PlanTarea? armarLibre(String descripcion, List<Producto> catalogo) {
    final tokens = _raices(descripcion);
    if (tokens.isEmpty) return null;

    final porTipo = <String, List<Producto>>{};
    for (final p in catalogo) {
      final texto = _norm('${p.nombre} ${p.marca} ${p.descripcion} ${_etiquetaTipo[p.tipoVisual] ?? ''}');
      final palabras = texto.split(' ').map(_raiz).toList();
      final coincide = tokens.any((tk) => palabras.any((w) => _parecidas(tk, w)));
      if (coincide) porTipo.putIfAbsent(p.tipoVisual, () => []).add(p);
    }
    if (porTipo.isEmpty) return null;

    final pasos = <PasoRecomendado>[];
    for (final e in porTipo.entries.take(5)) {
      final necesidad = Necesidad(_etiquetaTipo[e.key] ?? 'Productos relacionados',
          consejo: 'Coincide con lo que escribiste.', tipos: [e.key]);
      final buenos = e.value.where(_recomendable).toList();
      if (buenos.isEmpty) {
        pasos.add(PasoRecomendado(necesidad, const [], noDisponibles: _noDisponibles(e.value)));
      } else {
        pasos.add(PasoRecomendado(necesidad, _opciones(buenos), candidatos: buenos.length));
      }
    }
    return PlanTarea(
      const Tarea(
        titulo: 'Productos relacionados',
        resumen: 'No identifique una tarea concreta, pero estos productos del '
            'catalogo coinciden con lo que describiste. Cuentame un poco mas '
            'si buscas algo distinto.',
        claves: [],
        necesidades: [],
      ),
      pasos,
    );
  }

  static bool _cumple(Necesidad n, Producto p) {
    final nombre = _norm(p.nombre);
    final porPalabra = n.palabras.any((w) => nombre.contains(_norm(w)));
    final porTipo = n.tipos.contains(p.tipoVisual);
    // Si la necesidad pide palabras especificas, el tipo solo no basta.
    if (n.palabras.isNotEmpty) return porPalabra && (n.tipos.isEmpty || porTipo);
    return porTipo;
  }

  /// Arma el plan: productos recomendables (precio verificado y con stock) y,
  /// si no hay, los productos reales que existen en el catalogo pero estan
  /// agotados o sin precio confirmado, para avisarlo con su nombre.
  static PlanTarea armar(Tarea tarea, List<Producto> catalogo) {
    final pasos = <PasoRecomendado>[];
    for (final n in tarea.necesidades) {
      final coinciden = catalogo.where((p) => _cumple(n, p)).toList();
      final buenos = coinciden.where(_recomendable).toList();
      if (buenos.isEmpty) {
        pasos.add(PasoRecomendado(n, const [], noDisponibles: _noDisponibles(coinciden)));
      } else {
        pasos.add(PasoRecomendado(n, _opciones(buenos), candidatos: buenos.length));
      }
    }
    return PlanTarea(tarea, pasos);
  }
}
