# flutter_voip_kit_example

Demonstrates how to use the flutter_voip_kit plugin.

## Getting Started


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
