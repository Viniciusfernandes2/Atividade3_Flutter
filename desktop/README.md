# Connection Desktop

Aplicativo Flutter desktop para chat Bluetooth usando BLE pelo Bluetooth do notebook.

## Importante

O app em `../app` usa `nearby_connections`, que implementa Google Nearby Connections. O `serviceId` `br.sp.gov.cps.dsm.chat` desse pacote nao e um UUID BLE/GATT padrao. Por isso, um aplicativo desktop BLE comum nao descobre automaticamente o app Android atual.

Este projeto usa um UUID BLE derivado do mesmo identificador:

- ServiceId logico: `br.sp.gov.cps.dsm.chat`
- Service UUID BLE: `07eab2e6-fc51-5e32-a09b-788f502b8ed7`
- Caracteristica de escrita: `6dff0753-7a8e-57d7-9858-f4f4c781cb81`
- Caracteristica de notificacao: `8bc8e5cf-54eb-59ff-a05d-f94177f07f8d`

Para conversar com o app mobile, o app mobile tambem precisa expor/consumir esse servico BLE, ou o desktop precisa de uma implementacao nativa do protocolo Nearby Connections.

## Pre-requisitos no Windows

Para compilar e executar o app Flutter desktop no Windows, instale o Visual Studio com suporte a C++:

- Visual Studio 2022 Community, Professional ou Enterprise.
- Workload `Desktop development with C++`.
- Componentes de CMake e Windows SDK selecionados pelo instalador.

Depois da instalacao, confirme com:

```bash
flutter doctor
```

O Flutter deve reconhecer o Visual Studio antes de `flutter run -d windows` funcionar.

## Como preparar

Dentro desta pasta:

```bash
flutter create . --platforms=windows
flutter pub get
flutter run -d windows
```

Para Linux ou macOS, troque `windows` por `linux` ou `macos`, desde que o ambiente esteja configurado.
