import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_voip_kit/call.dart';

class FlutterVoipKit {
  static const _methodChannelName = 'flutter_voip_kit';
  static const _callEventChannelName = "com.wavv.callEventChannel";

  //methods
  static const _methodChannelStartCall = "flutter_voip_kit.startCall";

  static const MethodChannel _methodChannel =
      const MethodChannel(_methodChannelName);
  static const EventChannel _callEventChannel =
      const EventChannel(_callEventChannelName);

  static Stream<String?> get callEventStream => _callEventChannel
      .receiveBroadcastStream()
      .map((event) => event as String);

  //methods

  static Future<bool> startCall(String handle) async {
    final res = await _methodChannel.invokeMethod(_methodChannelStartCall);
    return res as bool;
  }
}
