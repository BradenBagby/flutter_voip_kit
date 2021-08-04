package com.example.flutter_voip_kit;

import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.telecom.CallAudioState;
import android.telecom.Connection;
import android.telecom.DisconnectCause;
import android.telecom.TelecomManager;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.util.HashMap;
import java.util.Map;

import static com.example.flutter_voip_kit.Constants.EVENT_answerCall;
import static com.example.flutter_voip_kit.Constants.EVENT_endCall;
import static com.example.flutter_voip_kit.Constants.EVENT_setHeld;
import static com.example.flutter_voip_kit.Constants.EVENT_setMuted;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALLER_NAME;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALL_NUMBER;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALL_UUID;

public class VoipConnection extends Connection {

    private static final String TAG = "VoipConnection";
    private HashMap<String, String> handle;
    private Context context;

    VoipConnection(Context context, HashMap<String, String> handle) {
        super();
        this.handle = handle;
        this.context = context;

        String number = handle.get(EXTRA_CALL_NUMBER);
        String name = handle.get(EXTRA_CALLER_NAME);

        if (number != null) {
            setAddress(Uri.parse(number), TelecomManager.PRESENTATION_ALLOWED);
        }
        if (name != null && !name.equals("")) {
            setCallerDisplayName(name, TelecomManager.PRESENTATION_ALLOWED);
        }
    }



    @Override
    public void onAnswer() {
        super.onAnswer();
        Log.d(TAG, "onAnswer called");

        setConnectionCapabilities(getConnectionCapabilities() | Connection.CAPABILITY_HOLD);
        setAudioModeIsVoip(true);
        final String uuid = handle.get(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_answerCall);
            put("uuid",uuid);
        }};

        Log.d(TAG, "On Answer data: " + data.toString());

       VoipPlugin.sink(data);
        Log.d(TAG, "onAnswer executed");
        setActive();
    }

    @Override
    public void onAbort() {
        super.onAbort();
        setDisconnected(new DisconnectCause(DisconnectCause.REJECTED));
endCall();;
        Log.d(TAG, "onAbort executed");
    }

    @Override
    public void onHold() {
        Log.d(TAG,"On hold");
        super.onHold();
        this.setOnHold();
        final String uuid = handle.get(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_setHeld);
            put("uuid",uuid);
            put("args",true);
        }};
        VoipPlugin.sink(data);
    }

    @Override
    public void onUnhold() {
        super.onUnhold();
        final String uuid = handle.get(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_setHeld);
            put("uuid",uuid);
            put("args",false);
        }};
        VoipPlugin.sink(data);
        VoipConnectionService.setAllOthersOnHold(uuid);
        setActive();
    }



    @Override
    public void onCallEvent(String event, Bundle extras) {
        super.onCallEvent(event, extras);
        Log.d(TAG,"CALL EVENT: " + event);
    }

    @Override
    public void onReject() {
        super.onReject();
        setDisconnected(new DisconnectCause(DisconnectCause.REJECTED));
       endCall();
        Log.d(TAG, "onReject executed");
    }
    @Override
    public void onDisconnect() {
        super.onDisconnect();
        setDisconnected(new DisconnectCause(DisconnectCause.LOCAL));
       endCall();
    }

    void endCall(){
        Log.d(TAG,"Ending call");
        final String uuid = handle.get(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_endCall);
            put("uuid",uuid);
        }};
        VoipPlugin.sink(data);
        try {
            ((VoipConnectionService) context).deinitConnection(handle.get(EXTRA_CALL_UUID));
        } catch(Throwable exception) {
            Log.e(TAG, "Handle map error", exception);
        }
        destroy();

    }

    @Override
    public void onPlayDtmfTone(char dtmf) {

    Log.d(TAG,"OnPlayDtmfTone");
    }

    @Override
    public void onShowIncomingCallUi() {
        super.onShowIncomingCallUi();
        Log.d(TAG,"Show incoming call UI");
    }

    @Override
    public void onCallAudioStateChanged(final CallAudioState state) {
        super.onCallAudioStateChanged(state);
        Log.d(TAG,"On Call Audio State Changed, is muted: " + state.isMuted());
        final String uuid = handle.get(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_setMuted);
            put("uuid",uuid);
            put("args",state.isMuted());
        }};
        VoipPlugin.sink(data);
    }

}

