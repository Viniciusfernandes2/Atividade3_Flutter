# Chat local entre celulares

Projeto Flutter para comunicação local entre celulares Android.

O aplicativo principal está em `app/` e foi ajustado para atender aos requisitos da atividade: comunicação entre celulares, Wi-Fi Direct, controle correto dos estados das mensagens e funcionamento com múltiplos dispositivos.

## O que foi implementado

1. Remoção do fluxo celular-notebook no aplicativo mobile.
2. Comunicação direta via Wi-Fi Direct entre celulares.
3. Correção dos estados das mensagens:
   - `Digitada`
   - `Recebida`
   - `Aberta`
4. Suporte ao funcionamento com pelo menos 3 celulares, mantendo conversas separadas por dispositivo.

## Estrutura principal

```text
app/
|-- android/
|   `-- app/src/main/kotlin/com/example/exemplo_quatro/
|       |-- MainActivity.kt
|       |-- ConnectionForegroundService.kt
|       `-- WifiDirectTransport.kt
|-- lib/
|   |-- app/
|   |-- core/platform/
|   |   |-- connection_foreground_service.dart
|   |   `-- wifi_direct_service.dart
|   `-- features/connection/
|       |-- connection_screen.dart
|       |-- data/message_protocol.dart
|       |-- models/connection_models.dart
|       `-- widgets/connection_widgets.dart
shared/
`-- lib/src/
    |-- message_protocol.dart
    |-- message_packet.dart
    |-- message_status.dart
    `-- message_batch_item.dart
outputs/
`-- arquivos de explicação e diffs das atividades
```

## Comunicação entre celulares

O app possui dois caminhos de comunicação:

- `Nearby Connections`, usado na opção `Buscar celulares`.
- `Wi-Fi Direct`, implementado diretamente no Android usando `WifiP2pManager` e sockets TCP.

No Wi-Fi Direct, o Flutter conversa com o Android por `MethodChannel`. O Android faz a descoberta/conexão com `WifiP2pManager` e, depois que o grupo Wi-Fi Direct é formado, troca os bytes das mensagens por socket TCP na porta `8988`.

## Estados das mensagens

O fluxo corrigido dos estados é:

1. `Digitada`: a mensagem foi criada localmente.
2. `Recebida`: o outro celular recebeu e enviou confirmação `received`.
3. `Aberta`: o outro celular abriu a conversa e enviou confirmação `opened`.

O estado só avança; ele não volta de `Aberta` para `Recebida`, por exemplo.

## Múltiplos dispositivos

O app guarda os dispositivos conectados em mapas separados para Nearby e Wi-Fi Direct. A lista de conversas é criada a partir desses dispositivos, e cada mensagem fica vinculada a um `conversaId`.

Para demonstrar com 3 celulares:

1. Abra o app nos celulares A, B e C.
2. Conecte B ao A.
3. Conecte C ao A.
4. No A, confirme que aparecem duas conversas e o cabeçalho informa `2 dispositivos conectados`.
5. Troque mensagens entre A e B, depois entre A e C.

## Arquivos de estudo

Os arquivos em `outputs/` mostram o que foi alterado em cada atividade:

- `atividade1-remocao-notebook.diff`
- `atividade2-explicacao.md`
- `atividade2-wifi-direct.diff`
- `atividade3-explicacao.md`
- `atividade3-estados-mensagens.diff`
- `atividade4-explicacao.md`
- `atividade4-multiplos-dispositivos.diff`

## Como validar

No app Android:

```powershell
cd app
flutter pub get
flutter analyze
flutter test
```

No pacote compartilhado:

```powershell
cd shared
dart analyze
```

## Observação

A validação automática confirma a consistência do código. A demonstração final das atividades 2 e 4 precisa ser feita em celulares Android reais, porque Wi-Fi Direct e conexões entre múltiplos dispositivos dependem do hardware e do sistema Android.
