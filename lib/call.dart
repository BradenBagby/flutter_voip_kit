import 'dart:convert';

import 'flutter_voip_kit.dart';

enum CallState { connecting, active, held, ended, failed, incoming }

///start a call with this callback. return if successful or not
typedef Future<bool> StartCallCallback();

class Call {
  final String uuid;
  final String address;
  final bool outgoing;

  CallState callState;

  //actions
  Future<bool> end() async {
    return FlutterVoipKit.endCall(this);
  }

  Future<bool> hold({bool onHold = true}) {
    return FlutterVoipKit.holdCall(this, onHold: onHold);
  }

  Future<bool> handleChangeState() {
    return FlutterVoipKit.callStateChangeHandler!(this);
  }

  Call({
    required this.uuid,
    required this.address,
    required this.outgoing,
    required this.callState,
  });

  Call copyWith(
      {String? uuid, String? address, bool? outgoing, CallState? callState}) {
    return Call(
        uuid: uuid ?? this.uuid,
        address: address ?? this.address,
        outgoing: outgoing ?? this.outgoing,
        callState: callState ?? this.callState);
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'address': address,
      'outgoing': outgoing,
      'callState': this.callState.index
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'Call(uuid: $uuid, address: $address, outgoing: $outgoing, state: $callState)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Call &&
        other.uuid == uuid &&
        other.address == address &&
        other.outgoing == outgoing &&
        other.callState == callState;
  }

  @override
  int get hashCode =>
      uuid.hashCode ^ address.hashCode ^ outgoing.hashCode ^ callState.hashCode;
}
