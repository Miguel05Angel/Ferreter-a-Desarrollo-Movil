# Ferreteria El Constructor - App movil Flutter

Aplicacion de gestion para ferreteria desarrollada en Flutter, con
arquitectura ordenada por capas, animaciones en toda la interfaz y
validaciones completas en formularios.

## Modulos

- Autenticación: acceso con DNI y contraseña, con alta de vendedores desde el perfil del administrador.
- Productos: catalogo con busqueda, filtro por categoria, CRUD completo
  y alertas de stock bajo/agotado.
- Carrito y ventas: registro de venta con IGV (18%), metodos de pago
  (Efectivo, Yape, Plin, Tarjeta), boleta/factura, descuento automatico
  de stock y numero de comprobante correlativo.
- Clientes: registro con DNI (8 digitos) / RUC (11 digitos), telefono
  (9 digitos), venta al credito (fiado).
- Proveedores: gestion con RUC y productos que ofrecen.
- Cotizaciones: creacion con validez configurable y cambio de estado.
- Inicio: panel con estadisticas animadas, categorias y accesos rapidos.
- Perfil: modo oscuro, edicion de nombre y cierre de sesion.

## Estructura

```
lib/
  main.dart
  app.dart
  core/
    constants/     # Constantes globales (IGV, unidades, metodos de pago)
    routes/        # Rutas con transiciones animadas
    theme/         # Tema claro/oscuro
    utils/         # Validadores y formateadores
  data/
    models/        # Modelos de datos
  providers/       # Estado con ChangeNotifier (Provider)
  ui/
    screens/       # Pantallas organizadas por modulo
    widgets/       # Widgets reutilizables (botones, tarjetas, chips...)
```

## Como ejecutar

1. Instalar Flutter SDK (canal estable).
2. Abrir la carpeta del proyecto en Android Studio o VS Code.
3. Ejecutar: `flutter pub get`
4. Conectar un emulador o dispositivo y ejecutar: `flutter run`

## Configuración de Firebase

La [guía de la práctica 11](docs/GUIA_11_FIREBASE.md) explica cómo crear el
primer administrador, probar el flujo local y activar el proyecto compartido.
