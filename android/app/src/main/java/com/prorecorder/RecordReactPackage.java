package com.prorecorder;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.prorecorder.record.AudioFileManager;
import com.prorecorder.record.AudioPlayerReact;
import com.prorecorder.record.AudioReact;
import com.prorecorder.view.ReactWaveChartManager;

import java.util.Arrays;
import java.util.List;

/**
 * Copyright 2018 SpeakIn.Inc
 * Created by west on 2018/8/16.
 */

public class RecordReactPackage implements ReactPackage {


    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        return Arrays.<NativeModule>asList(
                new AudioReact(reactContext),
                new AudioFileManager(reactContext),
                new AudioPlayerReact(reactContext)
        );
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        return Arrays.<ViewManager>asList(
                new ReactWaveChartManager()
        );
    }
}
