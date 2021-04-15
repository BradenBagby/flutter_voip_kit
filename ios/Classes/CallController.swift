//
//  ProviderDelegate.swift
//  flutter_voip_kit
//
//  Created by Braden Bagby on 4/15/21.
//

import Foundation
import AVFoundation
import CallKit


enum CallEvent : String {
    case answerCall = "answerCall"
    case endCall = "endCall"
    case setHeld = "setHeld"
    case reset = "reset"
    case startCall = "startCall"
}

class CallController : NSObject {
    private let provider : CXProvider
    var actionListener : ((CallEvent)->Void)?
    private let callController = CXCallController()
    
    override init() {
      provider = CXProvider(configuration: CallController.providerConfiguration)
      
      super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    //TODO: construct configuration from flutter. pass into init over method channel
    static var providerConfiguration: CXProviderConfiguration = {
      var providerConfiguration: CXProviderConfiguration
      if #available(iOS 14.0, *) {
           providerConfiguration = CXProviderConfiguration.init()
      } else {
           providerConfiguration = CXProviderConfiguration(localizedName: "WAVV")
      }
      
      providerConfiguration.supportsVideo = true
      providerConfiguration.maximumCallsPerCallGroup = 1
      providerConfiguration.supportedHandleTypes = [.phoneNumber]
      
      return providerConfiguration
    }()
}

//MARK: user actions
extension CallController {

    func end(call: Call) {
        print("CallController: user requested end call")
      let endCallAction = CXEndCallAction(call: call.uuid)
      let transaction = CXTransaction(action: endCallAction)
      
      requestTransaction(transaction)
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
      callController.request(transaction) { error in
        if let error = error {
          print("Error requesting transaction: \(error)")
        } else {
          print("Requested transaction successfully")
        }
      }
    }
    
    func setHeld(call: Call, onHold: Bool) {
        print("CallController: user requested hold call")
      let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
      
      let transaction = CXTransaction()
      transaction.addAction(setHeldCallAction)
      
      requestTransaction(transaction)
    }
    
    func startCall(handle: String, videoEnabled: Bool) {
        print("CallController: user requested start call")
      let handle = CXHandle(type: .phoneNumber, value: handle)
      
      let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
      startCallAction.isVideo = videoEnabled
      
      let transaction = CXTransaction(action: startCallAction)
      
      requestTransaction(transaction)
    }
}

//MARK: System notifications
extension CallController: CXProviderDelegate {
  func providerDidReset(_ provider: CXProvider) {
  
  }
  
    //action.callUUID
  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    print("CallController: Answer Call")
    actionListener?(.answerCall)
    action.fulfill()
  }
  
  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
   //startAudio()
 
    print("CallController: Audio session activated")

  }
  
  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    print("CallController: End Call")
    actionListener?(.endCall)
    action.fulfill()
  }
  
  func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
    print("CallController: Set Held")
    actionListener?(.setHeld)
    action.fulfill()
  }
  
  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    actionListener?(.startCall)
    print("CallController: Start Call")
  }
}
