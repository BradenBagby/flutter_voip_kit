import Flutter
import UIKit




class CallStreamHandler: NSObject, FlutterStreamHandler {
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("CallStreamHandler: on listen");
        SwiftFlutterVoipKitPlugin.callController.actionListener = { event in
            events(event.rawValue)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("CallStreamHanlder: on cancel")
        SwiftFlutterVoipKitPlugin.callController.actionListener = nil
        return nil
    }
    
}

public class SwiftFlutterVoipKitPlugin: NSObject, FlutterPlugin {
    static let _methodChannelName = "flutter_voip_kit";
    static let _callEventChannelName = "com.wavv.callEventChannel"
    static let callController = CallController()
    
    
    //methods
    static let _methodChannelStartCall = "flutter_voip_kit.startCall"
    static let _methodChannelReportIncomingCall = "flutter_voip_kit.reportIncomingCall"
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    
    //setup method channels
    let methodChannel = FlutterMethodChannel(name: _methodChannelName, binaryMessenger: registrar.messenger())
    
    //setup event channels
    let callEventChannel = FlutterEventChannel(name: _callEventChannelName, binaryMessenger: registrar.messenger())
    callEventChannel.setStreamHandler(CallStreamHandler())
    
    let instance = SwiftFlutterVoipKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }

    //TODO: remove these defaults and get as arguments
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? Dictionary<String, Any>
    if(call.method == SwiftFlutterVoipKitPlugin._methodChannelStartCall){
        if let handle = args?["handle"] as? String{
        SwiftFlutterVoipKitPlugin.callController.startCall(handle: handle, videoEnabled: false)
        result(true)
        }else{
        result(FlutterError.init(code: "bad args", message: nil, details: nil))
        }
    }else if call.method == SwiftFlutterVoipKitPlugin._methodChannelReportIncomingCall{
        if let handle = args?["handle"] as? String, let uuid = args?["uuid"] as? String{
        SwiftFlutterVoipKitPlugin.callController.reportIncomingCall(uuid: UUID(uuidString: uuid)!, handle: handle) { (error) in
        result(error == nil)
        }
        }else{
            result(FlutterError.init(code: "bad args", message: nil, details: nil))
        }
    }
  }
}
