import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

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
  final testUUID = "33041937-05b2-464a-98ad-3910cbe0d09e";
  List<Call> calls = [];
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();

    FlutterVoipKit.init(callStateChangeHandler: callStateChangeHandler);

    FlutterVoipKit.callListStream.listen((event) {
      dev.log("Widgets call listener");
      calls = event;
      setState(() {});
    });
  }

  Future<bool> callStateChangeHandler(call) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: !hasPermission
              ? Center(
                  child: ElevatedButton(
                    child: Text("Permission Check"),
                    onPressed: () {
                      FlutterVoipKit.checkPermissions().then((value) {
                        setState(() {
                          hasPermission = value;
                        });
                        if (!value) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("no Permissions"),
                          ));
                        }
                      });
                    },
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      ElevatedButton(
                        child: Text("Simlualate incoming call"),
                        onPressed: () {
                          FlutterVoipKit.reportIncomingCall(
                              handle: "${Random().nextInt(10)}" * 9,
                              uuid: testUUID);
                        },
                      ),
                      ElevatedButton(
                        child: Text("Start Call"),
                        onPressed: () {
                          FlutterVoipKit.startCall(
                            "${Random().nextInt(10)}" * 9,
                          );
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            final call = calls[index];
                            return Container(
                              color: call.callState == CallState.active
                                  ? Colors.green[300]
                                  : (call.callState == CallState.held ||
                                          call.callState ==
                                              CallState.connecting)
                                      ? Colors.yellow[200]
                                      : Colors.red,
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text("Number: ${call.address}"),
                                  ),
                                  if (call.callState != CallState.connecting)
                                    ElevatedButton(
                                      onPressed: () {
                                        call.hold(
                                            onHold: !(call.callState ==
                                                CallState.held));
                                      },
                                      child: Text(
                                          call.callState == CallState.held
                                              ? "Resume"
                                              : "Hold"),
                                    ),
                                  if (call.callState == CallState.active)
                                    IconButton(
                                      icon: Icon(
                                        Icons.phone_disabled_sharp,
                                        size: 30,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        call.end();
                                      },
                                    ),
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
