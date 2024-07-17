import { LightningElement, wire, api } from 'lwc';
import getDossierTasks from '@salesforce/apex/DossierTaskController.getDossierTasks';
import uploadFile from '@salesforce/apex/SharePointCallouts.postAttachmentFile';


function doAThing(file, businessCentralId) {
    console.log('meh');
    return new Promise((resolve, reject) =>  {
        let fn = file.name;
        let ft = file.type;

        console.log('Id: ' + businessCentralId);
        console.log('file name: ' + fn);
        console.log('file type: ' + ft);

        // console.log('loading: ' + this.loading);

        var reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = function () {
            console.log('ONLOAD');
            let res = reader.result;
            let base64 = 'base64,';
            let i = res.indexOf(base64) + base64.length;
            let bodyString = res.substring(i);
            console.log('BASE64 ' + bodyString);

            try {
                console.log('Before apex call');
                uploadFile({businessCentralId: businessCentralId, fileName: fn, fileType: ft, file: bodyString});
                resolve('Succesful upload');
            }
            catch (err) {
                reject(err);
            }
            // .then(() => {
            //     // const myTimeout = setTimeout(this.sayHello, 5000);
            //     // console.log('SUCCESS');
            //     resolve('SUCCESS UPLOAD');
            // })
            // .catch ((error) => {
            //     // this.error = error;
            //     reject('ERROR');
            // })
        };
        reader.onerror = function (error) {
            reject(error);
            // this.loading = false;
            // console.log('Error: ', error);
        };
    });
}

export default class DossierTaskComponent extends LightningElement {
    @api recordId;
    error;
    loading = false;

    @wire(getDossierTasks, {professionalId: '$recordId'})
    dossierTasks;

    toBase64(file) {
        let base64 = 'base64,';
        let i = file.indexOf(base64) + base64.length;
        return file.substring(i);
    }

    // doAThing() {
    //     console.log('HELLO');
        // return new Promise((resolve, reject) =>  {
        //     let fn = file.name;
        //     let ft = file.type;

        //     console.log('Id: ' + businessCentralId);
        //     console.log('file name: ' + fn);
        //     console.log('file type: ' + ft);

        //     console.log('loading: ' + this.loading);

        //     var reader = new FileReader();
        //     reader.readAsDataURL(file);
        //     reader.onload = function () {
        //         console.log('ONLOAD');
        //         let res = reader.result;
        //         let base64 = 'base64,';
        //         let i = res.indexOf(base64) + base64.length;
        //         let bodyString = res.substring(i);
        //         console.log('BASE64 ' + bodyString);

        //         uploadFile({businessCentralId: businessCentralId, fileName: fn, fileType: ft, file: bodyString})
        //         .then(() => {
        //             // const myTimeout = setTimeout(this.sayHello, 5000);
        //             // console.log('SUCCESS');
        //             resolve('SUCCESS');
        //         })
        //         .catch ((error) => {
        //             // this.error = error;
        //             reject('ERROR');
        //         })
        //     };
        //     reader.onerror = function (error) {
        //         reject('ERROR');
        //         // this.loading = false;
        //         // console.log('Error: ', error);
        //     };
        // });
    // }

    handleFileUpload(event) {
        let businessCentralId = event.target.dataset.index;
        let files = event.target.files;

        if (files.length != 0) {
            this.loading = true;
            
            let file = files[0];
            console.log('Joe');

            this.loading = true;
            setTimeout(() => {
                doAThing(file, businessCentralId)
                .then((res) => {
                    console.log('SUCCESS');
                    this.loading = false;
                })
                .catch((error) => {
                    console.log(error);
                    this.loading = false;
                })
            })
        }
        
    
    /*
            let fn = file.name;
            let ft = file.type;

            console.log('Id: ' + businessCentralId);
            console.log('file name: ' + fn);
            console.log('file type: ' + ft);

            console.log('loading: ' + this.loading);

            var reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = function () {
                console.log('ONLOAD');
                let res = reader.result;
                let base64 = 'base64,';
                let i = res.indexOf(base64) + base64.length;
                let bodyString = res.substring(i);
                console.log('BASE64 ' + bodyString);

                uploadFile({businessCentralId: businessCentralId, fileName: fn, fileType: ft, file: bodyString})
                .then(() => {
                    const myTimeout = setTimeout(this.sayHello, 5000);
                    console.log('SUCCESS');
                })
                .catch ((error) => {
                    // this.error = error;
                    console.log('ERROR');
                })
                .finally(() => {
                    this.loading = false;
                })
            };
            reader.onerror = function (error) {
                this.loading = false;
                console.log('Error: ', error);
            };
        }
        */
    }

    renderedCallback() {
        let inputs = this.template.querySelectorAll('lightning-input');

        if (inputs) {
            inputs.forEach((input) => {
                input.addEventListener('change', this.handleFileUpload.bind(this));
            });
        }
    }

    // handleUpload(event) {
    //     console.log('handle upload');
    //     console.log(JSON.stringify(event.currentTarget) + JSON.stringify(event.detail));
    // }
}