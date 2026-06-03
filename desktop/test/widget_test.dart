import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connection_desktop/main.dart';

void main() {
  testWidgets('mostra tela principal do desktop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ConnectionDesktopScreen(configurarBluetooth: false),
      ),
    );

    expect(find.text('Conexao Bluetooth'), findsOneWidget);
    expect(find.textContaining('Status:'), findsOneWidget);
  });
}
