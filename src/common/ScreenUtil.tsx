/**
 * 屏幕工具类
 * ui设计基准,iphone 6
 * width:375
 * height:667
 */

/*
 设备的像素密度，例如：
 PixelRatio.get() === 1          mdpi Android 设备 (160 dpi)
 PixelRatio.get() === 1.5        hdpi Android 设备 (240 dpi)
 PixelRatio.get() === 2          iPhone 4, 4S,iPhone 5, 5c, 5s,iPhone 6,xhdpi Android 设备 (320 dpi)
 PixelRatio.get() === 3          iPhone 6 plus , xxhdpi Android 设备 (480 dpi)
 PixelRatio.get() === 3.5        Nexus 6       */

import { Dimensions, PixelRatio, Platform} from 'react-native';


export const deviceWidth = Dimensions.get('window').width;      //设备的宽度
export const deviceHeight = Dimensions.get('window').height;    //设备的高度
let fontScale = PixelRatio.getFontScale();                      //返回字体大小缩放比例

let pixelRatio = PixelRatio.get();      //当前设备的像素密度
const defaultPixel = 2;                 //iphone6的像素密度
//px转换成dp
const w2 = 375 / defaultPixel;
const h2 = 667 / defaultPixel;
const scale = Math.min(deviceHeight / h2, deviceWidth / w2);   //获取缩放比例

/**
 * 设置text为sp
 * @param size sp
 * return number dp
 */
export function setSpText(size: number) {
    // size = Math.round((size * scale + 0.5) * pixelRatio / fontScale);
    // return size / defaultPixel;
    return size;
}

export function scaleSize(size: number) {

    size = Math.round(size * scale + 0.5);
    return size / defaultPixel;
}

export function dp(size: number, isFont?:boolean) {
    isFont = isFont?isFont:false;
    return isFont
        ? setSpText(Platform.OS == 'android'?size:(size-1))
        : scaleSize(size);
}