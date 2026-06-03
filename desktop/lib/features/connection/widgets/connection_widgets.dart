part of '../../../main.dart';

class _PainelConexao extends StatelessWidget {
  const _PainelConexao({
    required this.nomeUsuario,
    required this.serviceId,
    required this.estadoBluetooth,
    required this.anunciando,
    required this.procurando,
    required this.tipoBusca,
    required this.conectados,
  });

  final String nomeUsuario;
  final String serviceId;
  final String estadoBluetooth;
  final bool anunciando;
  final bool procurando;
  final _TipoBusca? tipoBusca;
  final int conectados;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nomeUsuario, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Bluetooth: $estadoBluetooth'),
          Text('ServiceId: $serviceId'),
          Text(
            anunciando
                ? 'Status: disponivel para conexoes'
                : procurando
                ? 'Status: buscando ${tipoBusca == _TipoBusca.notebooks ? 'notebooks' : 'celulares'}'
                : 'Status: indisponivel',
          ),
          Text('Conectados: $conectados'),
        ],
      ),
    );
  }
}

class _AvisoCompatibilidade extends StatelessWidget {
  const _AvisoCompatibilidade();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Para o notebook encontrar o celular, deixe o celular em Disponivel. '
        'Depois procure no desktop pelo nome salvo no celular. Se o celular apenas buscar o notebook, '
        'ele conecta como cliente e nao aparece na busca do desktop.',
        style: TextStyle(color: colorScheme.onSecondaryContainer),
      ),
    );
  }
}

class _ListaAparelhos extends StatelessWidget {
  const _ListaAparelhos({
    required this.titulo,
    required this.aparelhos,
    required this.conectando,
    required this.onConectar,
  });

  final String titulo;
  final List<BleDevice> aparelhos;
  final bool conectando;
  final ValueChanged<BleDevice> onConectar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: aparelhos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhum aparelho encontrado.'),
                  ),
                )
              : ListView.builder(
                  itemCount: aparelhos.length,
                  itemBuilder: (context, index) {
                    final aparelho = aparelhos[index];
                    final nome = aparelho.name?.isNotEmpty == true
                        ? aparelho.name!
                        : 'Aparelho sem nome';
                    final servicos = aparelho.services.isEmpty
                        ? 'sem servicos anunciados'
                        : 'servicos: ${aparelho.services.join(', ')}';

                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(nome),
                      subtitle: Text(
                        [
                          aparelho.deviceId,
                          if (aparelho.rssi != null) 'RSSI ${aparelho.rssi}',
                          servicos,
                        ].join(' | '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Conectar',
                        onPressed: conectando
                            ? null
                            : () => onConectar(aparelho),
                        icon: conectando
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Chat extends StatelessWidget {
  const _Chat({
    required this.mensagens,
    required this.controller,
    required this.conectado,
    required this.onEnviar,
  });

  final List<_MensagemChat> mensagens;
  final TextEditingController controller;
  final bool conectado;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: mensagens.isEmpty
              ? const Center(
                  child: Text('Conecte um aparelho para iniciar o chat.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = mensagens[index];
                    final alinhamento = mensagem.enviadaPorMim
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final cor = mensagem.enviadaPorMim
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest;

                    return Align(
                      alignment: alinhamento,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mensagem.remetente,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(mensagem.texto),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                mensagem.status.rotulo,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: conectado,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Digite uma mensagem',
                  ),
                  onSubmitted: conectado ? (_) => onEnviar() : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: conectado ? onEnviar : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
