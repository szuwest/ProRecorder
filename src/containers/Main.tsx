import React, {Component} from 'react';
import {Platform, StyleSheet, Text, View, Image, Button, 
  TouchableHighlight, NativeModules, NativeEventEmitter} from 'react-native';
import WaveView from "../components/WaveView";
import Event from '../common/Event'

const AudioRecorder = NativeModules.AudioRecorder;
const RecorderNativeEvent = new NativeEventEmitter(AudioRecorder);
const AudioPlayer = NativeModules.AudioPlayer;
const PlayerNativeEvent = new NativeEventEmitter(AudioPlayer);

type Props = {};
export default class Main extends Component<Props,{
  pcmPath: string,
  isRecording: boolean,
  isPlaying: boolean
}> {
  static navigationOptions = (navigation:any,screenProps:any)=>({
    // title: '录音',
    headerTitle: '录音',
    tabBarLabel: '录音',
    tabBarIcon: (params: any) => {
      let img;
      if(params.focused){
        img=require('../icon/tab_icon_help_selected.png')
      }else{
        img=require('../icon/tab_icon_help_normal.png')
      }
      return(
        <Image source={img}/>
      )
    },
    //navigation.navigation.state.params!=undefined?navigation.navigation.state.params.showTabBar:false
    tabBarVisible: true
  });

  constructor(p: any) {
    super(p);
    this.state = { pcmPath: "" , isRecording: false, isPlaying: false};
  }

  componentDidMount() {
    AudioRecorder.checkAndRequestAudio().then();
    RecorderNativeEvent.addListener('onAudioError', (errorInfo:any) => {
      console.log('onAudioError:' + errorInfo);
      this.setState({isRecording:false, pcmPath: ''})

    });
    PlayerNativeEvent.addListener('onAudioPlayDidStop', (res:any) => {
      this.setState({isPlaying:false})
    })
    PlayerNativeEvent.addListener('onAudioPlayProgressChanged', (res:any) => {
      this.onplayProgress(res.progress,res.total);
    })
  }

  componentWillUnmount() {
    RecorderNativeEvent.removeAllListeners();
    PlayerNativeEvent.removeAllListeners();
  }

  startRecord() {
    if (!this.state.isRecording) {
      AudioRecorder.startRecord().then(() => {
        this.setState({isRecording:true})
      }).catch((res:any) => {
        
      });
    }
  }

  stopRecord() {
    if (this.state.isRecording) {
      AudioRecorder.stopRecord().then((res:string) => {
        console.log("filePath=" + res)
        this.setState({isRecording:false, pcmPath:res}, () => {
          Event.publish('AudioFileChange', {'filePath':this.state.pcmPath});
        })
      }).catch((res:any) => {
        console.log("err=" + res);
      });
    }
  }

  startPlay() {
    if (!this.state.isPlaying && this.state.pcmPath.length > 0) {
      AudioPlayer.play(this.state.pcmPath).then(() => {
        this.setState({isPlaying:true})
      }).catch((res:any) => {
        console.log("err=" + res);
      });
    }
  }

  stopPlay() {
    if (this.state.isPlaying) {
      AudioPlayer.stop().then(() => {
        this.setState({isPlaying:false})
      });
    }
  }
 
  onRecordEnd(filePath: string) {
    this.setState({ pcmPath: filePath })
    console.log('onRecordEnd', filePath);
  }
  onRecordStart() {
      console.log('onRecordStart');
  }
  onplayProgress(ms:number,totalMs:number){
      console.log('onplayProgress',ms,totalMs);
  }
  waveView: WaveView
  render() {
    return <View>
        <View style={{ marginLeft: -6, marginRight: -6 }}>
            <WaveView 
                ref={(r) => { this.waveView = r; }}
                drawUI = {true}
                onRecordEnd={this.onRecordEnd.bind(this)}
                onRecordStart={this.onRecordStart.bind(this)}
                onplayProgress={this.onplayProgress.bind(this)}
                pcmPath={this.state.pcmPath}
                isWav={true}
                bgColor="#000"
                lineColor="#49d" pointOfMs={10} style={{ height: 300 }} />
        </View>

        <View style={{ margin: 10 }}>
            <Button title="开始录制" onPress={() => {
                // this.waveView.record(true);
                this.startRecord();
            }} />
        </View>
        <View style={{ margin: 10 }}>
            <Button title="停止录制" onPress={() => {
                // this.waveView.record(false);
              this.stopRecord();
            }} />
        </View>
        <View style={{ margin: 10 }}>
            <Button title="开始播放" onPress={() => {
                // this.waveView.play(true);
                this.startPlay();
            }} />
        </View>
        <View style={{ margin: 10 }}>
            <Button title="停止播放" onPress={() => {
                // this.waveView.play(false);
                this.stopPlay();
            }} />
        </View>
    </View>
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});