type NavigationDispatch<A> = (action: A) => boolean;

interface NavigationParams {
    [key: string]: any
}
declare interface NavigationAction {
  type:string,
  [key: string]: any
}

declare type NavigationScreenProp<S, A> = {
  state: S,
  dispatch: NavigationDispatch<A>,
  goBack: (routeKey?: (string | null)) => boolean,
  navigate: (
    routeName: string,
    params?: NavigationParams,
    action?: NavigationAction
  ) => boolean,
  setParams: (newParams: NavigationParams) => boolean,
};