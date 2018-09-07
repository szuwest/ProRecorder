var brandPrimary = '#000';
var brandPrimaryTap = '#000';
let themes = {
    // 支付宝钱包默认主题
    // https://github.com/ant_design/ant_design_mobile/wiki/设计变量表及命名规范
    // 色彩
    // ---
    // 文字色
    /** 默认文字 */
    color_text_base: '#000',
    /** 深色背景下的文字 */
    color_text_base_inverse: '#fff',
    color_text_secondary: '#a4a9b0',
    /** 文本框提示 */
    color_text_placeholder: '#bbb',
    /** 失效 */
    color_text_disabled: '#bbb',//失效	
    /** 辅助描述 */
    color_text_caption: '#888',
    /** 段落 */
    color_text_paragraph: '#333',
    /** 链接色 */
    color_link: brandPrimary,//链接色	
    // 阴影色
    color_shadow: 'rgba(0, 0, 0, .21)',//阴影色

    // 背景色
    /** 组件默认背景 */
    fill_base: '#fff',
    /** 页面背景 */
    fill_body: '#000',
    /** 默认背景按下 */
    fill_tap: '#ddd',
    /** 失效背景 */
    fill_disabled: '#ddd',
    /** 遮罩背景 */
    fill_mask: 'rgba(0, 0, 0, .4)',
    /** 浮层背景反色 */
    fill_overlay_inverse: 'rgba(0, 0, 0, .8)',
    /** 按钮颜色 */
    color_icon_base: '#ccc',
    /** 灰度色 */
    fill_grey: '#f7f7f7',
    /** 组件禁用 */
    opacity_disabled: '0.3',//组件禁用

    // 全局/品牌色
    /** 主色 */
    brand_primary: brandPrimary,
    /** 主色按下 */
    brand_primary_tap: brandPrimaryTap,
    /** 成功 */
    brand_success: '#6abf47',
    /** 警告 */
    brand_warning: '#f4333c',
    /** 失败 */
    brand_error: '#f4333c',
    /** 热门 */
    brand_hot: '#f96268',
    /** 重要 */
    brand_important: '#ff5b05',
    /** 等待 */
    brand_wait: '#108ee9',
    /** 基本边框色 */
    border_color_base: '#ddd', //基本边框色
    // 字体尺寸

    /** 图标辅助文字 */
    font_size_icontext: 10,
    /** 辅助文字 - 小 */
    font_size_caption_sm: 12,
    /** 基本字体 */
    font_size_base: 14,
    /** 副标题 */
    font_size_subhead: 15,
    /** 辅助文字 */
    font_size_caption: 16,
    /** 标题字体 */
    font_size_heading: 17,
    /** 展示型字体 - 小 */
    font_size_display_sm: 18,
    /** 展示型字体 - 中 */
    font_size_display_md: 21,
    /** 展示型字体 - 大 */
    font_size_display_lg: 24,
    /** 展示型字体 - 超大 */
    font_size_display_xl: 30,

    // 字体家族
    // ---
    // tslint:disable-next-line
    font_family_base: '_apple_system,"SF UI Text",Roboto,Noto,"Helvetica Neue",`elvetica,"PingFang SC","Hiragino Sans GB","Microsoft YaHei","微软雅黑",Arial,sans_serif',
    font_family_code: 'Consolas,Menlo,Courier,monospace',
    // 圆角
    // ---
    radius_xs: 2,
    radius_sm: 3,
    radius_md: 5,
    radius_lg: 7,
    // 边框尺寸
    // ---
    border_width_sm: 0.5,
    border_width_md: 1,
    border_width_lg: 2,
    // 间距
    // ---
    // 水平间距
    h_spacing_sm: 5,
    h_spacing_md: 8,
    h_spacing_lg: 15,
    // 垂直间距
    v_spacing_xs: 3,
    v_spacing_sm: 6,
    v_spacing_md: 9,
    v_spacing_lg: 15,
    v_spacing_xl: 21,
    // 高度
    // ---
    line_height_base: 1,
    line_height_paragraph: 1.5,
    // 图标尺寸
    // ---
    icon_size_xxs: 15,
    icon_size_xs: 18,
    icon_size_sm: 21,
    icon_size_md: 22,
    icon_size_lg: 36,
    // 动画缓动
    // ---
    ease_in_out_quint: 'cubic_bezier(0.86, 0, 0.07, 1)',
    // 组件变量
    // ---
    actionsheet_item_height: 50,
    actionsheet_item_font_size: 18,
    // button
    button_height: 47,
    button_font_size: 18,
    button_height_sm: 23,
    button_font_size_sm: 12,
    across_button_height: 50,
    primary_button_fill: brandPrimary,
    primary_button_fill_tap: brandPrimaryTap,
    ghost_button_color: brandPrimary,
    ghost_button_fill_tap: brandPrimaryTap,
    link_button_fill_tap: '#ddd',
    link_button_font_size: 16,
    // modal
    modal_font_size_heading: 15,
    modal_button_font_size: 15,
    modal_button_height: 50,
    // list
    list_title_height: 30,
    list_item_height_sm: 35,
    list_item_height: 44,
    // input
    input_label_width: 17,
    input_font_size: 17,
    input_color_icon: '#ccc',
    input_color_icon_tap: brandPrimary,
    // tabs
    tabs_color: brandPrimary,
    tabs_height: 42,
    tabs_font_size_heading: 15,
    // segmented_control
    segmented_control_color: brandPrimary,
    segmented_control_height: 27,
    segmented_control_fill_tap: brandPrimary + '10',
    // tab_bar
    tab_bar_fill: '#ebeeef',
    tab_bar_height: 50,
    // toast
    toast_fill: 'rgba(255, 255, 255, .1)',
    // search_bar
    search_bar_fill: '#efeff4',
    search_bar_height: 44,
    search_bar_input_height: 28,
    searchbar_font_size: 15,
    search_color_icon: '#bbbbbb',
    // notice_bar
    notice_bar_fill: '#fffada',
    notice_bar_height: 36,
    // switch
    switch_fill: '#4dd865',
    // tag
    tag_height: 25,
    tag_small_height: 15,
    // table
    table_title_height: 30,
    // picker
    option_height: 42,
    toast_zindex: 1999,
    action_sheet_zindex: 1000,
    popup_zindex: 999,
    modal_zindex: 999
}

let nowThemes: { [key: string]: number | string } & typeof themes = themes;

let antdStyle = require("antd-mobile/lib/style/themes/default");
for (let k of Object.keys(nowThemes)) {
    antdStyle[k] = nowThemes[k as any];
}

export default nowThemes;