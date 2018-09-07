import {apiServer} from './config';
// import {VERSION} from '../../react/api/index';

/**上传单个pcm音频文件 */
export function uploadPcmFile(filePath: string) {
    return new Promise((resolve, reject) => {
        let formData = new FormData();
        let file = { uri: 'file://' + filePath, type: 'multipart/form-data', name: 'image.pcm' }
        formData.append("files", file as any);

        fetch(`http://${apiServer}/file?id=vpr_app.vprvoiceFileUpload&v=${1.0}&sessionId=`, {
            method: 'POST',
            headers: {
                'Content-Type': 'multipart/form-data',
            },
            body: formData,
        }).then(response => {
            if (response.ok) {
                return response.json();
            } else {
                reject(response)
            }
        }, (e) => {
            reject(e)
        }).then(response => {
            if (response.hasError) {
                reject(response);
            } else {
                resolve(response.data.fileList[0]);      
            }
        },(e) => {
            alert(e.massage);
        }).catch(err => {
            reject(err);
        })
    });
}