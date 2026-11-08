import 'package:ferreteria_app/ui/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El acceso público solo pide DNI y contraseña', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('DNI'), findsOneWidget);
    expect(find.text('CONTRASEÑA'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });
}
