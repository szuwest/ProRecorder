package com.prorecorder.record;

import android.text.TextUtils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.prorecorder.MainApplication;

import java.io.File;

/**
 * Copyright 2018 SpeakIn.Inc
 * Created by west on 2018/8/20.
 */

public class AudioPlayerReact extends ReactContextBaseJavaModule implements PcmPlayer.AudioPlayerListener {

    private PcmPlayer pcmPlayer;
    public AudioPlayerReact(ReactApplicationContext reactContext) {
        super(reactContext);
        pcmPlayer = MainApplication.app.audioPlayer;
        pcmPlayer.addAudioPlayerListener(this);
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        pcmPlayer.removeRecordListener(this);
    }

    @Override
    public String getName() {
        return "AudioPlayer";
    }

    @ReactMethod
    public void play(String filePath, Promise promise) {
        if (TextUtils.isEmpty(filePath) || !new File(filePath).exists()) {
            promise.reject("-1", "file not exist!");
            return;
        }
        pcmPlayer.setPcmPath(filePath);
        pcmPlayer.setIsWav(filePath.toLowerCase().endsWith(".wav"));
        pcmPlayer.start();
        promise.resolve("");
    }

    @ReactMethod
    public void stop(Promise promise) {
        if (pcmPlayer.isPlaying) {
            pcmPlayer.stop();
        }
        promise.resolve("");
    }

    @Override
    public void onPlayStart() {

    }

    @Override
    public void onPlayEnd() {
        WritableMap params = Arguments.createMap();
        params.putInt("code", 1);
        //发送一个js事件onAudioError
        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onAudioPlayDidStop", params);
    }

    @Override
    public void onPlayData(byte[] recordData, int length) {

    }

    @Override
    public void onProgress(int ms, int totalMs) {
        WritableMap params = Arguments.createMap();
        params.putInt("progress", ms);
        params.putInt("total", totalMs);
        //发送一个js事件onAudioError
        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onAudioPlayProgressChanged", params);
    }
}
