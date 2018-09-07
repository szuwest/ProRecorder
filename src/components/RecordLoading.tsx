import RN, { View, Image, Animated, Easing } from 'react-native';

export default class RecordLoading extends Component<RN.ViewProperties, { rotate: Animated.Value }> {
    static defaultProps = { style: {} };
    constructor(p: any) {
        super(p);
        this.state = {
            rotate: new Animated.Value(0)
        }
    }
    componentWillMount() {
        this.animated();
    }
    componentWillUnmount() {
        this.animated = () => { };
    }
    animated() {
        this.state.rotate.setValue(0)
        Animated.timing(this.state.rotate, {
            toValue: 1,
            duration: 400,
            easing: Easing.linear,
            useNativeDriver: true
        }).start(() => this.animated())
    }
    render() {
        return <View {...this.props} style={Object.assign({ marginBottom: dp(15) } as RN.ViewStyle, this.props.style)}>
            <Animated.Image style={{
                transform: [{
                    rotate: this.state.rotate.interpolate({
                        inputRange: [0, 1],
                        outputRange: ['0deg', '360deg']
                    })
                }]
            }} source={require("../../icon/icon_refesh.png")} />
            <View style={{position:"absolute",width:"100%",height:"100%",left:0,top:0,justifyContent: 'center'}}>
                <Image style={{ alignSelf: "center" }} source={require("../../icon/wav.png")} />
            </View>
        </View>
    }
} 