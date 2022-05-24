import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:flutter_voip_kit/call.dart';
import 'package:flutter_voip_kit/call_manager.dart';

enum CallEndedReason { failed, remoteEnded, unanswered }
typedef Future<bool> CallStateChangeHandler(Call call);
typedef Future<bool> CallActionHandler(Call call, CallAction action);

class FlutterVoipKit {
  //public

  ///list of current active calls
  static Stream<List<Call>> get callListStream =>
      CallManager.callListStreamController.stream;

  ///handle call state changes and return if event is successful or not
  ///The most important setup of flutter_voip_kit
  ///If all states are not accounted for, your calls may not work
  ///for example: When a call becomes CallState.Connecting your VOIP service should perform the connection for that call and return true/false on success
  ///
  ///See example for more details
  static CallStateChangeHandler? callStateChangeHandler;

  /// handle call action requests and return if event is successful or not
  /// similar to callStateChangeHandler, but handles any action that is not a call state change
  /// See CallAction enum for list of actions
  ///
  /// see example for more details
  static CallActionHandler? callActionHandler;

  static const _methodChannelName = 'flutter_voip_kit';
  static const _callEventChannelName = "flutter_voip_kit.callEventChannel";
  static final _callManager = CallManager();

  //methods
  static const _methodChannelStartCall = "flutter_voip_kit.startCall";
  static const _methodChannelReportIncomingCall =
      "flutter_voip_kit.reportIncomingCall";
  static const _methodChannelReportOutgoingCall =
      "flutter_voip_kit.reportOutgoingCall";
  static const _methodChannelReportCallEnded =
      "flutter_voip_kit.reportCallEnded";
  static const _methodChannelEndCall = "flutter_voip_kit.endCall";
  static const _methodChannelHoldCall = "flutter_voip_kit.holdCall";
  static const _methodChannelCheckPermissions =
      "flutter_voip_kit.checkPermissions";
  static const _methodChannelMuteCall = "flutter_voip_kit.muteCall";

  //events
  static const event_answerCall = "answerCall";
  static const event_endCall = "endCall";
  static const event_setHeld = "setHeld";
  static const event_reset = "reset";
  static const event_startCall = "startCall";
  static const event_setMuted = "setMuted";

  static const MethodChannel _methodChannel =
      const MethodChannel(_methodChannelName);
  static const EventChannel _callEventChannel =
      const EventChannel(_callEventChannelName);

  static Future<void> init(
      {required CallStateChangeHandler callStateChangeHandler,
      required CallActionHandler callActionHandler}) async {
    if (kIsWeb) {
      return;
    }
    FlutterVoipKit.callStateChangeHandler = callStateChangeHandler;
    FlutterVoipKit.callActionHandler = callActionHandler;

    ///listen to event channel for device updates on call states
    _callEventChannel.receiveBroadcastStream().listen((eventDataRaw) async {
      try {
        final eventData = Map<String, dynamic>.from(eventDataRaw);
        final event = eventData["event"] as String?;
        log("Received broadcast: $eventData");
        switch (event) {
          case event_answerCall:
            _answerCall(eventData);
            break;
          case event_endCall:
            _endCall(eventData);
            break;
          case event_startCall:
            _startCall(eventData);
            break;
          case event_setHeld:
            _setHeld(eventData);
            break;
          case event_setMuted:
            _setMuted(eventData);
            break;
          case event_reset:
            _callManager.endAll();
            break;
          case "test":
            log("TEST");
            break;
          default:
            throw Exception("Unrecognized event");
        }
      } catch (er) {
        log("Error in callEventChannel: $er $eventDataRaw");
      }
    });
  }

  // MARK: public methods

  ///start call initiated from user
  static Future<bool> startCall(String handle, {String? uuid}) async {
    Map<String, String> payload = {"handle": handle};
    if (uuid != null) {
      payload['uuid'] = uuid;
    }
    final res =
        await _methodChannel.invokeMethod(_methodChannelStartCall, payload);
    return res as bool;
  }

  ///check if device can handle making calls
  ///
  ///`openSettings` - whether to auto open device settings on permission failure
  ///'`performRequest` - whether or not to show the native permission request if no permissions
  static Future<bool> checkPermissions(
      {bool openSettings = false, bool performRequest = true}) async {
    if (kIsWeb) {
      return false;
    }
    final res = await _methodChannel.invokeMethod(
        _methodChannelCheckPermissions,
        {"openSettings": openSettings, "performRequest": performRequest});
    return res as bool;
  }

  ///report incoming call from notification
  ///This will happen when you're flutter app receives notification on an incoming call and needs to report it to the native OS
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
      _callManager.addCall(call);
      await callStateChangeHandler!(call..callState = CallState.incoming);
    }
    return res as bool;
  }

  ///end call initiated by user. Also could call Call.end()
  static Future<bool> endCall(String uuid) async {
    final res = await _methodChannel
        .invokeMethod(_methodChannelEndCall, {"uuid": uuid});
    return res as bool;
  }

  ///hold call initiated by user. Also could call Call.hold()
  static Future<bool> holdCall(String uuid, {bool onHold = true}) async {
    final res = await _methodChannel
        .invokeMethod(_methodChannelHoldCall, {"uuid": uuid, "hold": onHold});
    return res as bool;
  }

  ///mute call initiated by user. Also could call Call.mute
  static Future<bool> muteCall(String uuid, {bool muted = true}) async {
    final res = await _methodChannel
        .invokeMethod(_methodChannelMuteCall, {"uuid": uuid, "muted": muted});
    return res as bool;
  }

  //private methods
  static void _answerCall(Map<String, dynamic> eventData) async {
    final uuid = eventData["uuid"] as String?;
    final call = _callManager.getCallByUuid(uuid!);
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
  }

  static void _endCall(Map<String, dynamic> eventData) async {
    final uuid = eventData["uuid"] as String?;
    final call = _callManager.getCallByUuid(uuid!);
    if (call != null) {
      if (await callStateChangeHandler!(call..callState = CallState.ended)) {
        _callManager.removeCall(call);
      }
    }
  }

  static void _startCall(Map<String, dynamic> eventData) async {
    final uuid = eventData["uuid"] as String;
    final handle = eventData["args"] as String?;
    final newCall =
        _callManager.getCallByUuid(uuid)?.copyWith(address: handle) ??
            Call(
                address: handle!,
                uuid: uuid,
                outgoing: true,
                callState: CallState.connecting);
    _reportOutgoingCall(uuid: newCall.uuid, finishedConnecting: false);
    if (!await callStateChangeHandler!(
        newCall..callState = CallState.connecting)) {
      log("Failed to start call");
      _callFailed(newCall);
    } else {
      _callManager.addCall(newCall);

      //failed to report to os that the call has connected likely means os failed the call early
      if (!await _reportOutgoingCall(
          uuid: newCall.uuid, finishedConnecting: true)) {
        log("Failed to report outgoing call as connected so we are failing the call");
        _callFailed(newCall);
      }
      if (!await callStateChangeHandler!(
          newCall..callState = CallState.active)) {
        await _callFailed(newCall);
      }
    }
  }

  static void _setHeld(Map<String, dynamic> eventData) async {
    final uuid = eventData["uuid"] as String;
    final onHold = eventData["args"] as bool;
    final call = _callManager.getCallByUuid(uuid);
    if (call != null) {
      if (!await callStateChangeHandler!(
          call..callState = onHold ? CallState.held : CallState.active)) {
        log("Failed to set hold for call. Failing");
        _callFailed(call);
      }
    }
  }

  static void _setMuted(Map<String, dynamic> eventData) async {
    final uuid = eventData["uuid"] as String;
    final muted = eventData["args"] as bool;
    final call = _callManager.getCallByUuid(uuid);
    if (call != null) {
      if (!await callActionHandler!(call..muted = muted, CallAction.muted)) {
        log("Failed to set muted for call");
        // for now we just fail the call. Would be nice to revert call to muted state of the system but wed have to write special case in order to dodge the infinite loop it would cause
        _callFailed(call);
      }
    }
  }

  static Future<bool> _reportCallEnded(
      {required String uuid, required CallEndedReason reason}) async {
    String r = reason
        .toString()
        .replaceFirst("CallEndedReason.", ""); //better way to do this??
    final res = await _methodChannel.invokeMethod(
        _methodChannelReportCallEnded, {"uuid": uuid, "reason": r});
    return res as bool;
  }

  static Future<bool> _reportOutgoingCall(
      {required String uuid, required bool finishedConnecting}) async {
    final res = await _methodChannel.invokeMethod(
        _methodChannelReportOutgoingCall,
        {"uuid": uuid, "finishedConnecting": finishedConnecting});
    return res as bool;
  }

  ///when call failes, report to native device, perform user's action, and remove if user's action returns true
  static Future<bool> _callFailed(Call call) async {
    await _reportCallEnded(uuid: call.uuid, reason: CallEndedReason.failed);
    if (await callStateChangeHandler!(call..callState = CallState.failed)) {
      _callManager.removeCall(call);
      return true;
    }
    return false;
  }
}
