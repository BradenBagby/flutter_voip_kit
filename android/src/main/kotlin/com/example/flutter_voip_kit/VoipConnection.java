package com.example.flutter_voip_kit;

import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.telecom.Connection;
import android.telecom.TelecomManager;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.util.HashMap;
import java.util.Map;

import static com.example.flutter_voip_kit.Constants.EVENT_answerCall;
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
    }

}
