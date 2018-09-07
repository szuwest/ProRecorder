
import * as React from 'react';
import Event from './Event';
import apiClient from './apiClient';
import "../style/themes";
import {dp} from './ScreenUtil';
import {debug} from './config';

let w: any = window;

w.reduxConnect = (cls: React.ComponentClass, mapStateToProps: () => any, mapDispatchToProps: Function) => connect(mapStateToProps, mapDispatchToProps, null, { withRef: true })(cls)
w.R = React;
w.React = React;
w.PureComponent = React.PureComponent;

// const oldSetState = React.Component.prototype.setState;
// React.Component.prototype.setState = function () {
//     if (this.constructor.navigationOptions) {
//         if (this._reactInternalInstance) {
//             let routes = __store__.getState().nav.routes;
//             if (routes[routes.length - 1].routeName == this.constructor.name) {
//                 oldSetState.apply(this, arguments);
//             }
//         }
//     } else {
//         oldSetState.apply(this, arguments);
//     }
// }
w.Component = React.Component;
w.util = {
    Event
}
w.__DEBUG__ = false;

w.apiClient = apiClient;

w.dp = dp
w.IMEI = "";
w.log = function () {
debug && console.log.apply(window,arguments);
}
 