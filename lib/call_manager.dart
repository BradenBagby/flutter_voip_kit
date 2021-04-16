import 'dart:async';

import 'package:flutter_voip_kit/call.dart';

import 'flutter_voip_kit.dart';

///internal class. keeps track of all active calls. Should not be accessed outside of plugin
class CallManager {
  ///list of active calls
  final List<Call> _calls = [];

  ///Stream that emits when a new call is added or removed
  static final callListStreamController =
      StreamController<List<Call>>.broadcast();

  ///retrievs a call by its UUID if it exists in the current calls
  Call? getCallByUuid(String uuid) {
    try {
      return _calls.firstWhere(
          (element) => element.uuid.toLowerCase() == uuid.toLowerCase());
    } catch (er) {
      return null;
    }
  }

  ///Adds a call and notifies listeners
  void addCall(Call call) {
    _calls.add(call);
    _notifyListeners();
  }

  ///Ends all calls
  void endAll() async {
    for (Call call in _calls) {
      await FlutterVoipKit
          .callStateChangeHandler!(call..callState = CallState.ended);
    }
    _calls.clear();
    _notifyListeners();
  }

  ///removes a call and notifies listeners
  void removeCall(Call call) {
    _calls.removeWhere(
        (element) => element.uuid.toLowerCase() == call.uuid.toLowerCase());
    _notifyListeners();
  }

  ///notify listeners when _call list changes
  void _notifyListeners() {
    callListStreamController.add(_calls);
  }
}
