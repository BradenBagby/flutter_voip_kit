import 'dart:async';
import 'dart:io';

import 'package:flutter_voip_kit/call.dart';
import 'package:path_provider/path_provider.dart';

import 'flutter_voip_kit.dart';

///internal class. keeps track of all active calls. Should not be accessed outside of plugin
class CallManager {
  static CallManager? _instance;
  factory CallManager() => _instance ??= CallManager._();

  CallManager._() {
    getApplicationDocumentsDirectory().then((value) {
      _path.complete("${value.path}/cached_incoming_call.json");
    });
  }
  /// local storage is used to cache a call so we can acces it across processes, this is important for android and incoming calls
  final _path = Completer<String>();

  ///list of active calls
  final List<Call> _calls = [];

  ///Stream that emits when a new call is added or removed
  static final callListStreamController =
      StreamController<List<Call>>.broadcast();

  ///retrievs a call by its UUID if it exists in the current calls
  Future<Call?> getCallByUuid(String uuid, {bool checkCache = true}) async {
    Call? call;
    try {
      call = _calls.isEmpty
          ? null
          : _calls.firstWhere(
              (element) => element.uuid.toLowerCase() == uuid.toLowerCase());
    } catch (er) {}

    // if we look for a call that doesnt exist we check the cache
    if (call == null && checkCache) {
      final path = await _path.future;
      final file = File(path);
      try {
        if (file.existsSync()) {
          final callInCacheString = file.readAsStringSync();
          final cachedCall = Call.fromJson(callInCacheString);
          // remove cache if its over a day old
          final now = DateTime.now().subtract(const Duration(days: 1));
          if (now.compareTo(cachedCall.startTimestamp) > 1) {
            file.deleteSync();
          } else {
            // add to _calls so we don't have to check cache again
            if (cachedCall.uuid == uuid) {
              _calls.add(cachedCall);
              call = cachedCall;
            }
          }
        }
      } catch (err) {
        file.deleteSync();
      }
    }

    return call;
  }

  /// Adds a call and notifies listeners
  Future<void> addCall(Call call) async {
    _calls.add(call);

    // cache call
    File(await _path.future)
        .writeAsStringSync(call.toJson(), mode: FileMode.write, flush: true);

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
