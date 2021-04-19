package com.example.flutter_voip_kit

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.CountDownTimer
import android.telecom.PhoneAccount
import android.telecom.TelecomManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class VoipPlugin(private val channel: MethodChannel, private val eventChannel: EventChannel, private var applicationContext: Context, private val voipUtilties: VoipUtilties) : MethodChannel.MethodCallHandler {



    companion object{
         var eventSink : EventChannel.EventSink? = null;
        @JvmStatic fun sink(info : Map<String,Any>){
            eventSink?.success(info);
        }
        var GENERAL_ERROR : String = "GENERAL_ERROR";
        private const val TAG = "VoipPlugin"
    }

    init {
        channel.setMethodCallHandler(this)

        //setup event channel
        eventChannel.setStreamHandler(
                object: EventChannel.StreamHandler {
                    override fun onListen(p0: Any?, sink: EventChannel.EventSink) {
                      eventSink = sink;
                    }
                    override fun onCancel(p0: Any) {
                        eventSink = null;
                    }
                }
        )
    }


    internal var currentActivity: Activity? = null
    internal fun stopListening() {
        channel.setMethodCallHandler(null)
    }



    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method){
            FlutterVoipKitPlugin.methodChannelCheckPermissions -> {
                voipUtilties.checkPhoneAccountPermission(currentActivity!!,result);
            }
            FlutterVoipKitPlugin.methodChannelReportIncomingCall -> {
                reportIncomingCall(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }

    }



   private fun reportIncomingCall(call: MethodCall, result: MethodChannel.Result){
        try {
            val uuid : String = call.argument("uuid")!!
            val handleString : String = call.argument("handle")!!
            val name : String? = call.argument("name") //TODO:
            Log.d(TAG, "displayIncomingCall number: $handleString, uuid: $uuid")
            val extras = Bundle()
            val uri = Uri.fromParts(PhoneAccount.SCHEME_TEL, handleString, null)
            extras.putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, uri)
            extras.putString(Constants.EXTRA_CALLER_NAME, handleString) //TODO: put name here
            extras.putString(Constants.EXTRA_CALL_UUID, uuid)
            voipUtilties.telecomManager.addNewIncomingCall(voipUtilties.handle, extras)
            result.success(true);
        }catch (er: Exception){
            Log.d(TAG,"Failed to report new incoming call: $er");
            result.error(GENERAL_ERROR,er.toString(),null)
        }

    }

}