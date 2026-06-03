part of '../../../main.dart';

class _MensagemChat {
  const _MensagemChat({
    required this.id,
    required this.texto,
    required this.remetente,
    required this.enviadaPorMim,
    required this.status,
  });

  final String id;
  final String texto;
  final String remetente;
  final bool enviadaPorMim;
  final MessageStatus status;

  _MensagemChat copyWith({MessageStatus? status}) {
    return _MensagemChat(
      id: id,
      texto: texto,
      remetente: remetente,
      enviadaPorMim: enviadaPorMim,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'texto': texto,
      'remetente': remetente,
      'enviadaPorMim': enviadaPorMim,
      'status': status.name,
    };
  }

  factory _MensagemChat.fromJson(Map<String, dynamic> json) {
    return _MensagemChat(
      id: json['id'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      remetente: json['remetente'] as String? ?? '',
      enviadaPorMim: json['enviadaPorMim'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.recebida,
      ),
    );
  }
}
