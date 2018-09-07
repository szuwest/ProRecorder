import RN, { View, Text, NativeModules, processColor, Animated, Image, Platform } from 'react-native';
import RecordLoading from "./RecordLoading";
import {dp} from '../common/ScreenUtil';


let AudioRecorder = NativeModules.AudioRecorder;
let android = Platform.OS == 'android';
const MaxMsMap = {
    number: 8000,
    longString: 180000,
    shortString: 10000
}
let isComponentUnmount = false;

interface Props {
    updateDateTimes?: (ms: number) => void,
    nowStep?: (number: number) => void,
    totalStep?: number,
    getUploadUrl: () => { url: string, chkType: string },
    getMsg: (step: number) => { tips: string, msg: string },
    recordComplete: (filePath: string[]) => Promise<string>
}
interface State {
    step?: number,
    errorTips?: string,
    uploading?: boolean,
    times?: string,
    buttonScale: Animated.Value,
    tipsOpacity: Animated.Value,
    mainTextScale: Animated.Value,
    stepTransform: Animated.Value,
    msgOpacity: Animated.Value,
    outerButtonScale: Animated.Value,
    buttonOpacity: Animated.Value
}

const baseText = { textAlign: "center" } as RN.TextStyle;
const assign = (o: RN.TextStyle, o1 = baseText) => Object.assign({}, o1, o);
const buttonSize = 54;
const button = {
    position: "absolute",
    bottom: dp(20),
    alignSelf: "center",
    borderRadius: buttonSize,
    width: buttonSize * 2,
    height: buttonSize * 2,
    opacity: 0.2,
    borderColor: "rgb(0,172,248)",
    borderStyle: "solid",
    borderWidth: 2
}

const innerButton = {
    backgroundColor: "#00B1FF",
    elevation: 4,
    shadowColor: '#00ACF8',
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    opacity: 1
}

const styles = {
    tips: assign({
        color: "#ddd",
        fontSize: dp(14, !0),
        marginTop: dp(28),
        lineHeight: dp(30)
    }),
    msg: assign({
        color: "#ddd",
        fontSize: dp(40, !0),
        textAlignVertical: "center"
    }),
    errorTips: {
        backgroundColor: "rgba(248,248,248,0.82)",
        height: dp(40),
        position: "absolute",
        bottom: dp(190),
        alignSelf: "center",
        justifyContent: 'center',
        borderRadius: dp(4)
    } as RN.ViewStyle,
    errorText: assign({
        fontSize: dp(14, !0),
        color: "#000",
        marginLeft: dp(15),
        marginRight: dp(15)
    }),
    button: button as RN.ViewStyle,
    internalButton: Object.assign({}, button, innerButton) as RN.ViewStyle,
    stepArea: {
        position: "absolute",
        top: dp(30),
        alignSelf: "center",
        width: dp(80),
        height: dp(18),
        paddingLeft: 10,
        paddingRight: 10,
        overflow: "visible"
    } as RN.ViewStyle,
    stepView: {
        width: '100%',
        height: dp(30)
    } as RN.ViewStyle,
}
if (!android) {
    styles.stepView.width = dp(88);
    styles.stepView.marginLeft = dp(115);
}
const errorMap: { [k: string]: string } = {
    "too-noisy": "周围太吵了，请更换安静的环境",
    "too-short": "您念得太快了，请放慢语速",
    "too-long": "录音过长，请重新录制",
    "too-loud": "声音过大，请离麦克风20cm重试一次",
    "too-quiet": "您念得太小声了，请重试"
}

const stepInitX = 6;
// this.props.modelType == "longString" ? "left" :
export default class Record extends Component<Props, State> {
    constructor(p: any) {
        super(p);
        this.state = {
            step: 0,
            errorTips: "",
            uploading: false,
            times: "",
            outerButtonScale: new Animated.Value(0.8),
            buttonScale: new Animated.Value(.5),
            tipsOpacity: new Animated.Value(0.8),
            mainTextScale: new Animated.Value(1),
            stepTransform: new Animated.Value(stepInitX),
            msgOpacity: new Animated.Value(1),
            buttonOpacity: new Animated.Value(0.2),
        };
        this.serverFileId = [];
        let sizeMap = {
            number: dp(40, !0),
            longString: dp(16, !0),
            shortString: dp(32, !0),
            gender: dp(40, !0)
        };
        let lineHeightMap = {
            number: dp(40),
            longString: dp(24),
            shortString: dp(40),
            gender: dp(40)
        };

        this.msgStyle = Object.assign({}, styles.msg, {
            fontSize: 16,
            textAlign: "center",
            lineHeight: 3
        });
        this.oneTimeMaxMs = MaxMsMap['longString']
    }
    oneTimeMaxMs = 0
    msgStyle: RN.TextStyle
    static defaultProps = {
        totalStep: 3
    } as Props
    static totalMs(dataLength: number, sampleRate: number = 16000) {
        return Math.floor(dataLength / 2 / sampleRate * 1000)
    }
    static getTimes(dataLength: number) {
        let totalMs = this.totalMs(dataLength);
        let fmt = (s: number) => s > 9 ? s : ('0' + s)
        let s = Math.floor(totalMs / 1000)
        var minutes = Math.floor(s / 60) % 60;
        var seconds = s % 60;
        return fmt(minutes) + ":" + fmt(seconds) + "." + fmt(Math.floor(totalMs / 10) % 100);
    }
    private timeId: number;
    serverFileId: string[];
    totalMs(dataLength: number) {
        return Record.totalMs(dataLength);
    }
    componentDidMount() {
        this.props.nowStep && this.props.nowStep(1);
    }

    getDataLength() {
        clearInterval(this.timeId);
        this.timeId = setInterval(() => {
            AudioRecorder.getDataLength().then((dataLength: number) => {
                let totalMs = this.totalMs(dataLength);
                this.props.updateDateTimes && this.props.updateDateTimes(totalMs);
                __DEBUG__ && this.setState({ times: Record.getTimes(dataLength) });
                // 强行停止逻辑
                if (totalMs > this.oneTimeMaxMs) {
                    clearInterval(this.timeId);
                    AudioRecorder.stopAudioRecording().then(() => {
                        return this.setState({ errorTips: "录音过长，请重新录制" });
                    });
                }
            });
        }, 100);
    }
    isStop = true
    start() {
        this.setState({ errorTips: "", times: "" });
        let mainTextScale = 1.1
        Animated.parallel([
            Animated.timing(this.state.buttonScale, { toValue: .7, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.outerButtonScale, { toValue: .8, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.buttonOpacity, { toValue: 1, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.tipsOpacity, { toValue: 0, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.mainTextScale, { toValue: mainTextScale, useNativeDriver: true, duration: 300 }),
        ]).start();
        if (this.isStop) {
            AudioRecorder.startAudioRecording()
                .then(() => {
                    this.isStop = false;
                    this.getDataLength();
                })
                .catch((e: string) => {
                    this.isStop = true;
                    alert("没有录音权限")
                })
        }
    }
    stop(isCancel: boolean) {
        let RecordLoadingMinRunTime = 1200;
        let ButtonStopAnimateTime = 300;
        Animated.parallel([
            Animated.timing(this.state.buttonScale, { toValue: .5, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.outerButtonScale, { toValue: 0.8, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.buttonOpacity, { toValue: 0.2, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.tipsOpacity, { toValue: 0.8, useNativeDriver: true, duration: 300 }),
            Animated.timing(this.state.mainTextScale, { toValue: 1, useNativeDriver: true, duration: 300 }),
        ]).start(() => {
            // AudioRecorder.onError().then((r: string) => {
            //     this.isStop = true;
            //     r && alert(r);
            // })
            AudioRecorder.stopAudioRecording().then((filePath: string) => {
                clearInterval(this.timeId);
                AudioRecorder.getDataLength()
                    .then((dataLength: number) => {
                        this.isStop = true;
                        if (Record.totalMs(dataLength) < 500) { return this.setState({ errorTips: "您念得太快了，请放慢语速" }); }
                        let { step } = this.state;
                        setTimeout(() => {
                            this.setState({ uploading: true }, () => {
                               
                            })
                        }, ButtonStopAnimateTime)
                    })
                    .catch((r: string) => {
                        this.isStop = true;
                    })
            });
        });
    }

    next() {
        let nextStep = this.state.step + 1;
        if (nextStep < this.props.totalStep) {
            Animated.parallel([
                // Animated.timing(this.state.stepTransform, {
                //     toValue: stepInitX + 21 * nextStep,
                //     duration: 400,
                //     useNativeDriver: true
                // }),
                Animated.timing(this.state.msgOpacity, {
                    toValue: 0,
                    duration: 400,
                    useNativeDriver: true
                })
            ]).start(() => {
                this.props.nowStep(nextStep + 1);
                this.setState({ step: nextStep, times: "" }, () => {
                    Animated.timing(this.state.msgOpacity, {
                        toValue: 1,
                        duration: 400,
                        useNativeDriver: true
                    }).start();
                })
            })
        } else {
            this.setState({ uploading: true }, () => {
                this.props.recordComplete(this.serverFileId).then(r => {
                    !isComponentUnmount && this.setState({ uploading: false });
                    this.props.nowStep && this.props.nowStep(nextStep);
                })
            });
        }
    }
    getText(msg: string) {
        return msg;
    }
    render() {
        let { state } = this;
        let msg = this.props.getMsg(state.step);
        return <View style={{ flex: 1, padding: dp(20) }} >
            <View style={{ height: dp(30) }} />
            <Animated.Text style={[styles.tips, { opacity: state.tipsOpacity }]}>{msg.tips}</Animated.Text>
            <Animated.View style={{
                marginTop: dp(20),
                transform: [{ scale: state.mainTextScale }],
                opacity: state.msgOpacity,
            }}>
                <Text style={this.msgStyle}>{this.getText(msg.msg)}</Text>
            </Animated.View>
            {state.errorTips ? <View style={styles.errorTips}><Text style={styles.errorText}>{state.errorTips}</Text></View> : null}
            <Animated.View style={[{
                position: 'absolute',
                bottom: dp(140),
                alignSelf: 'center',
            }, {
                opacity: state.tipsOpacity,
            }]}>
                <Text style={{
                    textAlign: 'center',
                    color: '#fff',
                    fontSize: dp(14),
                }}>请按住录音按钮说话</Text>
            </Animated.View>

            {/* {__DEBUG__ ? <Text style={{ color: "#fff" }}>{state.times}</Text> : null}  */}
            {
                state.uploading
                    ? <RecordLoading style={{ alignSelf: "center", position: "absolute", bottom: "5%" }} />
                    : <Animated.View style={[styles.button, { opacity: this.state.buttonOpacity, transform: [{ scale: state.outerButtonScale }] }]} />
            }
            {
                state.uploading ? null :
                    <Animated.View onTouchStart={this.start.bind(this)}
                        onTouchEnd={this.stop.bind(this, false)}
                        onTouchCancel={this.stop.bind(this, true)} style={[styles.internalButton, { transform: [{ scale: state.buttonScale }] }]} />
            }
        </View>
    }
}