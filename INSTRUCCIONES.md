# ferreteria_app - correcciones (stock reservado, efectivo, reposicion, bienvenida)

## 1. Copiar
Descomprime este zip SOBRE tu proyecto (mismas carpetas) y acepta reemplazar.

## 2. Ejecutar
    flutter clean
    flutter pub get
    flutter run

## 3. Como comprobar cada correccion
1. STOCK EN PLOMO: abre un producto con 2 unidades -> "Agregar" dos veces.
   El numero baja 2 -> 1 -> 0 con animacion, aparece "2 EN CARRITO" en gris plomo
   y la barra se pinta de plomo. Si borras el item del carrito, vuelve a subir.
2. EFECTIVO: vende algo que sume S/ 106.08 -> Efectivo.
   Aparece el aviso "Redondeo en efectivo": comprobante S/ 106.08, a cobrar S/ 106.00.
   Con Yape, Plin o Tarjeta se cobra S/ 106.08 exacto.
3. REPOSICION: abre un producto con 5 unidades o menos (o agotado).
   Administrador: "Solicitar reposicion de stock" -> elige proveedor, cantidad,
   "Generar reporte de pedido" (PDF), "Solicitar por WhatsApp", "Llamar",
   y "Registrar ingreso de stock" cuando llegue la mercaderia.
   Vendedor: "Avisar al administrador" (WhatsApp).
4. BIENVENIDA: cierra la app por completo y vuelve a abrirla: el anillo 3D
   ya muestra los productos y dice "08 REFERENCIAS".

## 4. Firebase
Los datos nuevos (2 proveedores nuevos) se cargan solos al abrir la app
(version de datos 3). No se pisan tus cambios.
