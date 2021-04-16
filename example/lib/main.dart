import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_voip_kit/call.dart';
import 'package:flutter_voip_kit/flutter_voip_kit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final testUUID = "33041937-05b2-464a-98ad-3910cbe0d09e";
  List<Call> calls = [];

  @override
  void initState() {
    super.initState();

    FlutterVoipKit.callStateChangeHandler = (call) async {
      dev.log("widget call state changed lisener: $call");
      setState(() {});
      switch (call.callState) {
        case CallState.connecting:
          dev.log("--------------> Call connecting");
          await Future.delayed(const Duration(seconds: 1));
          return true;
          break;
        case CallState.active:
          dev.log("--------> Call active");
          return true;
        case CallState.ended:
          dev.log("--------> Call ended");
          await Future.delayed(const Duration(seconds: 1));
          return true;
        case CallState.failed:
          dev.log("--------> Call failed");
          return true;
        case CallState.held:
          dev.log("--------> Call held");
          return true;
        default:
          return false;
          break;
      }
    };

    FlutterVoipKit.init();

    FlutterVoipKit.callManager.callListStream.listen((event) {
      dev.log("Widgets call listener");
      calls = event;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                ElevatedButton(
                  child: Text("Simlualate incoming call"),
                  onPressed: () {
                    /*final uuid = testUUID
                        .replaceFirst("3", "${Random().nextInt(10)}")
                        .replaceFirst("4", "${Random().nextInt(10)}");*/
                    FlutterVoipKit.reportIncomingCall(
                        handle: "63628456" +
                            "${Random().nextInt(10)}" +
                            "${Random().nextInt(10)}",
                        uuid: testUUID);
                  },
                ),
                ElevatedButton(
                  child: Text("Start Call"),
                  onPressed: () {
                    /*final uuid = testUUID
                        .replaceFirst("3", "${Random().nextInt(10)}")
                        .replaceFirst("4", "${Random().nextInt(10)}");*/
                    FlutterVoipKit.startCall(
                      "63628456" +
                          "${Random().nextInt(10)}" +
                          "${Random().nextInt(10)}",
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      final call = calls[index];
                      return Container(
                        height: 100,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(call.address),
                            ),
                            Text(call.callState.toString()),
                            if (call.callState == CallState.active) ...[
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  call.end();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.hourglass_disabled),
                                onPressed: () {
                                  call.hold();
                                },
                              )
                            ],
                            if (call.callState == CallState.held)
                              IconButton(
                                icon: Icon(Icons.star),
                                onPressed: () {
                                  call.hold(onHold: false);
                                },
                              )
                          ],
                        ),
                      );
                    },
                    itemCount: calls.length,
                  ),
                )
              ],
            ),
          )),
    );
  }
}
