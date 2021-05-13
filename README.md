# flutter_voip_kit

Use iOS CallKit and Android's Telecom library to create and receive calls with native functionality. e.g. Calls pop up on user's lock screen.

## Getting Started
To use this plugin, add `flutter_voip_kit` as a [dependency in your pubspec.yaml file]

### Setup

IOS: 
Add Voip background modes in Xcode

Android:

Add Permissions in Android Manifest in <manifest> block
```
        <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    <uses-permission android:name="android.permission.CALL_PHONE" />
``` 

Add Service in Android Manifest inside <application> block. You can change android:label to fit your project
```
         <service android:name="com.example.flutter_voip_kit.VoipConnectionService"
           android:label="VoipConnectionService"
           android:permission="android.permission.BIND_TELECOM_CONNECTION_SERVICE">
           <intent-filter>
               <action android:name="android.telecom.ConnectionService" />
           </intent-filter>
       </service>
```

### API
Be sure to check out th example project in /example

### FlutterVoipKit.init(callStateChangeHandler: CallStateChangeHandler)

Initialize FlutterVoipKit. Pass in a reference to your CallStateChange handler function that you will setup to handle all VOIP events (see below)

### typdef Future<bool> CallStateChangeHandler(Call call)
A callback function that you set up to handle all VOIP events. This function must handle every CallState and return true/false. If you forget to handle a call state your VOIP calls may fail. For example:
```dart
  Future<bool> myCallStateChangeHandler(call) async {
    dev.log("widget call state changed lisener: $call");

    switch (call.callState) {//handle every call state
      case CallState
          .connecting: //simulate connection time of 3 seconds for our VOIP service
        await Future.delayed(const Duration(seconds: 3));
        //MyVOIPService.connectCall(call.uuid)
        return true;
      case CallState
          .active: //here we would likely begin playing audio out of speakers
          //MyVOIPService.activeAudioForCall(call.uuid)
        return true;
      case CallState.ended: //likely end audio, disconnect
        return true;
      case CallState.failed: //likely cleanup
        return true;
      case CallState.held: //likely pause audio for specified call
        return true;
      default:
        return false;
        break;
    }
  }
```


###  FlutterVoipKit.callListStream
Listen to this stream for updates on active calls. Add to your array, bloc, or however you want to manage calls. Example
```dart
    FlutterVoipKit.callListStream.listen((allCalls) {
      setState(() {
        calls = allCalls;
      });
    });
```


### FlutterVoipKit Future<bool> reportIncomingCall(handle: String, uuid: String);
Report that your device has been notified of an incoming call. Do not perform any connection logic yet, the connection logic is placed in your myCallStateChanged callback. Instead, just report you are receiving call and wait for native OS to inform if you should connect or not

### FlutterVoipKit Future<bool> startCall(String address);
Inform native OS you wish to start a call. Do not perform any conenction logic here, the connection logic is placed in your myCallStateChanged callback. Instead, just report to OS you wish to start a call and wait for native OS to inform you if you should connect or not

### Call Future<bool> end   or..
## FlutterVoipKit.Future<bool> endCall(Call call)
Tell OS to end the call. Do not perform logic, perform logic in myCallStateChanged callback

### Call Future<bool> hold(bool onHold)   or..
### FlutterVoipKit static Future<bool> holdCall(Call call, {bool onHold = true})
Tell OS to set call on hold or not. Do not perform logic, perform logic in myCallStateChanged callback