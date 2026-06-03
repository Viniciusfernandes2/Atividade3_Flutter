part of '../../../main.dart';

extension _DesktopMessageProtocol on _ConnectionDesktopScreenState {
  String _novoIdMensagem() {
    return MessageProtocol.newMessageId();
  }

  Uint8List _codificarMensagem(String id, String texto) {
    return MessageProtocol.encodeMessage(id, texto);
  }

  Uint8List _codificarLoteMensagens(List<_MensagemChat> mensagens) {
    return MessageProtocol.encodeBatch(
      mensagens
          .map(
            (mensagem) =>
                MessageBatchItem(id: mensagem.id, text: mensagem.texto),
          )
          .toList(),
    );
  }

  Uint8List _codificarConfirmacaoAbertura(String mensagemId) {
    return MessageProtocol.encodeOpened(mensagemId);
  }

  void _processarPacotesRecebidos(
    String texto,
    String deviceId,
    String remetente,
  ) {
    for (final pacote in MessageProtocol.decodePackets(texto)) {
      if (pacote.type == MessagePacketType.opened) {
        _atualizarStatusMensagem(pacote.id, MessageStatus.aberta);
        continue;
      }

      if (_mensagens.any((mensagem) => mensagem.id == pacote.id)) {
        unawaited(_enviarConfirmacaoAbertura(deviceId, pacote.id));
        continue;
      }

      _adicionarMensagemRecebidaAoHistorico(
        _MensagemChat(
          id: pacote.id,
          texto: pacote.text,
          remetente: remetente,
          enviadaPorMim: false,
          status: MessageStatus.aberta,
        ),
      );
      unawaited(_enviarConfirmacaoAbertura(deviceId, pacote.id));
    }
  }
}
