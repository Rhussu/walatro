import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walatro/screens/home.dart';
import 'package:walatro/widgets/hypnotic_background.dart';
import 'package:walatro/widgets/rules_dialog.dart';

void main() {
  testWidgets('HomeScreen renders with HypnoticBackground and main menu buttons',
      (WidgetTester tester) async {
    // Definir tamaño de pantalla adecuado para pruebas
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Permitir inicializar animaciones
    await tester.pump(const Duration(milliseconds: 100));

    // Verificar presencia de HypnoticBackground
    expect(find.byType(HypnoticBackground), findsOneWidget);

    // Verificar que los textos clave del menú existen
    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.text('ANOTADOR DE MESA'), findsOneWidget);
    expect(find.text('CÓMO JUGAR'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);
    expect(find.text('♠  A gambling memory game  ♣'), findsOneWidget);
    expect(find.text('v0.1.0 • WALATRO EDITION'), findsOneWidget);

    // Probar interacción con "CÓMO JUGAR" para abrir RulesDialog
    await tester.tap(find.text('CÓMO JUGAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(RulesDialog), findsOneWidget);
  });
}
