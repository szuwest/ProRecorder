package com.prorecorder.record;

import java.io.InputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.BufferedInputStream;
import java.lang.ref.WeakReference;
import java.net.HttpURLConnection;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;

import android.text.TextUtils;
import android.util.Log;
import java.net.URL;

/**
 * Created by west on 2018/07/29.
 *
 */

public class PcmPlayer {
    public final String LOG_TAG = "PcmPlayer";
    public boolean isPlaying = false ,isWav = false;
    private String pcmPath = "";
    private Timer myTimer;
    private CheckProgressTimerTask myTimerTask;
    private AudioTrack audioTrack;
    private InputStream fileStream;
    private int pointOfMs = 10, sampleRate = 16000, oneTimeLength = 0;
    private String playMode = "";
//    private AudioPlayerListener listener;
private List<WeakReference<AudioPlayerListener>> listeners = new ArrayList<>();
    private long playLen,totalLen;
    private int totalMs;
    private byte[] bufferData;
    private int _writeOffset,_readOffset,_maxLen = 320 * 100 * 120;  // 缓存 120s 内容;
    private boolean onlineEOF,reWrite;
    private OnlineDataThread onlineThread;
    private int runThreadId = 0;
    public PcmPlayer(){
        this.setPointOfMs(this.pointOfMs);
    }

    public AudioTrack getAT(){
        int channelConfiguration = AudioFormat.CHANNEL_OUT_MONO;
        return new AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                channelConfiguration,
                AudioFormat.ENCODING_PCM_16BIT,
                oneTimeLength,
                AudioTrack.MODE_STREAM
        );
    }
//
//    public void setPlayerListener(AudioPlayerListener listener) {
//        this.listener = listener;
//    }
    public void addAudioPlayerListener(AudioPlayerListener listener) {
//        if (!listeners.contains(listener)) {
//            listeners.add(new WeakReference<AudioRecorderListener>(listener));
//        }
        boolean contain = false;
        for (int i=0;i<listeners.size(); i++) {
            WeakReference<AudioPlayerListener> wkL = listeners.get(i);
            if (wkL.get() == listener) {
                contain = true;
                break;
            }
        }
        if (!contain) {
            listeners.add(new WeakReference<AudioPlayerListener>(listener));
        }
    }

    public void removeRecordListener(AudioPlayerListener listener) {
        for (int i=0;i<listeners.size(); i++) {
            WeakReference<AudioPlayerListener> wkL = listeners.get(i);
            if (wkL.get() == listener) {
                listeners.remove(wkL);
            }
        }
//        listeners.remove(listener);
    }

    public void setPcmPath(String pcmPath){
        this.pcmPath = pcmPath;
    }

    public void setIsWav(boolean isWav){
        this.isWav = isWav;
    }

    public void setPointOfMs(int pointOfMs){
        this.pointOfMs = pointOfMs;
        oneTimeLength = 16000 *  pointOfMs / 1000 * 2;
    }

    public void log(String msg){
        Log.d(LOG_TAG,msg);
    }

    private void decodeLoop(){
        try {
            if(audioTrack == null || isPlaying == false) return;
            boolean needPlay = false;
            if( playMode == "local" ) needPlay = fileStream.available() > 0 ;
            if( playMode == "online" ) needPlay = onLineDataLen() > 0 ;
            if( needPlay ) {
                byte[] data = new byte[oneTimeLength];
                int readLen;
                if(playMode == "local") {
                    readLen = fileStream.read(data, 0, oneTimeLength);
                } else {
                    readLen = readOnlineData(data, 0, oneTimeLength);
                }
                audioTrack.write(data, 0, readLen);
                playLen += readLen;
//                if (listener != null) {
//                    listener.onPlayData(data, readLen);
//                    listener.onProgress( this.byteToMs(playLen),totalMs );
//                }
                for (int i=0; i<listeners.size(); i++) {
                    WeakReference<AudioPlayerListener> wkL = listeners.get(i);
                    if (wkL.get() != null) {
                        wkL.get().onPlayData(data, readLen);
                        wkL.get().onProgress( this.byteToMs(playLen),totalMs );
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void play(){
        if(audioTrack != null){
            audioTrack.release();
        }
        audioTrack = getAT();
        audioTrack.play();
    }

    public int byteToMs(long byteLen){
        return (int)(byteLen/ 32);
    }

    private boolean playLocalFile(){
        try {
            fileStream = new FileInputStream(this.pcmPath);
            totalLen = ( (FileInputStream)fileStream ).getChannel().size();
            totalLen -= isWav ? 44 : 0;
            totalMs = this.byteToMs( totalLen );
            if(isWav){
                fileStream.read(new byte[44],0,44);
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    private URLConnection playOnlineFile(){
        URLConnection urlconn;
        try{
            URL url =new URL(this.pcmPath);
            urlconn = url.openConnection();
            urlconn.connect();
            int HttpResult = ( (HttpURLConnection) urlconn ).getResponseCode();
            if(HttpResult != HttpURLConnection.HTTP_OK) {
                System.out.print("无法连接到");
                return null;
            } else {
                totalLen = urlconn.getContentLength();
                totalLen -= isWav ? 44 : 0;
                totalMs = this.byteToMs(totalLen);
                fileStream = new BufferedInputStream(urlconn.getInputStream());
            }
        } catch (IOException e){
            e.printStackTrace();
            return null;
        }
        return urlconn;
    }

    public void runTimer(){
        playLen = 0;
        play();
        myTimerTask = new CheckProgressTimerTask();
        myTimer = new Timer();
        myTimer.scheduleAtFixedRate(myTimerTask, 0, pointOfMs);
//        if (listener != null) {
//            listener.onPlayStart();
//        }
        for (int i=0; i<listeners.size(); i++) {
            WeakReference<AudioPlayerListener> wkL = listeners.get(i);
            if (wkL.get() != null) {
                wkL.get().onPlayStart();
            }
        }
        isPlaying = true;
    }

    public void start(){
        if( pointOfMs != 0 && !TextUtils.isEmpty(pcmPath)) {
            reserVar();
            if( pcmPath.substring(0,4).toLowerCase().compareTo("http") == 0) {
                playMode = "online";
                stopOnlineThread();
                onlineThread = new OnlineDataThread();
                onlineThread.start();
            } else {
                playMode = "local";
                if(playLocalFile()) {
                    runTimer();
                }
            }
        } else {
            log("pointOfMs or pcmPath not set");
        }
    }

    public void reserVar(){
        if (myTimer != null) {
            myTimer.cancel();
            myTimer = null;
        }
        if (myTimerTask != null) {
            myTimerTask.cancel();
            myTimerTask = null;
        }
        onlineEOF = false;
        _writeOffset = 0;
        _readOffset = 0;
        bufferData = null;
        if(audioTrack != null){
            audioTrack.stop();
            audioTrack.release();
            audioTrack = null;
        }
    }

    public void stopOnlineThread(){
        if(onlineThread != null && onlineThread.isAlive()){
            onlineThread.isStop = true;
            onlineThread.interrupt();
            onlineThread = null;
        }
    }

    public void stop(){
//        if(listener != null){
//            listener.onPlayEnd();
//        }
        for (int i=0; i<listeners.size(); i++) {
            WeakReference<AudioPlayerListener> wkL = listeners.get(i);
            if (wkL.get() != null) {
                wkL.get().onPlayEnd();
            }
        }
        if(audioTrack != null) audioTrack.stop();
        reserVar();
        isPlaying = false;
    }

    private int onLineDataLen(){
        if( reWrite && _writeOffset == _readOffset ) return _maxLen;
        if( _readOffset > _writeOffset){
            return _maxLen - _readOffset + _writeOffset;
        } else {
            return _writeOffset - _readOffset;
        }
    }
    private int readOnlineData(byte[] out,int offset,int len){
        int arrowReadLen = onLineDataLen();
        len = arrowReadLen > len ? len : arrowReadLen;
        if( len % 2 == 1 ) len -= 1;
        if(len == 0) return 0;
        if( _readOffset >= _writeOffset ){
            if( _maxLen - _readOffset > len ){
                System.arraycopy(bufferData,_readOffset,out,offset,len);
                _readOffset += len;
            } else {
                int onceReadLen = _maxLen - _readOffset;
                System.arraycopy(bufferData,_readOffset,out,offset,onceReadLen);
                System.arraycopy(bufferData,0,out, onceReadLen, len - onceReadLen );
                _readOffset = len - onceReadLen;
                reWrite = false;
            }
        } else {
            System.arraycopy(bufferData,_readOffset,out,offset,len);
            _readOffset += len;
        }
        return len;
    }
    public interface AudioPlayerListener {
        void onPlayStart();
        void onPlayEnd();
        void onPlayData(byte[] recordData, int length);
        void onProgress(int ms, int totalMs);
    }

    private class OnlineDataThread extends Thread{
        public boolean isStop;
        @Override
        public void run() {
            isStop = false;
            onlineEOF = false;
            _writeOffset = 0;
            _readOffset = isWav ? 44 : 0;
            reWrite = false;
            bufferData = new byte[ _maxLen ];
            int readLen,nextReadLen = oneTimeLength;
            int _runThreadId = ++runThreadId;
            URLConnection urlconn = playOnlineFile();
            if( urlconn != null ) runTimer(); else  return ;
            long needDownLoadLen = totalLen;

            while (true){
                if(_runThreadId != runThreadId) { break;}
                try {
                    if( isStop ) {
                        if( fileStream != null ){
                            fileStream.close();
                            fileStream = null;
                        }
                        break;
                    }
                    if( _writeOffset + nextReadLen > _maxLen ) nextReadLen = _maxLen - _writeOffset;
                    if(  ( _writeOffset +  nextReadLen > _readOffset ||  _writeOffset == _readOffset  ) && reWrite ) {
                        continue;
                    }
                    readLen = fileStream.read(bufferData , _writeOffset , nextReadLen);
                    if( readLen == -1 ) {
                        if(needDownLoadLen <= 0) {
                            break;
                        }
                    } else {
                        needDownLoadLen -= readLen;
                        _writeOffset += readLen;
                    }
                    nextReadLen = oneTimeLength;
                    if( _writeOffset == _maxLen ) {
                        reWrite = true;
                        _writeOffset = 0;
                    }
                } catch (IOException e){}
                catch (NullPointerException e){}
            }
            ((HttpURLConnection) urlconn).disconnect();
            if(_runThreadId == runThreadId) {
                onlineEOF = true;
            }
        }
    }
    private class CheckProgressTimerTask extends TimerTask {
        @Override
        public void run() {
            if(playMode == "local") {
                try { if (fileStream.available() <= 0) stop(); }
                catch (IOException e){ e.printStackTrace(); }
                decodeLoop();
            } else if(playMode == "online") {
                if( !onlineEOF || onLineDataLen() > 0 ){
                    decodeLoop();
                } else {
                    stop();
                }
            }
        }
    }
}

