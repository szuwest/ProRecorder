import { merge } from "lodash";
import { debug, apiTimeout, apiServer } from "./config";

export default {
    call: function apiClient(id: string, version: string, request: any, timeout?: number) {
        let fullUrl = `http://${apiServer}/call?id=${id}&v=${version}`;
        let _timeout = timeout || apiTimeout || 15000;
        let opt: any = {
            headers: merge({}, {
                'Access-Control-Allow-Origin': '*',
                'Accept': 'application/json',
                "Content-Type": "application/json"
            }),
            method: "post",
            body: JSON.stringify(request)
        };
        if (opt.method == "get") {
            delete opt.body
        }
        debug && console.log('%c fetch ', "color:#4CAF50 ; font-weight: bold", id, request)
        return new Promise(function (resolve, reject) {
            var tid: any = 0;
            tid = setTimeout(function () {
                debug && console.log('%c fetch timeout ', "color:#F20404 ; font-weight: bold", id, request)
                reject({ apiError: true, errorType: "timeout", errorDesc: `网络超时` })
            }, _timeout);
            fetch(fullUrl, opt)
                .then(response => {
                    return response.json().then(json => ({ json, response }));
                })
                .then(({ json, response }) => {
                    clearTimeout(tid);
                    if (response.ok) {
                        if (json.hasError) {
                            reject({ apiError: true, errorType: "apiError", errorDesc: json.errorDesc });
                        } else {
                            resolve(json.data)
                        }
                    } else {
                        debug && console.log('%c fetch status error ', "color:#F20404 ; font-weight: bold", id, request, response.status);
                        reject({ apiError: true, errorType: "httpError", errorDesc: `服务器未知错误` });
                    }
                })
                .catch(function (e) {
                    debug && console.log('%c fetch error ', "color:#F20404 ; font-weight: bold", id, request, e);
                    reject({ apiError: true, errorType: "otherError", errorDesc: `服务器繁忙` });
                });
        });

    }
}
