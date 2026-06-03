import 'dart:async';

import 'package:flutter/services.dart';

class WifiDirectDevice {
  const WifiDirectDevice({required this.id, required this.name});

  final String id;
  final String name;

  factory WifiDirectDevice.fromMap(Map<dynamic, dynamic> map) {
    return WifiDirectDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Wi-Fi Direct',
    );
  }
}

sealed class WifiDirectEvent {
  const WifiDirectEvent();
}

class WifiDirectPeersChanged extends WifiDirectEvent {
  const WifiDirectPeersChanged(this.devices);

  final List<WifiDirectDevice> devices;
}

class WifiDirectDiscoveryChanged extends WifiDirectEvent {
  const WifiDirectDiscoveryChanged(this.discovering);

  final bool discovering;
}

class WifiDirectConnected extends WifiDirectEvent {
  const WifiDirectConnected({required this.id, required this.name});

  final String id;
  final String name;
}

class WifiDirectDisconnected extends WifiDirectEvent {
  const WifiDirectDisconnected(this.id);

  final String id;
}

class WifiDirectMessageReceived extends WifiDirectEvent {
  const WifiDirectMessageReceived({
    required this.id,
    required this.name,
    required this.data,
  });

  final String id;
  final String name;
  final Uint8List data;
}

class WifiDirectError extends WifiDirectEvent {
  const WifiDirectError(this.message);

  final String message;
}

class WifiDirectService {
  WifiDirectService._();

  static const MethodChannel _channel = MethodChannel(
    'br.sp.gov.cps.dsm.chat/wifi_direct',
  );
  static final StreamController<WifiDirectEvent> _events =
      StreamController<WifiDirectEvent>.broadcast();
  static bool _initialized = false;

  static Stream<WifiDirectEvent> get events => _events.stream;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static Future<void> start({required String deviceName}) async {
    initialize();
    await _channel.invokeMethod<void>('start', {'deviceName': deviceName});
  }

  static Future<void> discover() async {
    initialize();
    await _channel.invokeMethod<void>('discover');
  }

  static Future<void> stopDiscovery() async {
    initialize();
    await _channel.invokeMethod<void>('stopDiscovery');
  }

  static Future<void> connect(String deviceId) async {
    initialize();
    await _channel.invokeMethod<void>('connect', {'deviceId': deviceId});
  }

  static Future<void> sendBytes(String deviceId, Uint8List data) async {
    initialize();
    await _channel.invokeMethod<void>('sendBytes', {
      'deviceId': deviceId,
      'data': data,
    });
  }

  static Future<void> stop() async {
    initialize();
    await _channel.invokeMethod<void>('stop');
  }

  static Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'peersChanged':
        final devices = (call.arguments as List<dynamic>? ?? [])
            .whereType<Map<dynamic, dynamic>>()
            .map(WifiDirectDevice.fromMap)
            .where((device) => device.id.isNotEmpty)
            .toList();
        _events.add(WifiDirectPeersChanged(devices));
      case 'discoveryChanged':
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        _events.add(
          WifiDirectDiscoveryChanged(args['discovering'] as bool? ?? false),
        );
      case 'connected':
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        if (id.isNotEmpty) {
          _events.add(
            WifiDirectConnected(
              id: id,
              name: args['name'] as String? ?? 'Wi-Fi Direct',
            ),
          );
        }
      case 'disconnected':
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        if (id.isNotEmpty) {
          _events.add(WifiDirectDisconnected(id));
        }
      case 'messageReceived':
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        final data = args['data'];
        if (id.isNotEmpty && data is Uint8List) {
          _events.add(
            WifiDirectMessageReceived(
              id: id,
              name: args['name'] as String? ?? 'Wi-Fi Direct',
              data: data,
            ),
          );
        }
      case 'error':
        final args = call.arguments as Map<dynamic, dynamic>? ?? {};
        _events.add(WifiDirectError(args['message'] as String? ?? 'Erro'));
    }
  }
}
