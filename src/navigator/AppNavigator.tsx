import React from 'react';
import RN, { Image, View, StyleSheet, BackHandler, } from 'react-native';
import { createBottomTabNavigator,createStackNavigator } from 'react-navigation';
import HomeScreen from '../containers/Main';
import FilesScreen from '../containers/FileList';

const styles = StyleSheet.create({
  icon: {
    height: 22,
    width: 22
  }
});

const MainNavi = createStackNavigator({
  Home: HomeScreen
})

const FilesNavi = createStackNavigator({
  Files: FilesScreen
})

export const MainNavigator = createBottomTabNavigator({
  Main: { 
    screen: MainNavi,
    navigationOptions: {
      tabBarLabel: '录音',
      tabBarIcon: (params:any) => {
        let img;
        if(params.focused){
          img=require('../icon/tab_icon_help_selected.png')
        }else{
          img=require('../icon/tab_icon_help_normal.png')
        }
        return(
          <Image
          source={img}/>
        )
      }
    }
   },
  VoiceManage: { 
    screen: FilesNavi,
    navigationOptions: {
      tabBarLabel: '文件',
      tabBarIcon: (params: any) => {
        let img;
        if(params.focused){
          img=require('../icon/tab_icon_mission_selected.png')
        }else{
          img=require('../icon/tab_icon_mission_normal.png')
        }
        return(
          <Image
          source={img}/>
        )
      },
    }
  }
}, {
    tabBarPosition: 'bottom',
    swipeEnabled: false,
    animationEnabled: false,
    lazy: true,
    tabBarOptions: {
      activeTintColor: "#215eec",
      inactiveTintColor: "#4c4c4c",
      showIcon: true,
      showLabel: true,
      style: { backgroundColor: "#fff", 
      borderColor: '#ddd', 
      borderTopWidth: 1,
      height: 50,
      padding:0 },
      // labelStyle: { fontSize: 11},
      indicatorStyle: {backgroundColor:'transparent', height: 0},
    }
  })


BackHandler.addEventListener("hardwareBackPress", () => {
  if (this.lastBackPressed && this.lastBackPressed + 2000 >= Date.now()) {
    return false
  }
  this.lastBackPressed = Date.now();
  RN.ToastAndroid.show("再按一次退出应用", RN.ToastAndroid.SHORT);
  return true
})

export default MainNavigator;