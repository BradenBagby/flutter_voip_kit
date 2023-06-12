# flutter_voip_kit

Use iOS CallKit and Android's Telecom library to create and receive calls with native functionality. e.g. Calls pop up on user's lock screen.

## Usage

To use this plugin, add `flutter_voip_kit` as a dependency in your *pubspec.yaml* file:

```sh
flutter pub add flutter_voip_kit
flutter pub get
```

### Setup

1. iOS:

Add VoIP background modes to Xcode.

2. Android:

Add the permissions and a VoIP connection service to your *android/app/src/main/AndroidManifest.xml* file.
You can change the `android:label` value of the service to fit your project:

```xml
<manifest>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.READ_PHONE_STATE" />
  <uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
  <uses-permission android:name="android.permission.CALL_PHONE" />
  
  <service 
    android:name="com.example.flutter_voip_kit.VoipConnectionService"
    android:label="VoipConnectionService"
    android:permission="android.permission.BIND_TELECOM_CONNECTION_SERVICE">
    <intent-filter>
      <action android:name="android.telecom.ConnectionService" />
    </intent-filter>
  </service>
</manifest>
``` 

### API

Be sure to check out the example project in */example*.

#### Initialization

A `CallStateChangeHandler` is a callback function of type `Future<bool> Function(Call call)` 
that you can set up to handle all VOIP events. This function must handle every `CallState`
and must return true or false. If you forget to handle a call state, your VOIP calls may 
fail. For example:

```dart
Future<bool> myCallStateChangeHandler(call) async {
  dev.log("widget call state changed lisener: $call");

  switch (call.callState) {//handle every call state
    case CallState.connecting:
      // Simulate a connection time of 3 seconds for our VOIP service
      await Future.delayed(const Duration(seconds: 3));
      // MyVOIPService.connectCall(call.uuid);
      return true;

    case CallState.active: 
      // Likely begin playing audio out of speakers
      // MyVOIPService.activeAudioForCall(call.uuid);
      return true;
    
    case CallState.ended: 
      // Likely end audio, disconnect
      return true;
    
    case CallState.failed: 
      // Likely cleanup
      return true;
    
    case CallState.held: 
      // Likely pause audio for specified call
      return true;
    
    default:
      return false;
  }
}
```

Before starting, initialize `FlutterVoipKit`. Pass in a reference to your `CallStateChangeHandler` function 
that you will setup to handle all VOIP events:

```dart
FlutterVoipKit.init(callStateChangeHandler: myCallStateChangeHandler);
```

After initializing, listen to `callListStream` for updates on active calls. Add to your array, bloc or 
however you want to manage calls:

```dart
FlutterVoipKit.callListStream.listen((allCalls) {
  setState(() => calls = allCalls);
});
```

#### Methods

When calling the methods below, **do not** perform any connection logic. The connection logic
must be placed in your `CallStateChangeHandler` callback. Instead, just call the method and wait
for the native OS to handle it.

Report that your device has been notified of an incoming call using `reportIncomingCall`:

```dart
Future<bool> reportIncomingCall(handle: String, uuid: String)
```

Inform native OS you wish to start a call using `startCall`:

```dart
Future<bool> startCall(address: String)
```

Tell OS to end the call using `end` or `endCall`:

```dart
Future<bool> end()
Future<bool> endCall(call: Call)
```

Tell OS to set call on hold or not using `hold` or `holdCall`:

```dart
Future<bool> hold(onHold: bool)
Future<bool> holdCall(call: Call, onHold: true)
```
