'use strict';
import React, { Component, ReactElement } from 'react';
import themes from "../style/themes";
import {dp} from '../common/ScreenUtil';
import {
    View,
    Text,
    Image,
    Modal,
    Alert,
    TextInput,
    ScrollView,
    StyleSheet,
    Dimensions,
    TouchableOpacity,
    StatusBar,
    TouchableHighlight,
    Platform
} from 'react-native';
var { width, height, scale } = Dimensions.get('window');

var contentModal;
// 类
export default class ModalView extends Component<{
    style?: any,
    visible?:boolean,
    msg?:string | string[],
    content?:() => JSX.Element,
    onOk?:() => boolean | void,
    onCancel?:() => void,
    btns?:string[]
}, {
    visible:boolean
}> {

    constructor(props?: any) {
        super(props);
        this.state = {
            visible: this.props.visible
        };
    }

    static defaultProps = {
        visible: false,
        btns: ['确定']
    }

    componentWillReceiveProps(nextProps: any) {
        this.setState({
            visible: this.props.visible
        });
    }

    setModalVisible(bool: boolean) {
        this.setState({
            visible: bool
        }, () => {
            if (bool == true) {
                if (Platform.OS != "ios") StatusBar.setBackgroundColor('rgba(23, 31, 60, 0.9)', true)
            } else {
                if (Platform.OS != "ios") StatusBar.setBackgroundColor(themes.fill_body, false)
            }
        })
    }

    onOk() {
        if (this.props.onOk) {
            const shouldClose = this.props.onOk();
            if (shouldClose !== false) {
                this.setModalVisible(false);
            }
        }
    }

    onCancel() {
        this.setModalVisible(false);
        this.props.onCancel && this.props.onCancel();
    }

    renderBtns() {
        const {btns} = this.props;
        if (btns.length == 1) {
            return (
                <View style={styles.buttonView}>
                    <View style={styles.horizontalLine} />
                    <TouchableOpacity
                        activeOpacity={0.7}
                        style={styles.buttonStyle}
                        onPress={() => { this.onOk() }}>
                        <Text style={styles.buttonText}>
                            {btns[0]}
                        </Text>
                    </TouchableOpacity>
                </View>
            );
        } else {
            return (
                <View style={styles.buttonView}>
                    <View style={styles.horizontalLine} />
                    <View style={{
                        flexDirection:'row',
                        position:'relative'
                    }}>
                        <TouchableOpacity
                            activeOpacity={0.7}
                            style={[styles.buttonStyle, styles.confirmbtn]}
                            onPress={() => { this.onCancel() }}>
                            <Text style={styles.buttonText}>
                                {btns[0]}
                            </Text>
                        </TouchableOpacity>
                        <View style={styles.verticalLine} />
                        <TouchableOpacity
                            activeOpacity={0.7}
                            style={[styles.buttonStyle, styles.confirmbtn]}
                            onPress={() => { this.onOk() }}>
                            <Text style={styles.buttonText}>
                                {btns[1]}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            );
        }
        
    }

    renderMsgs() {
        let msg = this.props.msg;
        if (!msg) {
            return null
        }
        if (typeof msg == 'string') {
            return <Text style={styles.msg}>{msg}</Text>
        } else {
            return msg.map((text:string,index:number) => {
                return <View key={'msg'+index}><Text style={styles.msg}>{text}</Text></View>
            });
        }
    }

    render() {
        let handleFunc: any;
        var modalBackgroundStyle = {
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
        };
        return (
            <Modal
                animationType='none'
                transparent={true}
                visible={this.state.visible}
                onShow={() => { }}
                onRequestClose={() => { }} 
            >
                <View style={[styles.modalStyle, modalBackgroundStyle, this.props.style || {}]}>
                    <View style={[styles.subView]}>
                        <View style={styles.content}>
                            {this.renderMsgs()}
                            {this.props.content && this.props.content()}
                        </View>
                        {this.renderBtns()}
                    </View>
                </View>
            </Modal>
        );
    }
}
var styles = StyleSheet.create({
    // modal的样式
    modalStyle: {
        // backgroundColor:'#ccc',
        alignItems: 'center',
        justifyContent: 'center',
        flex: 1
    },
    // modal上子View的样式
    subView: {
        marginLeft: dp(38),
        marginRight: dp(38),
        backgroundColor: '#fff',
        alignSelf: "stretch",
        justifyContent: 'center',
        borderRadius: dp(8),
        elevation: dp(2)
    },
    // 标题
    // 水平的分割线
    horizontalLine: {
        height: 0.5,
        backgroundColor: '#999',
        opacity:0.2,
        marginTop:dp(2)
    },
    // 按钮
    buttonView: {
    },

    buttonStyle: {
        paddingHorizontal:dp(50),
        paddingVertical:dp(15),
    },

    confirmbtn: {
        width: '50%',
        flexDirection: 'column'
    },

    verticalLine: {
        width: 0.5,
        height: '100%',
        backgroundColor: '#999',
        opacity:0.2
    },

    buttonText: {
        fontSize: dp(15, !0),
        color: '#00ACF8',
        textAlign: 'center',
    },
    
    msg: {
        color:'#000',
        fontSize:dp(15),
        textAlign:'center'
    },
    content: {
        padding:dp(20)
    }
});

export let alert = (msg?:string,title?:string,callback?:() => void) => {
    title = title || '提示';
    msg = msg || '';
    Alert.alert(
        title,
        msg,
        [
            {text: '确定', onPress: () => {
                callback && callback();
            }}
        ]
    )
}