import 'dart:convert';

import 'flutter_voip_kit.dart';

enum CallState { connecting, active, held, ended, failed, incoming }

//when we update a call's action, we need to verify it completes successfully
enum CallAction { muted }

///Call object represents a call going on with the users device
class Call {
  /// UUID of call
  final String uuid;

  /// address or handle of the call
  final String address;

  /// outgoing is true if call is initiated by the user
  final bool outgoing;

  /// metadata on the call
  final Map<String, dynamic> metadata;

  ///current state of call
  CallState callState;
  bool muted = false;

  //actions

  ///End the call initiated by the user
  Future<bool> end() async {
    return FlutterVoipKit.endCall(this.uuid);
  }

  ///hold the call initiated by the user
  Future<bool> hold({bool onHold = true}) {
    return FlutterVoipKit.holdCall(this.uuid, onHold: onHold);
  }

  ///mute the call initiated by the user
  Future<bool> mute({bool muted = true}) {
    return FlutterVoipKit.muteCall(this.uuid, muted: muted);
  }

  Call(
      {required this.uuid,
      required this.address,
      required this.outgoing,
      required this.callState,
      this.metadata = const {}});

  Call copyWith(
      {String? uuid,
      String? address,
      bool? outgoing,
      CallState? callState,
      Map<String, dynamic>? metadata}) {
    return Call(
        uuid: uuid ?? this.uuid,
        address: address ?? this.address,
        outgoing: outgoing ?? this.outgoing,
        callState: callState ?? this.callState,
        metadata: metadata ?? this.metadata);
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'address': address,
      'outgoing': outgoing,
      'callState': this.callState.index,
      'muted': muted,
      'metadata': metadata
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'Call(uuid: $uuid, address: $address, outgoing: $outgoing, state: $callState), muted: $muted';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Call &&
        other.uuid == uuid &&
        other.address == address &&
        other.outgoing == outgoing &&
        other.callState == callState &&
        other.muted != muted &&
        other.metadata == metadata;
  }

  @override
  int get hashCode =>
      uuid.hashCode ^
      address.hashCode ^
      outgoing.hashCode ^
      callState.hashCode ^
      muted.hashCode ^
      metadata.hashCode;
}
