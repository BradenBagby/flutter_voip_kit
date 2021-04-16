import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_voip_kit/call.dart';
import 'package:flutter_voip_kit/call_manager.dart';

enum CallEndedReason { failed, remoteEnded, unanswered }
typedef Future<bool> CallStateChangeHandler(Call state);

class FlutterVoipKit {
  static CallStateChangeHandler?
      callStateChangeHandler; //handle call state changes and return if event is successful or not

  static const _methodChannelName = 'flutter_voip_kit';
  static const _callEventChannelName = "com.wavv.callEventChannel";
  static final callManager = CallManager();

  //methods
  static const _methodChannelStartCall = "flutter_voip_kit.startCall";
  static const _methodChannelReportIncomingCall =
      "flutter_voip_kit.reportIncomingCall";
  static const _methodChannelReportOutgoingCall =
      "flutter_voip_kit.reportOutgoingCall";
  static const _methodChannelReportCallEnded =
      "flutter_voip_kit.reportCallEnded";
  static const _methodChannelEndCall = "flutter_voip_kit.endCall";

  //events
  static const event_answerCall = "answerCall";
  static const event_endCall = "endCall";
  static const event_setHeld = "setHeld";
  static const event_reset = "reset";
  static const event_startCall = "startCall";

  static const MethodChannel _methodChannel =
      const MethodChannel(_methodChannelName);
  static const EventChannel _callEventChannel =
      const EventChannel(_callEventChannelName);

  static Future<bool> init() async {
    _callEventChannel.receiveBroadcastStream().listen((eventDataRaw) async {
      try {
        final eventData = Map<String, dynamic>.from(eventDataRaw);
        final event = eventData["event"] as String?;
        final uuid = eventData["uuid"] as String?;
        final handle = eventData["handle"] as String?;
        final call = callManager.getCallByUuid(uuid!);
        log("Received broadcast: $eventData");
        switch (event) {
          case event_answerCall:
            if (call != null) {
              if (!await callStateChangeHandler!(
                  call..callState = CallState.connecting)) {
                _callFailed(call);
              } else {
                if (!await callStateChangeHandler!(
                    call..callState = CallState.active)) {
                  _callFailed(call);
                }
              }
            }
            break;
          case event_endCall:
            if (call != null) {
              if (await callStateChangeHandler!(
                  call..callState = CallState.ended)) {
                callManager.removeCall(call);
              }
            }
            break;
          case event_startCall:
            final newCall =
                callManager.getCallByUuid(uuid)?.copyWith(address: handle) ??
                    Call(
                        address: handle!,
                        uuid: uuid,
                        outgoing: true,
                        callState: CallState.connecting);
            reportOutgoingCall(uuid: newCall.uuid, finishedConnecting: false);
            if (!await callStateChangeHandler!(
                newCall..callState = CallState.connecting)) {
              log("Failed to start call");
              _callFailed(newCall);
            } else {
              callManager.addCall(newCall);
              reportOutgoingCall(uuid: newCall.uuid, finishedConnecting: true);
              if (!await callStateChangeHandler!(
                  newCall..callState = CallState.active)) {
                await _callFailed(newCall);
              }
            }
            break;
          case event_reset:
            callManager.endAll();
            break;
          default:
            throw Exception("Unrecognized event");
        }
      } catch (er) {
        log("Error in callEventChannel: $er $eventDataRaw");
      }
    });

    return true; //TODO:
  }

  ///when call failes, report to native device, perform user's action, and remove if user's action returns true
  static Future<bool> _callFailed(Call call) async {
    await reportCallEnded(uuid: call.uuid, reason: CallEndedReason.failed);
    if (!await callStateChangeHandler!(call..callState = CallState.active)) {
      callManager.removeCall(call);
      return true;
    }
    return false;
  }

  //methods

  static Future<bool> startCall(String handle) async {
    final res = await _methodChannel
        .invokeMethod(_methodChannelStartCall, {"handle": handle});
    return res as bool;
  }

  static Future<bool> reportIncomingCall(
      {required String handle, required String uuid}) async {
    final res = await _methodChannel.invokeMethod(
      _methodChannelReportIncomingCall,
      {"uuid": uuid, "handle": handle},
    );
    if (res) {
      final call = Call(
          address: handle,
          uuid: uuid,
          outgoing: false,
          callState: CallState.incoming);
      callManager.addCall(call);
      await callStateChangeHandler!(call..callState = CallState.incoming);
    }
    return res as bool;
  }

  static Future<bool> reportOutgoingCall(
      {required String uuid, required bool finishedConnecting}) async {
    final res = await _methodChannel.invokeMethod(
        _methodChannelReportOutgoingCall,
        {"uuid": uuid, "finishedConnecting": finishedConnecting});
    return res as bool;
  }

  static Future<bool> reportCallEnded(
      {required String uuid, required CallEndedReason reason}) async {
    String r = reason
        .toString()
        .replaceFirst("CallEndedReason", ""); //better way to do this??
    final res = await _methodChannel.invokeMethod(
        _methodChannelReportCallEnded, {"uuid": uuid, "reason": r});
    return res as bool;
  }

  static Future<bool> endCall(Call call) async {
    if (await callStateChangeHandler!(call..callState = CallState.ended)) {
      final res = await _methodChannel
          .invokeMethod(_methodChannelEndCall, {"uuid": call.uuid});
      return res as bool;
    }
    return false;
  }
}
