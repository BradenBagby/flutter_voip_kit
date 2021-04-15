import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    FlutterVoipKit.callEventStream.listen((event) {
      setState(() {
        log("$event");
        _platformVersion = "$event";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                onPressed: () {
                  FlutterVoipKit.startCall("6362845669");
                },
                child: Text("Start Call"),
              ),
              ElevatedButton(
                onPressed: () {
                  FlutterVoipKit.reportIncomingCall(uuid: testUUID, handle: "6362845669");
                },
                child: Text("Report Call"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
