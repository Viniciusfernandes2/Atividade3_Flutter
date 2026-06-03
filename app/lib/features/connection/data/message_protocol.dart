part of '../connection_screen.dart';

extension _ConnectionMessageProtocol on _ConnectionScreenState {
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

  Uint8List _codificarConfirmacaoRecebimento(String mensagemId) {
    return MessageProtocol.encodeReceived(mensagemId);
  }

  Uint8List _codificarConfirmacaoAbertura(String mensagemId) {
    return MessageProtocol.encodeOpened(mensagemId);
  }

  void _processarPacotesRecebidos(
    String texto,
    String conversaId,
    String remetente,
  ) {
    final pacotes = MessageProtocol.decodePackets(texto);

    for (final pacote in pacotes) {
      if (pacote.type == MessagePacketType.received) {
        _atualizarStatusMensagem(pacote.id, MessageStatus.recebida);
        continue;
      }

      if (pacote.type == MessagePacketType.opened) {
        _atualizarStatusMensagem(pacote.id, MessageStatus.aberta);
        continue;
      }

      final status = _conversaEstaAberta(conversaId)
          ? MessageStatus.aberta
          : MessageStatus.recebida;
      if (_mensagens.any((mensagem) => mensagem.id == pacote.id)) {
        unawaited(
          _confirmarEstadoRemoto(
            conversaId,
            pacote.id,
            aberta: status == MessageStatus.aberta,
          ),
        );
        continue;
      }
      _adicionarMensagemRecebidaAoHistorico(
        _MensagemChat(
          id: pacote.id,
          conversaId: conversaId,
          texto: pacote.text,
          remetente: remetente,
          enviadaPorMim: false,
          status: status,
        ),
      );
      unawaited(
        _confirmarEstadoRemoto(
          conversaId,
          pacote.id,
          aberta: status == MessageStatus.aberta,
        ),
      );
    }
  }
}
