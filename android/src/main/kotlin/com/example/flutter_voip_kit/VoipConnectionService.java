package com.example.flutter_voip_kit;

import android.app.ActivityManager;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.telecom.Connection;
import android.telecom.ConnectionRequest;
import android.telecom.ConnectionService;
import android.telecom.DisconnectCause;
import android.telecom.PhoneAccountHandle;
import android.telecom.TelecomManager;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static android.telecom.Connection.PROPERTY_SELF_MANAGED;
import static com.example.flutter_voip_kit.Constants.EVENT_answerCall;
import static com.example.flutter_voip_kit.Constants.EVENT_endCall;
import static com.example.flutter_voip_kit.Constants.EVENT_startCall;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALLER_NAME;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALL_NUMBER;
import static com.example.flutter_voip_kit.Constants.EXTRA_CALL_UUID;

public class VoipConnectionService extends ConnectionService {

    private static final String TAG = "VoipConnectionService";
    public static Map<String, VoipConnection> currentConnections = new HashMap<>();


    public static Connection getConnection(String connectionId) {
        if (currentConnections.containsKey(connectionId)) {
            return currentConnections.get(connectionId);
        }
        return null;
    }

    public static void deinitConnection(String connectionId) {
        Log.d(TAG, "deinitConnection:" + connectionId);
        if (currentConnections.containsKey(connectionId)) {
            currentConnections.remove(connectionId);
        }
    }

    @Override
    public Connection onCreateIncomingConnection(PhoneAccountHandle connectionManagerPhoneAccount, ConnectionRequest request) {
        Log.d(TAG,"OnCreateIncomingConnection");
        Bundle extra = request.getExtras();
        Uri number = request.getAddress();
        String name = extra.getString(EXTRA_CALLER_NAME);
        Connection incomingCallConnection = createConnection(request);
        incomingCallConnection.setRinging();
        incomingCallConnection.setInitialized();

        return incomingCallConnection;
    }

    @Override
    public void onCreateIncomingConnectionFailed(PhoneAccountHandle connectionManagerPhoneAccount, ConnectionRequest request) {
        super.onCreateIncomingConnectionFailed(connectionManagerPhoneAccount, request);
        Log.d(TAG,"OnCreateIncomingConnection FAILED");
        final String uuid = request.getExtras().getString(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_endCall);
            put("uuid",uuid);
        }};
        VoipPlugin.sink(data);
    }

    @Override
    public Connection onCreateOutgoingConnection(PhoneAccountHandle connectionManagerPhoneAccount, ConnectionRequest request) {
        Bundle extras = request.getExtras();
        Connection outgoingCallConnection = null;
        String number = request.getAddress().getSchemeSpecificPart();
        String extrasNumber = extras.getString(EXTRA_CALL_NUMBER);
        String displayName = extras.getString(EXTRA_CALLER_NAME);
        boolean isForeground = VoipConnectionService.isRunning(this.getApplicationContext());

        Log.d(TAG, "makeOutgoingCall:, number: " + number + ", displayName:" + displayName);

        // Wakeup application if needed
        if (!isForeground) {
            Log.d(TAG, "onCreateOutgoingConnection: Waking up application");
           //TODO:
        }

        outgoingCallConnection = createConnection(request);
        outgoingCallConnection.setDialing();
        outgoingCallConnection.setAudioModeIsVoip(true);
        outgoingCallConnection.setCallerDisplayName(displayName, TelecomManager.PRESENTATION_ALLOWED);

        // ‍️Weirdly on some Samsung phones (A50, S9...) using `setInitialized` will not display the native UI ...
        // when making a call from the native Phone application. The call will still be displayed correctly without it.
        if (!Build.MANUFACTURER.equalsIgnoreCase("Samsung")) {
            outgoingCallConnection.setInitialized();
        }

        Log.d(TAG, "onCreateOutgoingConnection: calling");

        //notify fluttter
        final String uuid = outgoingCallConnection.getExtras().getString(EXTRA_CALL_UUID);
        final String address = outgoingCallConnection.getExtras().getString(EXTRA_CALL_NUMBER);
        Log.d(TAG,"Created call's uuid" + uuid);
         Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_startCall);
            put("uuid",uuid);
            put("args",address);
        }};
         VoipPlugin.sink(data);

        return outgoingCallConnection;
    }

    @Override
    public void onCreateOutgoingConnectionFailed(PhoneAccountHandle connectionManagerPhoneAccount, ConnectionRequest request) {
        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request);
        Log.d(TAG,"OnCreateOutgoingConnectionFailed FAILED");
        final String uuid = request.getExtras().getString(EXTRA_CALL_UUID);
        final Map<String,Object> data = new HashMap<String,Object>() {{
            put("event",EVENT_endCall);
            put("uuid",uuid);
        }};
        VoipPlugin.sink(data);
    }

    private Connection createConnection(ConnectionRequest request) {
        Log.d(TAG, "Create Connection");
        Bundle extras = request.getExtras();
        if(extras.getString(EXTRA_CALL_UUID) == null){
            extras.putString(EXTRA_CALL_UUID,UUID.randomUUID().toString());
        }
        HashMap<String, String> extrasMap = this.bundleToMap(extras);
        extrasMap.put(EXTRA_CALL_NUMBER, request.getAddress().toString());
        VoipConnection connection = new VoipConnection(this, extrasMap);
        connection.setConnectionCapabilities(Connection.CAPABILITY_MUTE | Connection.CAPABILITY_SUPPORT_HOLD);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                connection.setConnectionProperties(PROPERTY_SELF_MANAGED);
            }

        connection.setInitializing();

        connection.setExtras(extras);
        currentConnections.put(extras.getString(EXTRA_CALL_UUID), connection);

        return connection;
    }

    private HashMap<String, String> bundleToMap(Bundle extras) {
        HashMap<String, String> extrasMap = new HashMap<>();
        Set<String> keySet = extras.keySet();
        Iterator<String> iterator = keySet.iterator();

        while(iterator.hasNext()) {
            String key = iterator.next();
            if (extras.get(key) != null) {
                extrasMap.put(key, extras.get(key).toString());
            }
        }
        return extrasMap;
    }

    /**
     * https://stackoverflow.com/questions/5446565/android-how-do-i-check-if-activity-is-running
     *
     * @param context Context
     * @return boolean
     */
    public static boolean isRunning(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningTaskInfo> tasks = activityManager.getRunningTasks(Integer.MAX_VALUE);

        for (ActivityManager.RunningTaskInfo task : tasks) {
            if (context.getPackageName().equalsIgnoreCase(task.baseActivity.getPackageName()))
                return true;
        }

        return false;
    }


}
