package com.prorecorder.record.utils;


import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

/**
 * Copyright 2017 SpeakIn.Inc
 * Created by west on 2017/11/3.
 */

public class FileUtils {

    private static final int BUFFER_LEN = 8*1024;

    public static byte[]  convertFile(String filePath) throws IOException {
        File file = new File(filePath);
        FileInputStream inputStream = new FileInputStream(file);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[BUFFER_LEN];
        int read ;
        while ((read = inputStream.read(buffer)) != -1 ) {
            if (read == BUFFER_LEN) {
                baos.write(buffer);
            } else {
                byte[] bs2 = new byte[read];
                System.arraycopy(buffer, 0, bs2, 0, read);
                baos.write(bs2);
            }
        }

        return baos.toByteArray();
    }

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
