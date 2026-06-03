# Atividade 3 - Correcao dos estados das mensagens

## Objetivo da atividade

O enunciado pede para corrigir o controle e a exibicao dos estados das mensagens.

Os estados existentes sao:

- `Digitada`
- `Recebida`
- `Aberta`

O problema era que o app atualizava a mensagem para `Recebida` no aparelho remetente logo depois de chamar o envio local. Isso nao garantia que o outro celular realmente tinha recebido a mensagem.

Tambem havia um problema visual: o estado aparecia inclusive nas mensagens recebidas, fazendo a tela mostrar uma ordem confusa de estados.

## Regra correta adotada

A mensagem agora segue esta ordem:

1. `Digitada`: a mensagem foi criada no aparelho de quem enviou.
2. `Recebida`: o outro aparelho recebeu a mensagem e mandou uma confirmacao.
3. `Aberta`: o outro aparelho abriu a conversa e mandou uma confirmacao de abertura.

O estado nunca volta para tras. Por exemplo:

- `Aberta` nao pode voltar para `Recebida`.
- `Recebida` nao pode voltar para `Digitada`.

## Arquivos alterados

### 1. `shared/lib/src/message_packet.dart`

Foi adicionado um novo tipo de pacote:

```dart
received
```

Antes existiam apenas:

```dart
message
opened
```

Agora o protocolo consegue diferenciar:

- pacote de mensagem comum;
- confirmacao de recebimento;
- confirmacao de abertura.

Como explicar:

> Eu adicionei um pacote `received` ao protocolo para que o aparelho destinatario consiga avisar ao remetente que a mensagem realmente chegou.

### 2. `shared/lib/src/message_protocol.dart`

Foi adicionada a funcao:

```dart
MessageProtocol.encodeReceived(...)
```

Tambem foi alterada a decodificacao para reconhecer JSON com:

```json
{"type":"received","id":"..."}
```

Como explicar:

> O protocolo agora tem dois tipos de confirmacao: `received`, para mensagem recebida, e `opened`, para mensagem aberta.

### 3. `app/lib/features/connection/data/message_protocol.dart`

Foi adicionada a codificacao da confirmacao de recebimento:

```dart
_codificarConfirmacaoRecebimento(...)
```

Tambem foi alterado o processamento de pacotes recebidos:

- Se chegar pacote `received`, atualiza a mensagem local para `Recebida`.
- Se chegar pacote `opened`, atualiza a mensagem local para `Aberta`.
- Se chegar uma mensagem comum, o aparelho destinatario salva a mensagem e envia confirmacao de recebimento.
- Se a conversa ja estiver aberta, ele tambem envia confirmacao de abertura.

Como explicar:

> Quando um celular recebe uma mensagem, ele nao fica calado. Ele manda uma resposta de controle dizendo "recebi". Se a conversa estiver aberta, ele manda depois outra resposta dizendo "abri".

### 4. `app/lib/features/connection/connection_screen.dart`

Foi corrigido o controle dos estados.

Antes, ao enviar uma mensagem, o app fazia isso:

```dart
await _enviarBytes(conversa, bytes);
_atualizarStatusMensagem(mensagemId, MessageStatus.recebida);
```

Isso estava errado porque o status virava `Recebida` apenas porque o envio local terminou.

Agora, depois de enviar os bytes, a mensagem continua `Digitada` ate chegar a confirmacao `received` do outro aparelho.

Tambem foi adicionada uma protecao em `_atualizarStatusMensagem`:

```dart
if (mensagemAtual.status.index >= status.index) return;
```

Isso impede que o estado volte para tras.

Tambem foram adicionadas as funcoes:

```dart
_enviarConfirmacaoRecebimento(...)
_confirmarEstadoRemoto(...)
```

Elas garantem que o outro aparelho receba as confirmacoes na ordem correta:

1. primeiro `Recebida`;
2. depois `Aberta`, se a conversa estiver aberta.

Como explicar:

> O remetente nao decide sozinho que a mensagem foi recebida. Ele espera uma confirmacao enviada pelo destinatario. Alem disso, o codigo impede regressao de estado.

### 5. `app/lib/features/connection/widgets/connection_widgets.dart`

Foi corrigida a exibicao dos estados na tela.

Antes, todas as bolhas de mensagem mostravam status.

Agora, o status aparece somente nas mensagens enviadas por mim:

```dart
if (mensagem.enviadaPorMim) ...
```

Motivo:

O status `Digitada`, `Recebida` e `Aberta` e uma informacao importante para quem enviou a mensagem. Nas mensagens recebidas, mostrar esse estado confunde a leitura e passa a impressao de ordem errada.

Como explicar:

> A tela agora mostra estado apenas nas mensagens que eu enviei, porque e nelas que faz sentido acompanhar se o outro celular recebeu ou abriu.

### 6. `app/test/widget_test.dart`

Foram adicionados testes simples para validar:

- se o protocolo reconhece a confirmacao `received`;
- se a ordem dos estados continua `Digitada -> Recebida -> Aberta`.

## O que foi removido nesta atividade

Foi removida a atualizacao imediata para `Recebida` logo depois do envio local.

Antes:

```dart
await _enviarBytes(conversa, bytes);
_atualizarStatusMensagem(mensagemId, MessageStatus.recebida);
```

Agora:

```dart
await _enviarBytes(conversa, bytes);
```

Tambem foi removida a atualizacao imediata para `Recebida` no reenvio de mensagens pendentes. As mensagens reenviadas tambem precisam aguardar a confirmacao do outro aparelho.

## Fluxo final dos estados

### Caso 1: conversa fechada no destino

1. Usuario A envia mensagem.
2. No celular A, a mensagem aparece como `Digitada`.
3. Celular B recebe a mensagem.
4. Celular B envia confirmacao `received`.
5. Celular A atualiza a mensagem para `Recebida`.

### Caso 2: conversa aberta no destino

1. Usuario A envia mensagem.
2. No celular A, a mensagem aparece como `Digitada`.
3. Celular B recebe a mensagem.
4. Celular B envia confirmacao `received`.
5. Celular A atualiza a mensagem para `Recebida`.
6. Como a conversa esta aberta no celular B, ele envia confirmacao `opened`.
7. Celular A atualiza a mensagem para `Aberta`.

## Como demonstrar para o professor

Use dois celulares.

Passo a passo sugerido:

1. Conecte os dois celulares pelo app.
2. No celular B, deixe a conversa fechada ou volte para a lista.
3. No celular A, envie uma mensagem.
4. Mostre que a mensagem primeiro nasce como `Digitada`.
5. Quando o celular B recebe, o celular A muda para `Recebida`.
6. Abra a conversa no celular B.
7. Mostre que no celular A a mensagem muda para `Aberta`.
8. Mostre tambem que mensagens recebidas no celular B nao exibem o rotulo de estado na bolha.

Frase curta para apresentar:

> Eu corrigi os estados para serem controlados por confirmacoes reais entre os aparelhos. A mensagem so vira `Recebida` quando o destinatario confirma o recebimento, e so vira `Aberta` quando o destinatario abre a conversa. Na interface, o estado aparece apenas nas mensagens enviadas por mim.

## Validacao feita

Comandos executados:

```powershell
dart format
flutter analyze
flutter test
dart analyze
```

Resultado:

- Arquivos Dart formatados.
- `flutter analyze`: sem problemas encontrados no app.
- `flutter test`: todos os testes passaram.
- `dart analyze`: sem problemas encontrados no pacote `shared`.

