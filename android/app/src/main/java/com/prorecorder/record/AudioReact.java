package com.prorecorder.record;

import android.Manifest;
import android.content.Context;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.prorecorder.MainApplication;
import com.prorecorder.record.utils.DevicesInfo;
import com.prorecorder.record.utils.PermissionsChecker;

public class AudioReact extends ReactContextBaseJavaModule {
    public String getName() {
        return "AudioRecorder";
    }

    Context mContext;
    Promise startPromise, stopPromise;
    private AudioRecorder audioRecorder;
    private PermissionsChecker permissionsChecker;
    private RecorderListener listener = new RecorderListener(this);

    public AudioReact(ReactApplicationContext reactContext) {
        super(reactContext);
        mContext = reactContext;
        audioRecorder = MainApplication.app.audioRecorder;
        audioRecorder.addAudioRecorderListener(listener);
        audioRecorder.setSaveWavFile(true);
        permissionsChecker = new PermissionsChecker(reactContext);
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        audioRecorder.removeRecordListener(listener);
    }

    /**
     * 获取手机唯一标识
     * @param promise
     */
    @ReactMethod
    public void getIMEI(Promise promise) {
        promise.resolve(DevicesInfo.getDeviceInfo().imei);
    }

    /**
     * 获取这一次录音数据的总大小
     * @param promise
     */
    @ReactMethod
    public void getDataLength(Promise promise) {
        promise.resolve(String.valueOf(audioRecorder.getDataLength()));
    }

    /**
     * 采用默认参数录音
     * @param promise
     */
    public void startRecord(Promise promise) {
        if (!Environment.getExternalStorageState().equals( Environment.MEDIA_MOUNTED)) {
            //sdcard状态是没有挂载的情况
            promise.reject("-100", "没有SD卡，无法进行录音存储");
            return ;
        }
        if (permissionsChecker.lacksPermissions(Manifest.permission.RECORD_AUDIO)) {
            promise.reject("-1", "未开启录音权限，无法进行录音。请到【设置】--【应用程序管理】--找到应用开启录音权限");
            return ;
        }
        audioRecorder.startRecord();
        this.startPromise = promise;
    }

    /**
     * 开始录音
     * @param sampleRate 指定采样率
     * @param bitPerSample 指定采样精度
     * @param channel 声道数
     * @param promise
     */
    @ReactMethod
    public void startRecord2(int sampleRate, int bitPerSample, int channel, Promise promise) {
        if (!Environment.getExternalStorageState().equals( Environment.MEDIA_MOUNTED)) {
            //sdcard状态是没有挂载的情况
            promise.reject("-100", "没有SD卡，无法进行录音存储");
            return ;
        }
        if (permissionsChecker.lacksPermissions(Manifest.permission.RECORD_AUDIO)) {
            promise.reject("-1", "未开启录音权限，无法进行录音。请到【设置】--【应用程序管理】--找到应用开启录音权限");
            return ;
        }
        audioRecorder.startRecord(sampleRate, bitPerSample, channel);
        this.startPromise = promise;
    }

    /**
     *  停止录音
     */
    @ReactMethod
    public void stopRecord(Promise promise) {
        audioRecorder.stopRecord();
        stopPromise = promise;
    }

    /**
     * 暂停录音
     */
    @ReactMethod
    public void pauseRecord() {
        audioRecorder.pause();
    }

    /**
     * 恢复录音
     */
    @ReactMethod
    public void resumeRecord() {
        audioRecorder.resume();
    }

    /**
     * 获取录音权限
     * @param promise
     */
    @ReactMethod
    public void checkAndRequestAudio(final Promise promise) {
        audioRecorder.startRecord();
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                if (!lackOfPermission()){
                    return;
                }
                if (((ReactApplicationContext)mContext).getCurrentActivity() != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        ((ReactApplicationContext) mContext).getCurrentActivity().requestPermissions(
                                new String[]{Manifest.permission.RECORD_AUDIO,Manifest.permission.READ_PHONE_STATE, Manifest.permission.WRITE_EXTERNAL_STORAGE,
                                        Manifest.permission.READ_EXTERNAL_STORAGE}, 1);
                    }
                }
            }
        });
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                audioRecorder.stopRecord();
                if (promise != null) promise.resolve(null);
            }
        }, 500);
    }

    private boolean lackOfPermission() {
        return permissionsChecker.lacksPermissions(Manifest.permission.RECORD_AUDIO, Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.READ_PHONE_STATE, Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }

    private byte[] recordedData = new byte[0];
    class RecorderListener implements AudioRecorder.AudioRecorderListener {
        private AudioReact audioReact;

        public RecorderListener(AudioReact audioReact) {
            this.audioReact = audioReact;
        }

        public void onRecordStart() {
            if (audioReact.startPromise != null) {
                audioReact.startPromise.resolve(null);
            }
            audioReact.startPromise = null;
        }

        public void onAudioError(int errCode, String msg) {
            WritableMap params = Arguments.createMap();
            params.putInt("errCode", errCode);
            params.putString("errMsg", msg);
            //发送一个js事件onAudioError
            ((ReactContext)audioReact.mContext).getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("onAudioError", params);
        }

        public void onVolumeChange(double volume) {

        }

        public void onRecordData(byte[] recordData,int length) {
//            synchronized (this) {
//                byte[] newData = new byte[recordedData.length + length];
//                System.arraycopy(recordedData, 0, newData, 0, recordedData.length);
//                System.arraycopy(recordData, 0, newData, recordedData.length, length);
//                recordedData = newData;
//            }
        }

        public void onRecordEnd(final String filePath) {
            if (audioReact.stopPromise != null) {
                audioReact.stopPromise.resolve(filePath);
            }
            audioReact.stopPromise = null;
        }
    }
}
