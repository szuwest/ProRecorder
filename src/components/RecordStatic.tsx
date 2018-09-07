import { NativeModules } from 'react-native';
let AudioRecorder = NativeModules.AudioRecorder;

export default {
    record: function (recordTime: number, cb: (filePath: string) => void) {
        AudioRecorder.startAudioRecording().then(() => {
            this._getDataLength(cb, recordTime * 2 * 16000 / 1000);
        });
    },
    _getDataLength(cb: (filePath: string) => void, totalLen: number) {
        clearInterval(this.timeId);
        this.timeId = setInterval(() => {
            AudioRecorder.getDataLength().then((dataLength: number) => {
                if (dataLength >= totalLen) {
                    clearInterval(this.timeId);
                    AudioRecorder.stopAudioRecording().then(cb)
                }
            });
        }, 20);
    }
}