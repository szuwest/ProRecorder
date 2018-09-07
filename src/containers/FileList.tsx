import React, {Component} from 'react';
import {StyleSheet, TouchableOpacity, Text, 
  View, Image, FlatList, NativeModules} from 'react-native';
import Event from '../common/Event'


const AudioFileManager = NativeModules.AudioFileManager;
const AudioPlayer = NativeModules.AudioPlayer;

type Props = {};
export default class FileList extends Component<Props, {
  audioData: Array<string>
}> {

  static navigationOptions = (navigation:any,screenProps:any)=>({
    title: '文件列表',
    tabBarLabel: '文件',
    tabBarIcon: (params: any) => {
      let img;
      if(params.focused){
        img=require('../icon/tab_icon_mission_selected.png')
      }else{
        img=require('../icon/tab_icon_mission_normal.png')
      }
      return(
        <Image source={img}/>
      )
    },
    //navigation.navigation.state.params!=undefined?navigation.navigation.state.params.showTabBar:false
    tabBarVisible: true,
    headerTintColor: '#333',
    headerTitleStyle: {
      fontWeight: 'bold',
    },
  });

  constructor(p: any) {
    super(p);
    // /storage/emulated/0/SpeakInSDK/record/1511501453.pcm 1511440583
    this.state = { audioData: [] };
  }

  componentWillMount() {
    this.reloadData('');
    Event.subscribe('AudioFileChange',this.reloadData.bind(this));
  }

  componentWillUnmount() {
    Event.unsubscribe('AudioFileChange', this.reloadData.bind(this));
  }

  reloadData(res:any) {
    AudioFileManager.listFileInDoc('ProRecorder').then((data:any) => {
      console.log("audio length =" + data.length)
      this.setState({
        audioData: data
      })
    });
  }

  //点击每一行的对象
  Cellheader(data:string){
    // alert(data);
    AudioPlayer.play(data);
  }
    //使用json中的title动态绑定key
    keyExtractor(item: Object, index: number) {
      return item + "" + index;
    }

  //列表的每一行
  renderItemView({item}){
    console.log("item=" + item)
    let ind = item.lastIndexOf('/');
    let fileName = item.substr(ind+1);
    return(
      <TouchableOpacity style={{flex:1,
                                height:60,
                                backgroundColor:'#eee',
                        }}
                        onPress={()=>{this.Cellheader(item)}}
                       >
        <View style={{backgroundColor:'#fff',
                      height:59,justifyContent: 'center',
                      alignItems: 'center'}}>
           <Text>{fileName}</Text>
        </View>
      </TouchableOpacity>
    );
  }

  render() {
    return (
      <View style={styles.container}>
        <FlatList style={{backgroundColor:'#fff',flex:1,marginTop:0}}
                  data = {this.state.audioData}
                  renderItem={this.renderItemView.bind(this)}
                  keyExtractor={this.keyExtractor.bind(this)}
                  >
        </FlatList>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    // justifyContent: 'center',
    // alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },

});