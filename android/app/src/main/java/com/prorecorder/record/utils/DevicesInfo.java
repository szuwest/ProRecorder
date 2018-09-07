package com.prorecorder.record.utils;

import android.content.Context;
import android.os.Build;

import com.prorecorder.MainApplication;


public class DevicesInfo {

    private static DevicesInfo info = null;
	public String imei;
    public String deviceName;
    private String systemVer;

	public DevicesInfo(Context ctx) {
        imei = DeviceUUID.getDeviceUUID(ctx);
        deviceName = Build.MANUFACTURER + " " + Build.MODEL;
        systemVer = Build.VERSION.RELEASE;
    }

	public static DevicesInfo getDeviceInfo() {
        if (info == null) {
            info = new DevicesInfo(MainApplication.app);
        }
        return info;
    }

	public String getIMEI(){
		return imei;
	}

}
