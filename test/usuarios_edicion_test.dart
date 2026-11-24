import 'package:ferreteria_app/data/models/usuario.dart';
import 'package:ferreteria_app/providers/auth_provider.dart';
import 'package:ferreteria_app/ui/screens/perfil/editar_usuario_screen.dart';
import 'package:ferreteria_app/ui/screens/perfil/usuarios_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const vendedor = Usuario(
  id: 'vendedor',
  dni: '12345678',
  nombre: 'Juan Perez',
  telefono: '987654321',
  rol: 'Vendedor',
);
const administrador = Usuario(
  id: 'admin',
  dni: '87654321',
  nombre: 'Administrador',
  telefono: '',
  rol: 'Administrador',
);

class SesionPrueba extends ChangeNotifier implements AuthProvider {
  SesionPrueba(this.usuarioActual);
  @override
  Usuario? usuarioActual;
  int lecturas = 0;
  Map<String, String>? guardado;
  @override
  Stream<List<Usuario>> escucharUsuarios() {
    lecturas++;
    return Stream.value([vendedor]);
  }

  @override
  Future<void> editarUsuario(
      {required String usuarioId,
      required String nombre,
      required String telefono}) async {
    guardado = {'id': usuarioId, 'nombre': nombre, 'telefono': telefono};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(SesionPrueba sesion, Widget screen) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: sesion,
      child: MaterialApp(home: screen),
    );

void main() {
  testWidgets('Vendedor y visitante no leen ni editan usuarios',
      (tester) async {
    for (final usuario in [vendedor, null]) {
      final sesion = SesionPrueba(usuario);
      await tester.pumpWidget(app(sesion, const UsuariosScreen()));
      await tester.pumpAndSettle();
      expect(sesion.lecturas, 0);
      expect(find.byTooltip('Editar usuario'), findsNothing);
      await tester.pumpWidget(
          app(sesion, const EditarUsuarioScreen(usuario: vendedor)));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Guardar cambios'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      sesion.dispose();
    }
  });

  testWidgets('Administrador abre y guarda nombre y teléfono', (tester) async {
    final sesion = SesionPrueba(administrador);
    await tester.pumpWidget(app(sesion, const UsuariosScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar usuario'));
    await tester.pumpAndSettle();
    expect(find.text('DNI 12345678 · Vendedor'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(
        find.byType(TextFormField).first, 'Juan Actualizado');
    await tester.enterText(find.byType(TextFormField).last, '912345678');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(sesion.guardado, {
      'id': 'vendedor',
      'nombre': 'Juan Actualizado',
      'telefono': '912345678',
    });
    expect(find.text('Usuarios'), findsOneWidget);
  });

  testWidgets('Nombre vacío y teléfono inválido impiden guardar',
      (tester) async {
    final sesion = SesionPrueba(administrador);
    await tester
        .pumpWidget(app(sesion, const EditarUsuarioScreen(usuario: vendedor)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(sesion.guardado, isNull);
    expect(find.text('Ingresa el nombre'), findsOneWidget);
    expect(find.textContaining('El celular debe tener'), findsOneWidget);
  });
}
