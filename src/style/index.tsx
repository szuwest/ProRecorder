import { ViewStyle } from 'react-native';
import _themes from "./themes";

export const themes = _themes;

export default {
    Container: {
        flex: 1,
        backgroundColor: themes.fill_body,
        padding: dp(10)
    } as ViewStyle
}