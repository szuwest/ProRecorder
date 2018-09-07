package com.prorecorder.record.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.telephony.TelephonyManager;
import android.text.TextUtils;

import java.util.UUID;

/**
 * Copyright 2017 SpeakIn.Inc
 * Created by west on 2017/10/26.
 */

public class DeviceUUID {

    private static final String _UUID = "DeviceUUID";
    private static final String KEY_UUID = "KEY_UUID";

    public static String getDeviceUUID(Context context){

        try {
            //IMEI（imei）
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
            String imei = tm.getDeviceId();
            if (!TextUtils.isEmpty(imei) && !imei.startsWith("00000")) {
                return imei;
            }

            String sn = tm.getSimSerialNumber();
            if (!TextUtils.isEmpty(sn) && !sn.startsWith("00000")) {
                return sn;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        SharedPreferences preferences = context.getSharedPreferences(_UUID, Context.MODE_PRIVATE);
        String uuid = preferences.getString(KEY_UUID, "");
        if (TextUtils.isEmpty(uuid)) {
            uuid = UUID.randomUUID().toString();
            preferences.edit().putString(KEY_UUID,uuid).apply();
        }
        return uuid;
    }

}
