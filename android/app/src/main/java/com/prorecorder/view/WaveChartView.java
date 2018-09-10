package com.prorecorder.view;

/**
 *
 * Created by west on 2017/11/21.
 */

import android.graphics.Canvas;

import android.os.Bundle;
import android.view.View;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.util.Log;


import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.prorecorder.MainApplication;
import com.prorecorder.record.AudioRecorder;
import com.prorecorder.record.PcmPlayer;

import javax.annotation.Nullable;
import java.nio.ByteOrder;
import java.util.HashMap;
import java.util.ArrayList;
import android.os.Handler;
import android.os.Message;

import java.nio.ByteBuffer;
import java.util.List;

class DataPoint{
    public int min,max;
    public DataPoint(){}
    public DataPoint( List<Integer> list){
        min = max  = list.get(0);
        for(int i:list){
            if(i > max) max = i;
            if(i < min) min = i;
        }
    }
}

class WaveChartViewListener implements AudioRecorder.AudioRecorderListener,PcmPlayer.AudioPlayerListener {

    public WaveChartView waveChartView;
    private int maxPoint = 16000 / 1000 * 400;
    private List<Integer> dataList = new ArrayList();
    private String listenMode;

    public short[] byteArray2ShortArray(byte[] data, int items) {
        ByteBuffer bf = ByteBuffer.wrap(data);
        bf.order(ByteOrder.LITTLE_ENDIAN);
        short[] retVal = new short[items];
        for (int i=0;i<items;i++) {
            retVal[i]= bf.getShort();
        }
        return retVal;
    }

    public void setPointOfMs(int pointOfMs){
        this.maxPoint = 16000 / 1000 * pointOfMs;
    }

    public WaveChartViewListener(WaveChartView waveChartView,int pointOfMs,String listenMode) {
        this.waveChartView = waveChartView;
        setPointOfMs(pointOfMs);
        this.listenMode = listenMode;
    }

    public void onRecordStart() {
        Log.d("WaveChartViewListener","onRecordStart");
        if( listenMode == "isRecord" ){
            waveChartView.recordStatus = true;
        } else {
            waveChartView.playStatus = true;
        }
        waveChartView.handler.post(new Runnable() {
            @Override
            public void run() {
                waveChartView.setReset(true);
            }
        });
        sendEvent(listenMode == "isRecord" ? "recordStart":"playStart",new HashMap());
    }

    public void onAudioError(int errCode, String msg) {}

    public void onVolumeChange(double volume) { }

    public void onRecordEnd(String filePath, boolean isCancel) {
        if( listenMode == "isRecord" ){
            waveChartView.recordStatus = false;
        } else {
            waveChartView.playStatus = false;
        }
        HashMap keymap = new HashMap();
        if (isCancel) {
            keymap.put("filePath", "cancel");
        } else {
            keymap.put("filePath", filePath);
        }
        sendEvent(listenMode == "isRecord" ? "recordEnd":"playStop",keymap);
    }

    public void sendEvent(String EventName, HashMap<String,String> kayMap){
        WritableMap event = Arguments.createMap();
        event.putString("eventName", EventName);
        for(String key:kayMap.keySet()){
            event.putString(key, kayMap.get(key));
        }
        Log.d("sendEvent",EventName);
        ((ReactContext)waveChartView.getContext()).getJSModule(RCTEventEmitter.class)
                .receiveEvent(waveChartView.getId(), "topMessage", event);
    }

    public void onRecordData(byte[] recordData,int length){
        List<DataPoint> list  = new ArrayList();
        short[] outData = this.byteArray2ShortArray(recordData,length/2);
        for (int i = 0; i < outData.length; i++) {
            dataList.add( (int)outData[i] );
            if(dataList.size() == maxPoint){
                list.add(new DataPoint(dataList));
                dataList.clear();
            }
        }
        waveChartView.handler.sendMessage( getMsg( list ) );
    }

    public Message getMsg(List<DataPoint> list){
        Message msg = new Message();
        Bundle data = new Bundle();
        int[] max = new int[list.size()],min =new int[list.size()];
        int idx=0;
        for(DataPoint p:list){
            max[idx] = p.max;
            min[idx] = p.min;
            idx++;
        }
        data.putIntArray("minArr",min);
        data.putIntArray("maxArr",max);
        msg.setData(data);
        return msg;
    }

    public void onPlayStart(){
        onRecordStart();
    }

    public void onPlayEnd(){
        onRecordEnd("", false);
    }

    public void onPlayData(byte[] recordData,int length){
        onRecordData(recordData,length);
    }

    public void onProgress(int ms,int totalMs){
        HashMap keymap = new HashMap();
        keymap.put("ms",String.valueOf(ms));
        keymap.put("totalMs",String.valueOf(totalMs));
        sendEvent("playProgress",keymap);
    }
}

public class WaveChartView extends View {
    public boolean recordStatus = false,playStatus = false;
    private boolean  needInit= true;
    private int lineColor = Color.parseColor("#999999"),bgColor = Color.parseColor("#000000");
    private Paint paint = null;
    private Path path = null;
    private List<DataPoint> pointData = null;
    private AudioRecorder audioRecorder;
    private PcmPlayer pcmPlayer;
    private int width,height,halfHeight,pointOfMs=10;
    public Handler handler= null;
    private String pcmPath = "";
    private boolean drawUI = true ,isWav = false;

    public WaveChartView(ThemedReactContext context) {
        super(context);
        Log.d("WaveChartView","WaveChartView");
        pointData = new ArrayList();
        handler = new Handler() {
            public void handleMessage(Message msg) {
                if( drawUI && (recordStatus == true || playStatus == true) ) {
                    int[] max = msg.getData().getIntArray("maxArr");
                    int[] min = msg.getData().getIntArray("minArr");
                    List<DataPoint> list = new ArrayList();
                    for (int i = 0; i < max.length; i++) {
                        DataPoint p = new DataPoint();
                        p.max = max[i];
                        p.min = min[i];
                        list.add(p);
                    }
                    drawWave(list);
                }
            }
        };
        setPaint(lineColor);
        path = new Path();
        needInit = true;
        audioRecorder = MainApplication.app.audioRecorder;
        audioRecorder.addAudioRecorderListener(waveChartViewListener);
        pcmPlayer = MainApplication.app.audioPlayer;
        pcmPlayer.addAudioPlayerListener(waveChartViewListener2);
//        audioRecorder.setSaveWavFile(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if( drawUI ) {
            width = getWidth();
            height = getHeight();
            halfHeight = height / 2;
            if (needInit) initWave();
            canvas.drawColor(bgColor);
            canvas.drawPath(path, paint);
            super.onDraw(canvas);
        }
    }

    public void finalize( ){
        Log.d("WaveChartView","finalize");
        finalizeRecode();
    }

    private void finalizeRecode(){
        audioRecorder.removeRecordListener(waveChartViewListener);
        pcmPlayer.removeRecordListener(waveChartViewListener2);
    }

    public void drawWave(final List<DataPoint> point){
        while (pointData.size() > 0 && pointData.size() > width - 40 - point.size()) {
            pointData.remove(0);
        }
        for (int i = 0; i < point.size(); i++) {
            DataPoint t = new DataPoint();
            t.min = (point.get(i).min * halfHeight / 32768) + halfHeight;
            t.max = (point.get(i).max * halfHeight / 32768) + halfHeight;
            pointData.add(t);
        }
        path.reset();
        int idx = 0;
        for (DataPoint p : pointData) {
            if (p.max == p.min) {
                path.moveTo(idx, halfHeight);
                path.lineTo(idx + 1, halfHeight);
            } else {
                path.moveTo(idx, p.max);
                path.lineTo(idx, p.min);
            }
            idx++;
        }
        if( idx == 0 ) path.moveTo(0, halfHeight);
        path.lineTo(idx + 1, halfHeight);
        path.lineTo(width, halfHeight);
        invalidate();
    }

    private void initWave(){
        needInit = false;
        path.reset();
        path.moveTo(0,halfHeight);
        path.lineTo(width,halfHeight);
        path.close();
    }

    private void setPaint(int lineColor){
        paint = new Paint();
        paint.setColor(lineColor);
        paint.setStyle(Paint.Style.STROKE);
        paint.setAntiAlias(true);
        paint.setStrokeWidth(1);
    }

    public void setLineColor(@Nullable Integer lineColor){
        setPaint(lineColor);
        invalidate();
    }

    public void setPcmPath(@Nullable String pcmPath){
        Log.d("WaveChartView",pcmPath);
        this.pcmPath = pcmPath;
    }

    WaveChartViewListener waveChartViewListener2 = new WaveChartViewListener(this, pointOfMs, "isPlay");
    public String listenOnPlay(@Nullable Boolean play){
        pointData.clear();
        drawWave(new ArrayList());
        if (play) {
            if (this.pcmPath.length() == 0) {
                return "need pcm Data";
            } else {
                pcmPlayer.addAudioPlayerListener(waveChartViewListener2);
                pcmPlayer.setPointOfMs(pointOfMs);
                pcmPlayer.setPcmPath(this.pcmPath);
                pcmPlayer.setIsWav(this.isWav);
                return "start listen";
            }
        } else {
            pcmPlayer.removeRecordListener(waveChartViewListener2);
            return "stop listen";
        }
    }

    WaveChartViewListener waveChartViewListener = new WaveChartViewListener(this,pointOfMs,"isRecord");
    public void listenOnRecord(@Nullable Boolean record){
       pointData.clear();
       drawWave(new ArrayList());
       if(record){
           audioRecorder.addAudioRecorderListener(waveChartViewListener);
       } else {
           audioRecorder.removeRecordListener(waveChartViewListener);
       }
    }

    public void setPointOfMs(@Nullable Integer pointOfMs){
        this.pointOfMs = pointOfMs;
        waveChartViewListener.setPointOfMs(pointOfMs);
    }

    public void setNeedDrawUI(@Nullable Boolean drawUI){
        this.drawUI = drawUI;
    }

    public void setIsWav(@Nullable Boolean isWav){
        this.isWav = isWav;
    }

    public void setBgColor(@Nullable Integer bgColor) {
        this.bgColor = bgColor;
    }

    public void setReset(Boolean isReset) {
        Log.d("WaveChartView", "isReset=" + isReset);
        if (isReset) {
            pointData.clear();
            drawWave(new ArrayList());
        }
    }
}
