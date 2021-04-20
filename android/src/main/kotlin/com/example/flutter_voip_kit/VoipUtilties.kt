package com.example.flutter_voip_kit

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.os.Build
import android.telecom.ConnectionService
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class VoipUtilties( val applicationContext : Context) : PluginRegistry.RequestPermissionsResultListener {

    private var hasPhoneAccountResult: MethodChannel.Result? = null //saved to return of result check
    lateinit var telecomManager: TelecomManager
    lateinit var handle: PhoneAccountHandle
    lateinit var telephonyManager: TelephonyManager
    var openSettingsOnNoPermissions : Boolean = false;

    init {
        registerPhoneAccount(applicationContext,null) //TOOD: pass in init from flutter

    }

    private fun registerPhoneAccount(appContext: Context, imageName: String?) {
        if (!isConnectionServiceAvailable()) return

        val cName = ComponentName(applicationContext, VoipConnectionService::class.java)
        val appName = getApplicationName(appContext)
        handle = PhoneAccountHandle(cName, appName)
        val builder = PhoneAccount.Builder(handle, appName)
                .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
        if (imageName != null) {
            val identifier = appContext.resources.getIdentifier(imageName, "drawable", appContext.packageName)
            val icon = Icon.createWithResource(appContext, identifier)
            builder.setIcon(icon)
        }
        val account = builder.build()
        telephonyManager = applicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        telecomManager = applicationContext.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        telecomManager!!.registerPhoneAccount(account)
    }

    private fun getApplicationName(appContext: Context): String {
        val applicationInfo = appContext.applicationInfo
        val stringId = applicationInfo.labelRes
        return if (stringId == 0) applicationInfo.nonLocalizedLabel.toString() else appContext.getString(stringId)
    }



    companion object {
        private const val E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST"
        private const val TAG = "VoipUtilties"
        private val requiredPermissions = arrayOf(Manifest.permission.READ_PHONE_STATE, Manifest.permission.CALL_PHONE, Manifest.permission.RECORD_AUDIO)
        private  val REQUEST_READ_PHONE_STATE = 58251
    }

    private fun isConnectionServiceAvailable(): Boolean {
        // PhoneAccount is available since api level 23
        return Build.VERSION.SDK_INT >= 23
    }


         fun checkPhoneAccountPermission(activity: Activity?, result: MethodChannel.Result) {

            if (!isConnectionServiceAvailable()) {
                result.error(E_ACTIVITY_DOES_NOT_EXIST, "ConnectionService not available for this version of Android.", null)
                return
            }
            if (activity == null) {
                result.error(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist", null)
                return
            }
            val allPermissions = requiredPermissions
            hasPhoneAccountResult = result
            if (!this.hasPermissions(activity)) {
                ActivityCompat.requestPermissions(activity, allPermissions, REQUEST_READ_PHONE_STATE)
                return
            }
             val hasPhoneAccount = hasPhoneAccount();
            result.success(hasPhoneAccount)
        }

        private fun hasPermissions(activity: Activity): Boolean {
            for (permission in requiredPermissions) {
                val permissionCheck = ContextCompat.checkSelfPermission(activity, permission)
                if (permissionCheck != PackageManager.PERMISSION_GRANTED) return false
            }

            return true
        }

    @SuppressLint("MissingPermission")
    private fun hasPhoneAccount(): Boolean {

        var allAccounts = telecomManager.callCapablePhoneAccounts;
        Log.d(TAG, allAccounts.toString());
        var current = telecomManager!!.getPhoneAccount(handle);
        return if (current.isEnabled) {
            true;
        } else {
            if(openSettingsOnNoPermissions) { //auto open settings to choose phone account
                val intent = Intent(TelecomManager.ACTION_CHANGE_PHONE_ACCOUNTS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK

                applicationContext.startActivity(intent)
            }

            false;
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
        if (requestCode != REQUEST_READ_PHONE_STATE) {
            return false
        }

        for ((permissionsIndex, result) in grantResults!!.withIndex()) {
            if (requiredPermissions.contains(permissions!![permissionsIndex]) && result != PackageManager.PERMISSION_GRANTED) {
                val hasPhoneAccount = hasPhoneAccount()
                hasPhoneAccountResult!!.success(hasPhoneAccount)
                hasPhoneAccountResult = null
                return true
            }
        }

        hasPhoneAccountResult!!.success(false)
        hasPhoneAccountResult = null

        return true
    }

}




