package com.example.flutter_voip_kit

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.CountDownTimer
import android.telecom.CallAudioState
import android.telecom.PhoneAccount
import android.telecom.TelecomManager
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.*

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
        Log.d(TAG,"METHOD CALLED: ${call.method}")
        when(call.method){
            FlutterVoipKitPlugin.methodChannelCheckPermissions -> {
                checkPermissions(call,result)
            }
            FlutterVoipKitPlugin.methodChannelReportIncomingCall -> {
                reportIncomingCall(call, result)
            }
            FlutterVoipKitPlugin.methodChannelHoldCall -> {
                holdCall(call,result)
            }
            FlutterVoipKitPlugin.methodChannelStartCall -> {
                startCall(call,result)
            }
            FlutterVoipKitPlugin.methodChannelEndCall -> {
                endCall(call,result)
            }
            FlutterVoipKitPlugin.methodChannelReportOutgoingCall -> {
                reportOutgoingCall(call,result)
            }
            FlutterVoipKitPlugin.methodChannelReportCallEnded -> {
                reportCallEnded(call,result)
            }
            FlutterVoipKitPlugin.methodChannelMuteCall -> {
                muteCall(call,result)
            }
            else -> {
                result.notImplemented()
            }
        }

    }
    private fun checkPermissions(call: MethodCall, result: MethodChannel.Result) {
        voipUtilties.openSettingsOnNoPermissions = call.argument("openSettings") ?: false;
        val performRequest = call.argument("performRequest") ?: true;
        voipUtilties.checkPhoneAccountPermission(currentActivity!!, result, performRequest);
    }

    private fun reportOutgoingCall(call: MethodCall, result: MethodChannel.Result) {
        val uuid : String = call.argument("uuid")!!;
        val finishedConnecting : Boolean = call.argument("finishedConnecting")!!;
        if(finishedConnecting){
            val connection = VoipConnectionService.getConnection(uuid);
            Log.d(TAG,"report outgoing call: CALL ANSWERED $uuid connection exists: ${connection!=null}")
            connection?.onAnswer();

            //if we have already ended the call return false
            result.success(connection != null);
        }else{
            Log.d(TAG,"report outgoing call: CALL CONNECTING $uuid");
            result.success(true)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startCall(call: MethodCall, result: MethodChannel.Result) {
        val number : String = call.argument("handle")!!
        val uuidString : String? = call.argument("uuid")
        var uuid : UUID? = null;
        if(uuidString != null){
            uuid = UUID.fromString(uuidString);
        }
        //TODO: allow name passed in as well
        Log.d(TAG, "startCall number: $number")
        val extras = Bundle()
        val uri = Uri.fromParts(PhoneAccount.SCHEME_TEL, number, null)
        val callExtras = Bundle()
        callExtras.putString(Constants.EXTRA_CALL_NUMBER, number)
        if (uuid != null) {
            callExtras.putString(Constants.EXTRA_CALL_UUID, uuid.toString());
        }
        extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, voipUtilties.handle)
        extras.putParcelable(TelecomManager.EXTRA_OUTGOING_CALL_EXTRAS, callExtras)
        voipUtilties.telecomManager.placeCall(uri, extras)
        result.success(true)
    }


    private fun endCall(call: MethodCall, result: MethodChannel.Result){
        val uuid : String = call.argument("uuid")!!
        val connection = VoipConnectionService.getConnection(uuid);
            connection?.onDisconnect();
        result.success(true);
    }


    private fun reportCallEnded(call: MethodCall, result: MethodChannel.Result){
        val uuid : String = call.argument("uuid")!!
        val connection = VoipConnectionService.getConnection(uuid);
        connection?.onDisconnect();
        result.success(true);
    }


    private fun holdCall(call: MethodCall, result: MethodChannel.Result){
        Log.d(TAG,"Hold call");
        val uuid : String = call.argument("uuid")!!
        val hold : Boolean = call.argument("hold")!!
        val connection = VoipConnectionService.getConnection(uuid)
            if(hold){
                connection?.onHold();
            }else{
                connection?.onUnhold();
            }
        result.success(true);
    }

    private fun muteCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG,"Mute call");
        val uuid : String = call.argument("uuid")!!
        val muted : Boolean = call.argument("muted")!!
        val connection = VoipConnectionService.getConnection(uuid)
        val newAudioState = if (muted) {
            CallAudioState(true, connection.callAudioState.route,
                    connection.callAudioState.supportedRouteMask)
        } else {
            CallAudioState(false, connection.callAudioState.route,
                    connection.callAudioState.supportedRouteMask)
        }
        connection.onCallAudioStateChanged(newAudioState)
        result.success(true);
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