# Chat local entre celulares

Projeto Flutter ajustado para a atividade de comunicacao entre dispositivos moveis.

O foco da entrega esta no aplicativo Android em `app/`. O projeto original tambem possui uma pasta `desktop/`, mas a atividade solicitou remover o fluxo celular-notebook do aplicativo mobile e manter a comunicacao entre celulares.

## O que foi implementado

1. Remocao do fluxo celular-notebook no app mobile.
2. Comunicacao direta via Wi-Fi Direct entre celulares.
3. Correcao dos estados das mensagens:
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
`-- arquivos de explicacao e diffs das atividades
```

## Comunicacao entre celulares

O app possui dois caminhos de comunicacao:

- `Nearby Connections`, usado na opcao `Buscar celulares`.
- `Wi-Fi Direct`, implementado diretamente no Android usando `WifiP2pManager` e sockets TCP.

No Wi-Fi Direct, o Flutter conversa com o Android por `MethodChannel`. O Android faz a descoberta/conexao com `WifiP2pManager` e, depois que o grupo Wi-Fi Direct e formado, troca os bytes das mensagens por socket TCP na porta `8988`.

## Estados das mensagens

O fluxo corrigido dos estados e:

1. `Digitada`: a mensagem foi criada localmente.
2. `Recebida`: o outro celular recebeu e enviou confirmacao `received`.
3. `Aberta`: o outro celular abriu a conversa e enviou confirmacao `opened`.

O estado so avanca; ele nao volta de `Aberta` para `Recebida`, por exemplo.

## Multiplos dispositivos

O app guarda os dispositivos conectados em mapas separados para Nearby e Wi-Fi Direct. A lista de conversas e criada a partir desses dispositivos, e cada mensagem fica vinculada a um `conversaId`.

Para demonstrar com 3 celulares:

1. Abra o app nos celulares A, B e C.
2. Conecte B ao A.
3. Conecte C ao A.
4. No A, confirme que aparecem duas conversas e o cabecalho informa `2 dispositivos conectados`.
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

## Observacao

A validacao automatica confirma a consistencia do codigo. A demonstracao final das atividades 2 e 4 precisa ser feita em celulares Android reais, porque Wi-Fi Direct e conexoes entre multiplos dispositivos dependem do hardware e do sistema Android.
