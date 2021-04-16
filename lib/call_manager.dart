import 'dart:async';

import 'package:flutter_voip_kit/call.dart';

import 'flutter_voip_kit.dart';

///keeps track of all active calls
class CallManager {
  final List<Call> _calls = [];
  final _callListStreamController = StreamController<List<Call>>.broadcast();
  Stream<List<Call>> get callListStream => _callListStreamController.stream;

  Call? getCallByUuid(String uuid) {
    try {
      return _calls.firstWhere(
          (element) => element.uuid.toLowerCase() == uuid.toLowerCase());
    } catch (er) {
      return null;
    }
  }

  void addCall(Call call) {
    _calls.add(call);
    notifyListeners();
  }

  void endAll() async {
    for (Call call in _calls) {
      await FlutterVoipKit
          .callStateChangeHandler!(call..callState = CallState.ended);
    }
    _calls.clear();
    notifyListeners();
  }

  void removeCall(Call call) {
    _calls.removeWhere(
        (element) => element.uuid.toLowerCase() == call.uuid.toLowerCase());
    notifyListeners();
  }

  void notifyListeners() {
    _callListStreamController.add(_calls);
  }
}
