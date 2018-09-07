/// <reference types="react" />
/// <reference path="./types.d.ts" />
/// <reference types="react-native" />

import R = React;

declare type ComponentDefProps<NS = {}> = {
    dispatch?: (action: NavigationAction) => void,
    navigation?: NavigationScreenProp<{ params: {} & NS }, NavigationAction>
}

declare class Component<P={}, S={}, NS={}> extends React.Component<P & ComponentDefProps<NS>, S>{ }
declare class PureComponent<P={}, S={}, NS={}> extends React.PureComponent<P & ComponentDefProps<NS>, S>{ }

declare namespace util {
    const Event: {
        subscribe: (name: string, callback: Function, once?: boolean, insertFirst?: boolean) => any;
        unsubscribe: (name: string, callback: Function) => void;
        publish: (name: string, arg: Object, scope?: Object) => void;
    }
    const Format:(str:string)=>string
    const RandomCorpus:(data:any,type_num:number,type_txt:number)=>any
    const Toast:(str:string)=>void
}
declare let __DEBUG__: boolean;
declare let __store__: {
    dispatch: (action: NavigationAction) => void,
    getState:()=>any,
   
}
declare let global_location: {
    latitude:number,
    longitude:number,
}
declare let _teamid: string
declare let _teamname: string

declare namespace global {
    var apiClient: any;
}

declare interface ReduxGlobalStateNav {
    routes: any[]
}

declare interface ReduxGlobalState {
    nav: ReduxGlobalStateNav;
    auth: { isLoggedIn: boolean }
}

declare var dp: (size:number,isFont?:boolean)=>number
