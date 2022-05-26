import Flutter
import UIKit




class CallStreamHandler: NSObject, FlutterStreamHandler {
    
    var eventSink : FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("CallStreamHandler: on listen");
        self.eventSink = events
        SwiftFlutterVoipKitPlugin.callController.actionListener = voipEvent
        return nil
    }
    
    public func voipEvent (event: CallEvent, uuid: UUID, args : Any?)->Void {
            print("Action listener: \(event)")
            var data = ["event" : event.rawValue, "uuid": uuid.uuidString] as [String: Any]
            if args != nil{
                data["args"] = args!
            }
            eventSink?(data)
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("CallStreamHanlder: on cancel")
        SwiftFlutterVoipKitPlugin.callController.actionListener = nil
        return nil
    }
    
}

public class SwiftFlutterVoipKitPlugin: NSObject, FlutterPlugin {
    static let _methodChannelName = "flutter_voip_kit";
    static let _callEventChannelName = "flutter_voip_kit.callEventChannel"
    static let callController = CallController()
    static let callStreamHandler = CallStreamHandler()
    
    
    //methods
    static let _methodChannelStartCall = "flutter_voip_kit.startCall"
    static let _methodChannelReportIncomingCall = "flutter_voip_kit.reportIncomingCall"
    static let _methodChannelReportOutgoingCall = "flutter_voip_kit.reportOutgoingCall"
    static let _methodChannelReportCallEnded =
        "flutter_voip_kit.reportCallEnded";
    static let _methodChannelEndCall = "flutter_voip_kit.endCall";
    static let _methodChannelHoldCall = "flutter_voip_kit.holdCall";
    static let _methodChannelCheckPermissions = "flutter_voip_kit.checkPermissions";
    static let _methodChannelMuteCall = "flutter_voip_kit.muteCall";
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        //setup method channels
        let methodChannel = FlutterMethodChannel(name: _methodChannelName, binaryMessenger: registrar.messenger())
        
        //setup event channels
        let callEventChannel = FlutterEventChannel(name: _callEventChannelName, binaryMessenger: registrar.messenger())
        callEventChannel.setStreamHandler(callStreamHandler)
        
        let instance = SwiftFlutterVoipKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    // report incoming call from native code, then tell dart about this call
    public static func reportIncomingCallFromNative(handle: String, uuid: UUID, hasVideo: Bool, completion: ((Error?) -> Void)?){
        callController.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo) { err in
            if err == nil {
                callStreamHandler.voipEvent(event: .callStartedFromNative, uuid: uuid, args: nil) // TODO: pass info on the call
            }
            completion?(err)
        }
    }
    
    // report incoming call from dart
    static func reportIncomingCall(handle: String, uuid: String, result: FlutterResult?){
        SwiftFlutterVoipKitPlugin.callController.reportIncomingCall(uuid: UUID(uuidString: uuid)!, handle: handle) { (error) in
            print("ERROR: \(error?.localizedDescription ?? "none")")
            result?(error == nil)
        }
    }
    
    //TODO: remove these defaults and get as arguments
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("Method call \(call.method)");
        let args = call.arguments as? Dictionary<String, Any>
        if(call.method == SwiftFlutterVoipKitPlugin._methodChannelStartCall){
            if let handle = args?["handle"] as? String{
                let uuidString = args?["uuid"] as? String;
                SwiftFlutterVoipKitPlugin.callController.startCall(handle: handle, videoEnabled: false, uuid: uuidString)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelReportIncomingCall{
            if let handle = args?["handle"] as? String, let uuid = args?["uuid"] as? String{
                SwiftFlutterVoipKitPlugin.reportIncomingCall(handle: handle, uuid: uuid, result: result)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelReportOutgoingCall{
            if let finishedConnecting = args?["finishedConnecting"] as? Bool, let uuid = args?["uuid"] as? String{
                SwiftFlutterVoipKitPlugin.callController.reportOutgoingCall(uuid: UUID(uuidString: uuid)!, finishedConnecting: finishedConnecting);
                result(true);
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
        else if call.method == SwiftFlutterVoipKitPlugin._methodChannelReportCallEnded{
            if let reason = args?["reason"] as? String, let uuid = args?["uuid"] as? String{
                SwiftFlutterVoipKitPlugin.callController.reportCallEnded(uuid: UUID(uuidString: uuid)!, reason: CallEndedReason.init(rawValue: reason)!);
                result(true);
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelEndCall{
            if let uuid = args?["uuid"] as? String{
                SwiftFlutterVoipKitPlugin.callController.end(uuid: UUID(uuidString: uuid)!)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelHoldCall{
            if let uuid = args?["uuid"] as? String, let hold = args?["hold"] as? Bool{
                SwiftFlutterVoipKitPlugin.callController.setHeld(uuid: UUID(uuidString: uuid)!, onHold: hold)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelCheckPermissions{
            result(true) //no permissions needed on ios
        }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelMuteCall{
            if let uuid = args?["uuid"] as? String, let muted = args?["muted"] as? Bool{
                SwiftFlutterVoipKitPlugin.callController.setMute(uuid: UUID(uuidString: uuid)!, muted: muted)
                result(true)
            }else{
                result(FlutterError.init(code: "bad args", message: nil, details: nil))
            }
        }
    }
}
