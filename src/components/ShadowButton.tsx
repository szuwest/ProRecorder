import PropTypes from 'prop-types';
import RN,{ requireNativeComponent, View } from 'react-native';

var iface = {
  name: 'ShadowButton',
  propTypes: {
    shadowColor: PropTypes.number,
    shadowWidth: PropTypes.number,
    ...View.propTypes // 包含默认的View的属性
  },
};

let RCTShadowButton:any = requireNativeComponent('RCTShadowButton', iface)

export default RCTShadowButton as React.ClassicComponentClass< RN.ViewProperties & {
  shadowColor : number,
  shadowWidth : number
} >;