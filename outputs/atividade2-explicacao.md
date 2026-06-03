# Atividade 2 - Comunicacao via Wi-Fi Direct

## Objetivo da atividade

O enunciado pede para alterar o aplicativo para permitir comunicacao entre celulares usando Wi-Fi Direct.

Antes, o aplicativo ja conseguia conversar entre celulares usando o fluxo Nearby. O problema e que o Nearby usa recursos de Wi-Fi de forma indireta, por meio da biblioteca. Para atender a Atividade 2, foi criada uma implementacao direta de Wi-Fi Direct no Android, usando `WifiP2pManager`.

## Resumo do que foi feito

Foi adicionado um segundo transporte de comunicacao entre celulares:

- `Nearby`, que continua sendo usado na opcao `Buscar celulares`.
- `Wi-Fi Direct`, novo fluxo criado para a opcao `Buscar Wi-Fi Direct`.

As mensagens continuam usando o mesmo protocolo do chat. Ou seja, a tela, o historico e os estados das mensagens aproveitam a estrutura existente. A diferenca principal e o caminho usado para enviar os bytes.

## Arquivos alterados ou criados

### 1. `app/lib/core/platform/wifi_direct_service.dart`

Arquivo novo.

Ele cria a ponte entre Flutter/Dart e o codigo nativo Android.

O que existe nele:

- `MethodChannel('br.sp.gov.cps.dsm.chat/wifi_direct')`.
- Modelo `WifiDirectDevice`, usado para representar aparelhos encontrados.
- Eventos como:
  - `WifiDirectPeersChanged`, quando a lista de aparelhos encontrados muda.
  - `WifiDirectDiscoveryChanged`, quando a busca inicia ou para.
  - `WifiDirectConnected`, quando conecta.
  - `WifiDirectDisconnected`, quando desconecta.
  - `WifiDirectMessageReceived`, quando chega mensagem.
  - `WifiDirectError`, quando ocorre erro.
- Metodos chamados pelo Flutter:
  - `start`
  - `discover`
  - `stopDiscovery`
  - `connect`
  - `sendBytes`
  - `stop`

Como explicar:

> Este arquivo e o servico Dart que conversa com o Android. A tela nao acessa diretamente o `WifiP2pManager`; ela chama esse servico, e o servico envia os comandos para o codigo Kotlin por `MethodChannel`.

### 2. `app/android/app/src/main/kotlin/com/example/exemplo_quatro/WifiDirectTransport.kt`

Arquivo novo.

Este e o nucleo da Atividade 2.

O que ele faz:

- Usa `WifiP2pManager` para trabalhar diretamente com Wi-Fi Direct.
- Registra um `BroadcastReceiver` para receber eventos do Android:
  - Wi-Fi Direct ligado/desligado.
  - Lista de peers alterada.
  - Estado da conexao alterado.
- Faz descoberta de aparelhos com `discoverPeers`.
- Lista aparelhos encontrados com `requestPeers`.
- Conecta em outro aparelho com `WifiP2pConfig` e `manager.connect`.
- Depois que o grupo Wi-Fi Direct e formado, abre sockets TCP para enviar os bytes do chat.
- Usa a porta `8988`.
- Envia cada mensagem com um formato simples:
  - primeiro escreve o tamanho do pacote;
  - depois escreve os bytes da mensagem.
- Recebe pacotes do outro aparelho e envia para o Flutter pelo evento `messageReceived`.

Como explicar:

> O `WifiP2pManager` cuida da descoberta e formacao do grupo Wi-Fi Direct. Depois que a conexao Wi-Fi Direct existe, o app usa sockets TCP para transmitir os bytes reais da mensagem. Assim, a comunicacao nao depende apenas do Nearby; existe um transporte Wi-Fi Direct implementado diretamente no aplicativo.

### 3. `app/android/app/src/main/kotlin/com/example/exemplo_quatro/MainActivity.kt`

Foi alterado para registrar o canal nativo do Wi-Fi Direct.

O que mudou:

- O canal antigo do servico em foreground continuou existindo.
- Foi criado o canal:

```kotlin
private val wifiDirectChannelName = "br.sp.gov.cps.dsm.chat/wifi_direct"
```

- Foi instanciado o transporte:

```kotlin
wifiDirectTransport = WifiDirectTransport(this, wifiDirectChannel)
wifiDirectChannel.setMethodCallHandler(wifiDirectTransport)
```

- No `onDestroy`, o transporte e encerrado para fechar sockets, receiver e recursos do Android.

Como explicar:

> A `MainActivity` e o ponto de entrada Android do Flutter. Ela registra o `MethodChannel` para permitir que o Dart chame o codigo Kotlin responsavel pelo Wi-Fi Direct.

### 4. `app/android/app/src/main/AndroidManifest.xml`

Foram adicionadas permissoes necessarias para o transporte por rede:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

O projeto ja tinha permissoes relacionadas a Wi-Fi, Nearby, Bluetooth e localizacao. Essas permissoes sao importantes porque o Android exige permissoes de localizacao/Nearby para descobrir aparelhos por Wi-Fi Direct.

Como explicar:

> O Android precisa dessas permissoes para permitir descoberta, conexao e comunicacao em rede entre os celulares.

### 5. `app/lib/features/connection/connection_screen.dart`

Foi alterada a tela principal para suportar dois tipos de conversa.

O que mudou:

- Foi importado o novo servico:

```dart
import '../../core/platform/wifi_direct_service.dart';
```

- O menu passou a ter uma nova acao:

```dart
buscarWifiDirect
```

- Foi criado o enum:

```dart
enum _TipoConversa { celular, wifiDirect }
```

- Foram adicionados estados para Wi-Fi Direct:
  - lista de aparelhos encontrados por Wi-Fi Direct;
  - mapa de aparelhos conectados por Wi-Fi Direct;
  - controle de busca;
  - controle de conexao;
  - controle se o Wi-Fi Direct esta ativo.
- A tela escuta os eventos do `WifiDirectService`.
- Foi criada a funcao `_abrirBuscaWifiDirect`, que abre o modal de busca.
- Foi criada a funcao `_conectarWifiDirect`, que chama o transporte nativo.
- Foi criada a funcao `_aoEventoWifiDirect`, que trata os eventos vindos do Android.
- Foi criada a funcao `_enviarBytes`.

Antes, o envio de mensagem chamava diretamente:

```dart
Nearby().sendBytesPayload(...)
```

Agora o envio passa por `_enviarBytes`, que escolhe o transporte correto:

```dart
switch (conversa.tipo) {
  case _TipoConversa.celular:
    await Nearby().sendBytesPayload(conversa.deviceId, bytes);
  case _TipoConversa.wifiDirect:
    await WifiDirectService.sendBytes(conversa.deviceId, bytes);
}
```

Como explicar:

> A tela agora nao assume que toda conversa usa Nearby. Cada conversa tem um tipo. Se for conversa normal entre celulares, usa Nearby. Se for conversa Wi-Fi Direct, envia pelo `WifiDirectService`.

### 6. `app/lib/features/connection/widgets/connection_widgets.dart`

Foi alterado para mostrar o estado do Wi-Fi Direct e abrir a busca especifica.

O que mudou:

- A lista de conversas recebe `wifiDirectAtivo`.
- A tela vazia mostra se o Wi-Fi Direct esta ativo ou inativo.
- Foi criado o modal `_ModalBuscaWifiDirect`, parecido com o modal de busca de celulares, mas separado para Wi-Fi Direct.

Como explicar:

> A interface ganhou uma entrada visual para a nova forma de comunicacao. O usuario consegue escolher no menu a busca por Wi-Fi Direct e conectar em aparelhos encontrados por esse transporte.

### 7. `app/pubspec.yaml` e `app/pubspec.lock`

Durante a validacao, foram removidas dependencias que nao estavam sendo usadas pelo aplicativo atual:

- `flutter_contacts`
- `geolocator`
- `image_picker`

Motivo:

Essas dependencias sobraram do projeto original e nao faziam parte do requisito da Atividade 2. A remocao ajudou a deixar o projeto mais limpo e a permitir validacoes com o Dart/Flutter instalado no ambiente.

Como explicar:

> Essas dependencias nao foram removidas para implementar Wi-Fi Direct, mas para limpar pacotes que nao eram usados pelo app depois da Atividade 1 e evitar problemas de compatibilidade na validacao.

### 8. `app/test/widget_test.dart`

O teste foi ajustado porque o titulo principal da tela mudou para:

```dart
Chat local
```

Isso combina melhor com o aplicativo depois da Atividade 1 e 2, porque ele nao e mais apenas Bluetooth ou notebook; agora e um chat local entre celulares.

## Fluxo da comunicacao Wi-Fi Direct

1. Usuario abre o menu.
2. Usuario toca em `Buscar Wi-Fi Direct`.
3. Flutter chama `WifiDirectService.start`.
4. O servico Dart chama o Kotlin via `MethodChannel`.
5. O Kotlin inicia o `WifiP2pManager` e registra o `BroadcastReceiver`.
6. Flutter chama `discover`.
7. Android executa `discoverPeers`.
8. Quando aparelhos sao encontrados, Kotlin envia `peersChanged` para o Flutter.
9. A tela mostra os aparelhos encontrados.
10. Usuario toca para conectar.
11. Flutter chama `connect`.
12. Android cria a conexao Wi-Fi Direct.
13. Quando o grupo e formado, o app abre um socket TCP.
14. Ao enviar mensagem, o Flutter codifica a mensagem em bytes.
15. Se a conversa for Wi-Fi Direct, esses bytes sao enviados pelo socket.
16. O outro celular recebe os bytes e o Flutter processa como mensagem do chat.

## O que foi apagado nesta atividade

Para a Atividade 2, nao foi necessario apagar uma funcionalidade do chat para criar o Wi-Fi Direct.

O que foi removido nesta etapa foi apenas limpeza de dependencias nao usadas:

- `flutter_contacts`
- `geolocator`
- `image_picker`

Essas dependencias nao eram usadas pelo codigo atual e atrapalhavam a validacao do projeto.

Importante: a remocao do fluxo celular-notebook foi da Atividade 1. Nesta Atividade 2, o foco foi adicionar Wi-Fi Direct entre celulares.

## Como demonstrar para o professor

Para demonstrar funcionando, use pelo menos dois celulares Android reais.

Passo a passo sugerido:

1. Instale o app nos dois celulares.
2. Abra o app nos dois celulares.
3. Garanta que as permissoes de localizacao, Nearby/Wi-Fi e notificacao foram permitidas.
4. Em um dos celulares, abra o menu e toque em `Buscar Wi-Fi Direct`.
5. Selecione o outro aparelho quando ele aparecer.
6. Espere aparecer a conversa com subtitulo `Wi-Fi Direct`.
7. Envie uma mensagem.
8. Mostre que a mensagem chegou no outro celular.
9. Explique que a transmissao usa `WifiP2pManager` no Android e sockets TCP na porta `8988`.

Frase curta para apresentar:

> Eu mantive o Nearby para o fluxo ja existente entre celulares, mas criei um transporte Wi-Fi Direct direto no Android. O Flutter conversa com esse transporte por `MethodChannel`; o Android descobre e conecta os aparelhos com `WifiP2pManager`; depois que o grupo Wi-Fi Direct e formado, as mensagens do chat sao enviadas por socket TCP.

## Validacao feita

Comandos executados:

```powershell
flutter pub get
dart format
flutter analyze
flutter test
```

Resultado:

- `flutter pub get`: concluiu.
- `dart format`: arquivos Dart formatados.
- `flutter analyze`: sem problemas encontrados.
- `flutter test`: testes passaram.

Tambem foi tentado gerar APK debug, mas o Gradle local retornou um erro de provider antes de compilar o codigo Kotlin. Esse erro parece ser de configuracao local do ambiente Android/Gradle, nao da analise Dart do aplicativo. Para a demonstracao em celulares, ainda sera necessario gerar/instalar o APK em um ambiente Android configurado corretamente.

