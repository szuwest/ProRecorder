package com.prorecorder.record;

import android.os.Environment;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.prorecorder.record.utils.FileUtils;

import java.io.File;

/**
 * 音频文件管理
 * Copyright 2017 SpeakIn.Inc
 * Created by west on 2017/10/27.
 */

public class AudioFileManager extends ReactContextBaseJavaModule {

    public AudioFileManager(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "AudioFileManager";//JS中的模块名
    }

    /**
     * 删除某个音频文件或文件夹
     * @param filePath
     * @param promise
     */
    @ReactMethod
    public void deleteFile(final String filePath, final Promise promise) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                FileUtils.deleteFile(new File(filePath));
                promise.resolve(null);
            }
        }).start();
    }

    /**
     * 删除一系列文件
     * @param filesArray 文件路径数组
     * @param promise
     */
    @ReactMethod
    public void deleteFiles(final ReadableArray filesArray, final Promise promise) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                for (int i=0; i<filesArray.size(); i++) {
                    String filePath = filesArray.getString(i);
                    FileUtils.deleteFile(new File(filePath));
                }
                promise.resolve(null);
            }
        }).start();
    }

    /**
     * 删除某个人的所有音频文件
     * @param teamId
     * @param taskId
     * @param personIndex
     * @param promise
     */
    @ReactMethod
    public void deletePersonAudioDir(String teamId, String taskId, int personIndex, final Promise promise) {
        final String filePath = getPersonAudioDir(teamId, taskId, personIndex);
        new Thread(new Runnable() {
            @Override
            public void run() {
                FileUtils.deleteFile(new File(filePath));
                promise.resolve(null);
            }
        }).start();
    }

    /**
     * 删除某个任务的所有音频文件
     * @param teamId
     * @param taskId
     * @param promise
     */
    @ReactMethod
    public void deleteTaskFiles(String teamId, String taskId, final Promise promise) {
        final String filePath = getTaskAudioDir(teamId, taskId);
        new Thread(new Runnable() {
            @Override
            public void run() {
                FileUtils.deleteFile(new File(filePath));
                promise.resolve(null);
            }
        }).start();
    }

    @ReactMethod
    public void listFileInDoc(String path, Promise promise) {
        String recordDir = Environment.getExternalStorageDirectory() + "/" + path;
        File recordDirFile = new File(recordDir);
        File[] files = recordDirFile.listFiles();
        WritableArray wavFiles = Arguments.createArray();
        if (files != null && files.length > 0) {
            for (File file : files) {
                if (file.isFile() && file.getName().toLowerCase().endsWith(".wav")) {
                    wavFiles.pushString(file.getAbsolutePath());
                }
            }
        }
        promise.resolve(wavFiles);
    }


    ////////一下是内部方法

    /**
     * ..../teamid/taskid/personIndex/voiceindex/
     */
    public static String getVoiceFileDir(String teamId, String taskId, int personIndex, int voiceIndex) {
        String filePath = getPersonAudioDir(teamId, taskId, personIndex) + voiceIndex + "/";
        File file = new File(filePath);
        if (!file.exists())file.mkdirs();
        return filePath;
    }

    /**
     * ..../teamid/taskid/personIndex/
     */
    public static String getPersonAudioDir(String teamId, String taskId, int personIndex) {
        return getTaskAudioDir(teamId,taskId) + personIndex + "/";
    }

    /**
     * ..../teamid/taskid/
     */
    public static String getTaskAudioDir(String teamId, String taskId) {
        return ControlConstants.ROOT + teamId + "/" + taskId + "/";
    }

}
