# Atividade 4 - Funcionamento com multiplos dispositivos

## Objetivo da atividade

O enunciado pede que o aplicativo funcione e troque mensagens com pelo menos 3 celulares.

Nesta etapa, o foco nao e criar um novo transporte, mas garantir que o fluxo de conexao continue funcionando quando existe mais de um celular conectado ao mesmo tempo.

## Situacao do codigo antes

O app ja tinha uma estrutura boa para multiplos dispositivos:

- `_aparelhosConectados`: guarda varios celulares conectados pelo Nearby.
- `_wifiDirectConectados`: guarda varios celulares conectados pelo Wi-Fi Direct.
- `_conversas`: monta a lista de conversas a partir desses mapas.
- Cada mensagem usa `conversaId`, entao o historico de um celular nao se mistura com o de outro.

Mesmo assim, havia dois pontos que poderiam atrapalhar a demonstracao com 3 celulares:

1. Depois de conectar um celular pelo Nearby, o app podia ficar sem anunciar novamente imediatamente.
2. A tela nao mostrava claramente quantos dispositivos estavam conectados.

## Arquivos alterados

### 1. `app/lib/features/connection/connection_screen.dart`

Foram feitos ajustes pequenos no fluxo de multiplos dispositivos.

#### A. Evitar mostrar aparelho ja conectado na busca

Na descoberta Nearby, foi adicionada uma verificacao:

```dart
if (_aparelhosConectados.containsKey(id)) return;
```

Isso impede que um celular que ja esta conectado apareca novamente na lista de busca.

Como explicar:

> Se um celular ja esta conectado, ele nao precisa aparecer de novo como opcao de conexao. Isso evita tentativa duplicada e deixa a busca mais limpa.

#### B. Remover aparelho encontrado quando ele conecta

Quando a conexao e concluida, o aparelho e removido da lista de encontrados:

```dart
_aparelhosEncontrados.removeWhere((item) => item.id == id);
```

Como explicar:

> Depois que um aparelho entra na lista de conversas, ele sai da lista de busca.

#### C. Manter o app disponivel para outros celulares

Depois que uma conexao Nearby e confirmada, o app chama:

```dart
unawaited(_garantirDisponibilidade());
```

Isso faz o app voltar a anunciar automaticamente, permitindo que um terceiro celular encontre e conecte.

Tambem foi chamada a mesma funcao quando um aparelho desconecta, para o app continuar disponivel.

Como explicar:

> Para funcionar com 3 celulares, o primeiro celular nao pode parar de ficar disponivel depois que conecta com o segundo. Ele precisa continuar anunciando para o terceiro tambem conseguir encontrar.

#### D. Contagem de dispositivos conectados

Foi criado o getter:

```dart
int get _totalDispositivosConectados =>
    _aparelhosConectados.length + _wifiDirectConectados.length;
```

Ele soma conexoes Nearby e Wi-Fi Direct.

Como explicar:

> A tela passa a saber quantos dispositivos estao conectados, considerando os dois transportes implementados no app.

### 2. `app/lib/features/connection/widgets/connection_widgets.dart`

Foi alterada a lista de conversas para receber:

```dart
totalConectados
```

Quando existem conversas, a tela mostra um cabecalho:

```text
3 dispositivos conectados
```

ou:

```text
1 dispositivo conectado
```

Como explicar:

> Esse cabecalho ajuda na demonstracao da Atividade 4, porque fica visivel na tela quantos celulares estao conectados ao aplicativo.

## Como o app trabalha com 3 celulares

Exemplo com celulares A, B e C:

1. Celular A abre o app e fica disponivel.
2. Celular B busca celulares e conecta no A.
3. Depois da conexao, o A volta a anunciar automaticamente.
4. Celular C busca celulares e tambem conecta no A.
5. No celular A, a lista mostra duas conversas:
   - conversa com B;
   - conversa com C.
6. No cabecalho aparece:

```text
2 dispositivos conectados
```

Isso representa 3 celulares participando do teste: A, B e C.

## Troca de mensagens

Cada conversa continua separada por `conversaId`.

Quando A envia mensagem para B:

- a mensagem fica vinculada a conversa com B;
- C nao recebe essa mensagem.

Quando A envia mensagem para C:

- a mensagem fica vinculada a conversa com C;
- B nao recebe essa mensagem.

Como explicar:

> O app suporta multiplos dispositivos mantendo uma conversa independente para cada celular conectado. Assim, com 3 celulares, o aparelho central consegue alternar entre as conversas e trocar mensagens separadamente.

## Como demonstrar para o professor

Use 3 celulares Android reais.

Passo a passo sugerido:

1. Instale e abra o app nos 3 celulares.
2. De nomes diferentes aos aparelhos, por exemplo:
   - Celular A
   - Celular B
   - Celular C
3. No A, deixe o app aberto e disponivel.
4. No B, use `Buscar celulares` e conecte no A.
5. Volte para a lista no A e confirme que aparece uma conversa.
6. No C, use `Buscar celulares` e conecte no A.
7. No A, mostre que existem duas conversas e que o cabecalho informa `2 dispositivos conectados`.
8. Envie uma mensagem de A para B.
9. Envie uma mensagem de A para C.
10. Responda de B para A.
11. Responda de C para A.

Frase curta para apresentar:

> O aplicativo agora mantem uma lista de dispositivos conectados e continua anunciando depois de uma conexao, permitindo que outros celulares tambem conectem. Cada celular conectado aparece como uma conversa separada, e as mensagens sao filtradas pelo `conversaId`.

## Validacao feita

Comandos executados:

```powershell
dart format
flutter analyze
flutter test
```

Resultado:

- Arquivos Dart formatados.
- `flutter analyze`: sem problemas encontrados.
- `flutter test`: todos os testes passaram.

Observacao:

A validacao automatica confirma que o codigo esta consistente. A comprovacao do requisito precisa ser feita com 3 celulares Android reais, porque a avaliacao pede demonstrar o aplicativo funcionando entre dispositivos fisicos.

