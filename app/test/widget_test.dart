import 'dart:convert';

import 'package:connection_shared/connection_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exemplo_quatro/app/connection_app.dart';

void main() {
  testWidgets('mostra tela principal de conexao', (tester) async {
    await tester.pumpWidget(const ConnectionApp());

    expect(find.text('Chat local'), findsOneWidget);
  });

  test('protocolo reconhece confirmacao de recebimento', () {
    final bytes = MessageProtocol.encodeReceived('mensagem-1');
    final packet = MessageProtocol.decodePacket(utf8.decode(bytes));

    expect(packet.type, MessagePacketType.received);
    expect(packet.id, 'mensagem-1');
  });

  test('ordem dos estados segue o fluxo da mensagem', () {
    expect(
      MessageStatus.digitada.index,
      lessThan(MessageStatus.recebida.index),
    );
    expect(MessageStatus.recebida.index, lessThan(MessageStatus.aberta.index));
  });
}
