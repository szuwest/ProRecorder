import { 
    merge,
    isString
} from "lodash";
import {AsyncStorage} from 'react-native';
const noop = () => {};
export default {
    get(key:string) {
        return new Promise((resolve, reject) => {
            AsyncStorage.getItem(key, (err, result) => {
                if (err) {
                    reject(err);
                }
                try {
                    resolve(JSON.parse(result));
                } catch(e) {
                    resolve(result);
                }
            });
        });
    },
    set(key:string, data:any) {
        return new Promise((resolve, reject) => {
            const value = isString(data) ? data : JSON.stringify(data);
            AsyncStorage.setItem(key, value, (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(true);
                }
            });
        });
    },
    remove(key:string) {
        return new Promise((resolve, reject) => {
            AsyncStorage.removeItem(key, err => {
                if (err) {
                    reject(err);
                } else {
                    resolve(true);
                }
            });
        });
    },
    merge(key:string, data:any) {
        return new Promise((resolve, reject) => {
            AsyncStorage.getItem(key, (err, result) => {
                if (err) {
                    reject(err);
                } else {
                    AsyncStorage.setItem(key, merge(result, data), err => {
                        if (err) {
                            reject(err);
                        } else {
                            resolve(true);
                        }
                    });
                }
            });
        });
    }
}
