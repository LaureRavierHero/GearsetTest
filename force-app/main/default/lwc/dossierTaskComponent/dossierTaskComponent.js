import { LightningElement, wire, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getDossierTasks from '@salesforce/apex/DossierTaskController.getDossierTasks';
import uploadFile from '@salesforce/apex/SharePointCallouts.postAttachmentFile';

import successTitle from '@salesforce/label/c.lbl_success';
import successMessage from '@salesforce/label/c.lbl_file_upload_success';
import cardTitle from '@salesforce/label/c.lbl_file_upload_title';
import dossierItem from '@salesforce/label/c.lbl_dossier_item';
import upload from '@salesforce/label/c.lbl_upload';
import deadline from '@salesforce/label/c.lbl_deadline';
import status from '@salesforce/label/c.lbl_status';

export default class DossierTaskComponent extends LightningElement {
    @api recordId;
    error;
    loading = false;
    dossierTasks;
    error;

    labels = {
        successTitle: successTitle,
        successMessage: successMessage,
        cardTitle: cardTitle,
        dossierItem: dossierItem,
        upload: upload,
        deadline: deadline,
        status: status
    }

    @wire(getDossierTasks)
    wiredDossierTasks({error, data}) {
        if (data) {
            this.dossierTasks = data;
        }
        if (error) {
            this.error = JSON.stringify(error);
        }
    }

    showToast(variant, title, message) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}

    toBase64(file) {
        let base64 = 'base64,';
        let i = file.indexOf(base64) + base64.length;
        return file.substring(i);
    }

    async handleApiCall(businessCentralId, fn, ft, fileString) {
        return new Promise(async (resolve, reject) =>{
            console.log('2');
            try {
                await uploadFile({businessCentralId: businessCentralId, fileName: fn, fileType: ft, file: fileString});
                resolve('success');

            }
            catch (error) {
                reject(error);
            }
        });
    }

    async handleReadFile(file) {
        return new Promise((resolve, reject) =>  {
    
            var reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = function () {
                let res = reader.result;
                let base64 = 'base64,';
                let i = res.indexOf(base64) + base64.length;
                let bodyString = res.substring(i);
    
                resolve(bodyString);
            };
            reader.onerror = function (error) {
                reject(error);
            };
        });
    }

    handleFileUpload(event) {
        let businessCentralId = event.target.dataset.index;
        let files = event.target.files;

        if (files.length != 0) {
            this.loading = true;
            let file = files[0];
            let fn = file.name;
            let ft = file.type;

            this.loading = true;
            setTimeout(() => {
                this.handleReadFile(file)
                .then((res) => {
                    console.log('1' + res);
                    return this.handleApiCall(businessCentralId, fn, ft, res);
                })
                .then(() => {
                    this.showToast('success', labels.successTitle, labels.successMessage);
                    this.loading = false;
                })
                .catch((error) => {
                    this.showToast('error', 'Error', error.body.message);
                    this.loading = false;
                })
            })
        }
    }
}