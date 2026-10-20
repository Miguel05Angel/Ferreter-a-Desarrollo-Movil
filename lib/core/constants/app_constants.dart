class AppConstants {
  AppConstants._();

  static const String nombreApp = 'Ferreteria El Constructor';
  static const String eslogan = 'Todo para tu construccion';
  static const double igv = 0.18;
  static const int stockBajo = 5;
  static const String direccionFerreteria =
      'Av. Los Constructores 123, Lima, Peru';
  // Datos del negocio que aparecen en los comprobantes. Son valores de
  // ejemplo: cambialos por los reales de la ferreteria.
  static const String rucFerreteria = '20601234567';
  static const String telefonoFerreteria = '(01) 456-7890';
  static const String celularYapePlin = '987 654 321';
  static const String titularYapePlin = 'Ferreteria El Constructor';

  static const double latitudFerreteria = -12.0464;
  static const double longitudFerreteria = -77.0428;

  static const List<String> unidades = [
    'Unidad',
    'Metro',
    'Kg',
    'Bolsa',
    'Caja',
    'Galon',
    'Litro',
    'Pulgada',
  ];

  static const List<String> metodosPago = [
    'Efectivo',
    'Yape',
    'Plin',
    'Tarjeta',
  ];

  static const List<String> comprobantes = [
    'Boleta',
    'Factura',
  ];

  static const List<int> diasValidez = [7, 15, 30];
}
