package com.example.flutter_voip_kit

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** FlutterVoipKitPlugin
 *
 * Android Implementation Helped by: https://github.com/doneservices/flutter_callkeep/blob/master/LICENSE Copyright (c) 2019 1337 Marknadsplatser AB
 *
 * */
class FlutterVoipKitPlugin: FlutterPlugin, ActivityAware {
  companion object {
    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
        val plugin = FlutterVoipKitPlugin();
        plugin.setup(registrar.messenger(),registrar.context().applicationContext);
    }
    private const val TAG = "FlutterVoipKitPlugin"
    val methodChannelName = "flutter_voip_kit"
    val eventChannelName  = "flutter_voip_kit.callEventChannel";

    ///methods
    val methodChannelStartCall = "flutter_voip_kit.startCall"
    val methodChannelReportIncomingCall = "flutter_voip_kit.reportIncomingCall"
    val methodChannelReportOutgoingCall = "flutter_voip_kit.reportOutgoingCall"
    val methodChannelReportCallEnded =
            "flutter_voip_kit.reportCallEnded";
    val methodChannelEndCall = "flutter_voip_kit.endCall";
    val methodChannelHoldCall = "flutter_voip_kit.holdCall";
    val methodChannelCheckPermissions = "flutter_voip_kit.checkPermissions" //TODO: ios

  }





  private lateinit var channel : MethodChannel



  private var methodCallHandler: VoipPlugin? = null
  private var _utilties : VoipUtilties? = null

    fun setup(messenger: BinaryMessenger, context : Context){
        val channel = MethodChannel(messenger, methodChannelName)
        val eventChannel = EventChannel(messenger,eventChannelName)
        val utilties  = VoipUtilties(context)
        val plugin = VoipPlugin(channel,eventChannel, context,utilties)

        methodCallHandler = plugin
        _utilties = utilties
    }
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
setup(binding.binaryMessenger,binding.applicationContext);
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodCallHandler?.stopListening()
    methodCallHandler = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    val plugin = methodCallHandler ?: return
    var utilties = _utilties ?: return
    Log.d(TAG,"ATTACHED TO ACTIVITY")

    plugin.currentActivity = binding.activity
    binding.addRequestPermissionsResultListener(utilties)
  }

  override fun onDetachedFromActivity() {
    methodCallHandler?.currentActivity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }
}
