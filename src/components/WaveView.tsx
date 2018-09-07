import React, { Component } from 'react';
import PropTypes from 'prop-types';
import {dp} from '../common/ScreenUtil';
import RN, { requireNativeComponent, View, UIManager as uiManager, findNodeHandle, Platform,NativeModules } from 'react-native';


(window as any)['RN'] = RN;
const UIManager = uiManager as any;
//const RCTWaveChartView: any = {};

interface WaveChartViewProperties extends RN.ViewProperties {
    lineColor?: string,
    bgColor?: string,
    isWav?: boolean,
    pointOfMs?: number,
    pcmPath?:string,
    drawUI?:boolean,
    onRecordEnd?: (filePath: string) => void,
    onRecordStart?: () => void,
    onPlayStart?: () => void,
    onPlayEnd?: () => void,
    onplayProgress?:(ms:number,totalMs:number)=>void,
}
let iface = {
    name: 'WaveChartView',
    propTypes: {
        lineColor: PropTypes.string,
        bgColor: PropTypes.string,
        drawUI: PropTypes.bool,
        isWav: PropTypes.bool,
        pcmPath: PropTypes.string,
        pointOfMs: PropTypes.number,
        onMessage: PropTypes.func,
        ...View.propTypes
    }
}
let RCT = requireNativeComponent('RCTWaveChartView', iface) as any;

export default class WaveChartView extends Component<WaveChartViewProperties> {
    constructor(props: WaveChartViewProperties) {
        super(props);
    }
    onMessage(e: { nativeEvent: { filePath: string, eventName: string,ms:number,totalMs:number } }) {
        if (e.nativeEvent.eventName == 'recordEnd') {
            this.props.onRecordEnd && this.props.onRecordEnd(e.nativeEvent.filePath);
        }
        if (e.nativeEvent.eventName == 'recordStart') {
            this.props.onRecordStart && this.props.onRecordStart();
        }
        if (e.nativeEvent.eventName == 'playEnd' || e.nativeEvent.eventName == 'playStop') {
            this.props.onPlayEnd && this.props.onPlayEnd();
        }
        if (e.nativeEvent.eventName == 'playStart') {
            this.props.onPlayStart && this.props.onPlayStart();
        }
        if (e.nativeEvent.eventName == 'playProgress') {
            this.props.onplayProgress && this.props.onplayProgress(e.nativeEvent.ms,e.nativeEvent.totalMs);
        }
        
    }
    render() {
        return <RCT {...this.props} ref="view" onMessage={this.onMessage.bind(this)} />;
    }
    refs: {
        view: typeof RCT
    }
    runCommand(name: string, args: any[] = []) {
        return Platform.select({
            android: () => new Promise((res)=>{
                res(UIManager.dispatchViewManagerCommand(
                    this.getHandle(),UIManager.RCTWaveChartView.Commands[name],args
                ))
            })
            ,
            ios: ()=> RN.NativeModules.WaveChartViewManager[name](this.getHandle(), ...args)
        })();
    }
    getHandle() {
        return findNodeHandle(this.refs.view);
    }
    play(play: boolean) {
        return this.runCommand('play', [play]);
    }
    record(record: boolean) {
        return this.runCommand('record', [record]);
    }
}