package com.prorecorder.record;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

/**
 * 录音类
 * Created by west 2017/7/28.
 */
public class AudioRecorder {

    public interface AudioRecorderListener {
        void onRecordStart();

        void onAudioError(int errCode, String msg);

        void onVolumeChange(double volume);

        void onRecordEnd(String filePath, boolean isCancel);

        void onRecordData(byte[] recordData, int length);
    }

    private static final String TAG = AudioRecorder.class.getSimpleName();

    //录音配置参数
    //釆波率  8000, 11025, 16000, 22050, 32000,44100, 47250, 48000
    public static final int SAMPLE_RATE_IN_HZ = 16000;
    public static final int AUDIOROUCE = MediaRecorder.AudioSource.MIC;
    public static final int CHANNEL_IN = AudioFormat.CHANNEL_IN_MONO;
    public static final int ENCODING_PCM = AudioFormat.ENCODING_PCM_16BIT;
    //录音保存地址
    public final static String ROOT_PATH = Environment.getExternalStorageDirectory() + "/ProRecorder/";
    public final static String RECORD_DIR = ROOT_PATH;

    private static final int VOL_GET_INTERVAL = 100;

    private int minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE_IN_HZ, CHANNEL_IN, ENCODING_PCM);

    private AudioRecord mAudioRecord;
    // 录音运行控制开关bool
    private volatile boolean isRecording = false;
    private volatile boolean cancelRecord = false;
    private volatile boolean isPaused = false;

    public int getSampleRate() {
        return sampleRate;
    }

    public void setSampleRate(int sampleRate) {
        if (sampleRate < 8000) {
            Log.e(TAG, "采样率过低");
            return;
        }
        if (sampleRate > 48000) {
            Log.e(TAG, "采样率过高");
            return;
        }
        this.sampleRate = sampleRate;
    }

    public int getEncodingBit() {
        return encodingBit;
    }

    public void setEncodingBit(int encodingBit) {

        if (encodingBit != 24 && encodingBit != 16) {
            Log.e(TAG, "暂时只支持16或者24");
            return;
        }
        this.encodingBit = encodingBit;
    }

    //釆波率  8000, 11025, 16000, 22050, 32000,44100, 47250, 48000
    private int sampleRate = SAMPLE_RATE_IN_HZ;
    //采样精度
    private int encodingBit = 16;
    //声道，1为单声道，2为双声道
    private int channel = 1;

    public int getChannel() {
        return channel;
    }

    public void setChannel(int channel) {
        if (channel != 1 && channel != 2) {
            Log.e(TAG, "只支持1或2");
            return;
        }
        this.channel = channel;
    }



    // 用于实时显示音量大小的图标
    private double voiceValue = 0.0; // 麦克风获取的音量值
    private ArrayList<Double> voiceList = new ArrayList<>();//存放音量变化列表，用户计算平均音量

    private long dataLength = 0;

    public boolean isSaveWavFile() {
        return saveWavFile;
    }

    public void setSaveWavFile(boolean saveWavFile) {
        this.saveWavFile = saveWavFile;
    }

    private boolean saveWavFile = true;

    private List<WeakReference<AudioRecorderListener>> listeners = new ArrayList<>();

    public void addAudioRecorderListener(AudioRecorderListener listener) {
//        if (!listeners.contains(listener)) {
//            listeners.add(new WeakReference<AudioRecorderListener>(listener));
//        }
        boolean contain = false;
        for (int i=0;i<listeners.size(); i++) {
            WeakReference<AudioRecorderListener> wkL = listeners.get(i);
            if (wkL.get() == listener) {
                contain = true;
                break;
            }
        }
        if (!contain) {
            listeners.add(new WeakReference<AudioRecorderListener>(listener));
        }
    }

    public void removeRecordListener(AudioRecorderListener listener) {
        for (int i=0;i<listeners.size(); i++) {
            WeakReference<AudioRecorderListener> wkL = listeners.get(i);
            if (wkL.get() == listener) {
                listeners.remove(wkL);
            }
        }
//        listeners.remove(listener);
    }

    public AudioRecorder() {
    }

    public void startRecord() {
        startRecord(SAMPLE_RATE_IN_HZ, 16);
    }

    public void startRecord(int sampleRate, int encodingBit) {
        startRecord(sampleRate, encodingBit, 1);
    }

    public synchronized void startRecord(int sampleRate, int encodingBit, int channel) {
        if (isPaused) {
            Log.e(TAG, "录音暂停中，请调用resume恢复录音");
            return;
        }
        dataLength = 0;
        File file1 = new File(RECORD_DIR);
        if (!file1.exists()) {
            file1.mkdirs();
        }
        if (isRecording) {
            Log.d(TAG, "还在录着呢");
            return;
        }
        setSampleRate(sampleRate);
        setEncodingBit(encodingBit);
        setChannel(channel);

        int encoding_type = ENCODING_PCM;
        if (this.encodingBit == 24) {
            encoding_type = AudioFormat.ENCODING_PCM_FLOAT;
        }
        int channelType = CHANNEL_IN;
        if (this.channel == 2) {
            channelType = AudioFormat.CHANNEL_IN_STEREO;
        }
        minBufferSize = AudioRecord.getMinBufferSize(this.sampleRate, channelType, encoding_type);
        voiceValue = 0.0;
        mAudioRecord = new AudioRecord(AUDIOROUCE, this.sampleRate, channelType, encoding_type, minBufferSize);
        isRecording = true;
        cancelRecord = false;
        voiceList.clear();
        // 启动线程，录制音频文件
        Thread audioThread = new Thread(saveRunnable);
        audioThread.start();
    }

    public synchronized void stopRecord() {
        isPaused = false;
        isRecording = false;
    }

    public synchronized void cancelRecord() {
        this.cancelRecord = true;
        this.isRecording = false;
        isPaused = false;
        voiceList = new ArrayList<>();
    }

    //这里并没有真正的暂停录音，录音还在后台进行，只是不再回调录音数据，不再写录音数据进入文件
    public synchronized void pause() {
        if (isRecording() && !isPaused) {
            isPaused = true;
        }
    }

    public synchronized void resume() {
        if (!isRecording() && mAudioRecord != null) {
            isPaused = false;
        }
    }

    public long getDataLength() {
        return dataLength;
    }

    private Runnable saveRunnable = new Runnable() {
        @Override
        public void run() {
            String audioPath = null;
            String wavPath = null;
            String pcmName = null;
            String wavName = null;
            try {
                if (mAudioRecord == null || cancelRecord) {
                    return;
                }
                mAudioRecord.startRecording();
            } catch (IllegalStateException e) {
                e.printStackTrace();
                Message message = Message.obtain();
                message.what = 2;
                message.arg1 = -1;
                message.obj = e.getMessage();
                recorderHandle.sendMessage(message);
                return;
            }
            byte[] audiodata = new byte[minBufferSize];
            FileOutputStream fos = null;
            try {
                pcmName = System.currentTimeMillis() / 1000 + ".pcm";
                wavName = System.currentTimeMillis() / 1000 + ".wav";
                audioPath = RECORD_DIR  + pcmName;
                File file = new File(audioPath);
                if (file.exists()) {
                    file.delete();
                }
                fos = new FileOutputStream(file);// 建立一个可存取字节的文件
            } catch (Exception e) {
                e.printStackTrace();
                Message message = Message.obtain();
                message.what = 2;
                message.arg1 = -2;
                message.obj = e.getMessage();
                recorderHandle.sendMessage(message);
                return;
            }
            int readsize = 0;
            Log.d(TAG, "开始录制作音频！");

            Message startMsg = Message.obtain();
            startMsg.what = 0;
            recorderHandle.sendMessage(startMsg);

            long start = System.currentTimeMillis();
            while (isRecording) {
                // 保存文件
                if (mAudioRecord == null) {
                    return;
                }
                readsize = mAudioRecord.read(audiodata, 0, minBufferSize);

                if (isPaused) {//暂停中,不保存不回调
                    continue;
                }
                if (readsize > 0) {
                    try {
                        fos.write(audiodata);
                        for (int i=0; i<listeners.size(); i++) {
                            WeakReference<AudioRecorderListener> wkL = listeners.get(i);
                            if (wkL.get() != null) {
                                wkL.get().onRecordData(audiodata, readsize);
                            }
//                            listeners.get(i).onRecordData(audiodata,readsize);
                        }

                        dataLength += readsize;
                    } catch (IOException e) {
                        e.printStackTrace();
                        Message message = Message.obtain();
                        message.what = 2;
                        message.arg1 = -5;
                        message.obj = e.getMessage();
                        recorderHandle.sendMessage(message);
                        break;
                    }
                }
                if ((readsize > 0) && (audiodata.length > 0)) {
                    voiceValue = getVolumeMax(readsize, audiodata);
                    voiceList.add(voiceValue);
                } else {
                    voiceValue = 0.0;
                }
                if (System.currentTimeMillis() - start > VOL_GET_INTERVAL) {
                    Message message = Message.obtain();
                    message.what = 1;
                    message.obj = Math.abs(voiceValue / 1000);
                    recorderHandle.sendMessage(message);
                }
            }
            voiceValue = 0.0;
            Log.d(TAG, "录制结束！");
            try {
                fos.close();// 关闭写入流
            } catch (IOException e) {
                e.printStackTrace();
            }
            try {
                if (mAudioRecord != null) {
                    mAudioRecord.stop();
                    mAudioRecord.release();
                }
            } catch (IllegalStateException e) {
                e.printStackTrace();
            }
            isRecording = false;
            mAudioRecord = null;

            if (cancelRecord) {
                deleteFile(new File(audioPath));
                return;
            }
            if (saveWavFile) {
                wavPath = RECORD_DIR + wavName;
                Log.d(TAG, "开始压缩wav！");
                copyWaveFile(audioPath, wavPath);// 给裸数据加上头文件
                Log.d(TAG, "压缩wav成功！");
                deleteFile(new File(audioPath));
            }


            Message msg = Message.obtain();
            msg.obj = saveWavFile ? wavPath : audioPath;
            msg.what = 3;
            recorderHandle.sendMessage(msg);
        }
    };

    private int getVolumeMax(int r, byte[] bytes_pkg) {
        int mShortArrayLenght = r / 2;
        short[] short_buffer = byteArray2ShortArray(bytes_pkg,
                mShortArrayLenght);
        int max = 0;
        if (r > 0) {
            for (int i = 0; i < mShortArrayLenght; i++) {
                if (Math.abs(short_buffer[i]) > max) {
                    max = Math.abs(short_buffer[i]);
                }
            }
        }
        return max;
    }

    private short[] byteArray2ShortArray(byte[] data, int items) {
        short[] retVal = new short[items];
        for (int i = 0; i < retVal.length; i++)
            retVal[i] = (short) ((data[i * 2] & 0xff) | (data[i * 2 + 1] & 0xff) << 8);
        return retVal;
    }

    // 这里得到可播放的音频文件
    private void copyWaveFile(String inFilename, String outFilename) {
        FileInputStream in = null;
        FileOutputStream out = null;
        long totalAudioLen = 0;
        long totalDataLen = totalAudioLen + 36;
        byte[] data = new byte[minBufferSize];
        try {
            in = new FileInputStream(inFilename);
            out = new FileOutputStream(outFilename);
            totalAudioLen = in.getChannel().size();
            totalDataLen = totalAudioLen + 36;
            WriteWaveFileHeader(out, totalAudioLen, totalDataLen,
                    this.sampleRate, this.channel, this.encodingBit);
            while (in.read(data) != -1) {
                out.write(data);
            }
            in.close();
            out.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void writeWaveFile(byte[] pcmData, String outWavFilePath, int sampleRate, int encodingBit, int channel) {
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(outWavFilePath);
            long totalAudioLen = pcmData.length;
            long totalDataLen = totalAudioLen + 36;
            WriteWaveFileHeader(out, totalAudioLen, totalDataLen,
                    sampleRate, channel, encodingBit);
            out.write(pcmData);
            out.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public boolean isRecording() {
        return isRecording;
    }

    /**
     * 这里提供一个头信息。插入这些信息就可以得到可以播放的文件。 为我为啥插入这44个字节，这个还真没深入研究，不过你随便打开一个wav
     * 音频的文件，可以发现前面的头文件可以说基本一样哦。每种格式的文件都有 自己特有的头文件。
     */
    private static void WriteWaveFileHeader(FileOutputStream out, long totalAudioLen,
                                     long totalDataLen, int sampleRate, int channel, int encodingBit)
            throws IOException {
        long byteRate = sampleRate * encodingBit * channel / 8;
        byte[] header = new byte[44];
        header[0] = 'R'; // RIFF/WAVE header
        header[1] = 'I';
        header[2] = 'F';
        header[3] = 'F';
        header[4] = (byte) (totalDataLen & 0xff);
        header[5] = (byte) ((totalDataLen >> 8) & 0xff);
        header[6] = (byte) ((totalDataLen >> 16) & 0xff);
        header[7] = (byte) ((totalDataLen >> 24) & 0xff);
        header[8] = 'W';
        header[9] = 'A';
        header[10] = 'V';
        header[11] = 'E';
        header[12] = 'f'; // 'fmt ' chunk
        header[13] = 'm';
        header[14] = 't';
        header[15] = ' ';
        header[16] = 16; // 4 bytes: size of 'fmt ' chunk
        header[17] = 0;
        header[18] = 0;
        header[19] = 0;
        header[20] = 1; // format = 1
        header[21] = 0;
        header[22] = (byte) channel;
        header[23] = 0;
        header[24] = (byte) (sampleRate & 0xff);
        header[25] = (byte) ((sampleRate >> 8) & 0xff);
        header[26] = (byte) ((sampleRate >> 16) & 0xff);
        header[27] = (byte) ((sampleRate >> 24) & 0xff);
        header[28] = (byte) (byteRate & 0xff);
        header[29] = (byte) ((byteRate >> 8) & 0xff);
        header[30] = (byte) ((byteRate >> 16) & 0xff);
        header[31] = (byte) ((byteRate >> 24) & 0xff);
        header[32] = (byte) (channel * encodingBit / 8); // block align
        header[33] = 0;
        header[34] = (byte)encodingBit; // bits per sample
        header[35] = 0;
        header[36] = 'd';
        header[37] = 'a';
        header[38] = 't';
        header[39] = 'a';
        header[40] = (byte) (totalAudioLen & 0xff);
        header[41] = (byte) ((totalAudioLen >> 8) & 0xff);
        header[42] = (byte) ((totalAudioLen >> 16) & 0xff);
        header[43] = (byte) ((totalAudioLen >> 24) & 0xff);
        out.write(header, 0, 44);
    }

    private Handler recorderHandle = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case 3:
                    String filePath = (String) msg.obj;
                    Log.d(TAG, "audio file path = " + filePath);
                    for (int i=0; i<listeners.size(); i++) {
//                        listeners.get(i).onRecordEnd(filePath);
                        WeakReference<AudioRecorderListener> wkL = listeners.get(i);
                        if (wkL.get() != null) {
                            wkL.get().onRecordEnd(filePath, cancelRecord);
                        }
                    }
                    break;
                case 1:
                    Double value = (Double) msg.obj;
                    for (int i=0; i<listeners.size(); i++) {
//                        listeners.get(i).onVolumeChange(value);
                        WeakReference<AudioRecorderListener> wkL = listeners.get(i);
                        if (wkL.get() != null) {
                            wkL.get().onVolumeChange(value);
                        }
                    }
                    break;
                case 2: {
                    for (int i=0; i<listeners.size(); i++) {
//                        listeners.get(i).onAudioError(msg.arg1, (String) msg.obj);
                        WeakReference<AudioRecorderListener> wkL = listeners.get(i);
                        if (wkL.get() != null) {
                            wkL.get().onAudioError(msg.arg1, (String) msg.obj);
                        }
                    }
                }
                break;
                case 0:
                    for (int i=0; i<listeners.size(); i++) {
//                        listeners.get(i).onRecordStart();
                        WeakReference<AudioRecorderListener> wkL = listeners.get(i);
                        if (wkL.get() != null) {
                            wkL.get().onRecordStart();
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    };

    /**
     * 删除文件
     *
     * @param file
     */
    public static void deleteFile(File file) {
        if (file == null) return;
        if (file.exists()) {
            if (file.isFile()) {
                file.delete();
            } else if (file.isDirectory()) {
                File files[] = file.listFiles();
                if (files == null) return;
                for (int i = 0; i < files.length; i++) {
                    deleteFile(files[i]);
                }
            }
            file.delete();
        } else {
            System.out.println("文件不存在！" + "\n");
        }
    }

}
