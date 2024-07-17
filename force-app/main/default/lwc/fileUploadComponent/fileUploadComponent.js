import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import removeFile from '@salesforce/apex/FileUploadController.removeFile';
import getFiles from '@salesforce/apex/FileUploadController.getFiles';
import uploadFiles from '@salesforce/apex/FileUploadController.uploadFiles';
import { generateUrl } from 'lightning/fileDownload'

export default class FileUploadComponent extends NavigationMixin(LightningElement) {
    @api label;
    @api acceptedFormats;
    @api multiple;
    @api required;
    @api defaultFiles = [];
    @api recordId;
    @track filesToAdd = [];

    @wire(getFiles, {recordId: '$recordId'}) 
    wiredFiles({error, data}) {
        console.log('RECORD ID FILES' + this.recordId);
        if (data) {
            console.log('WIRED FILES');
            this.defaultFiles = [...data];
            this.filesToAdd = [...data];
        }
        else if (error) {
            console.log('ERROR SETTING FILES' + JSON.stringify(error));
        }
    }

    handleUploadFinished(event) {
        this.filesToAdd = [...this.filesToAdd, ...event.detail.files];
        console.log('FILES: ' + JSON.stringify(this.filesToAdd));
    }

    fileIsDefaultFile(documentId) {
        this.defaultFiles.forEach(file => {
            if (file.documentId === documentId) {
                return true;
            }
        });
        return false;
    }

    handleRemoveFile(event) {
        let index = event.target.dataset.index;
        let contentDocumentId = this.filesToAdd[index].documentId;
        console.log('Remove index' + event.target.dataset.index);
        console.log(this.filesToAdd[event.target.dataset.index]);
        if (!this.fileIsDefaultFile(contentDocumentId)) { // delete file if it was uploaded by user
            console.log('FROM SERVER');
            removeFile({contentDocumentId: contentDocumentId})
            .then(function () {
                let tmp = [...this.filesToAdd];
                tmp.splice(index, 1);
                this.filesToAdd = [...tmp];
            }.bind(this))
            .catch((err)=> {
                console.log('ERROR' + JSON.stringify(err));
            })
        }
        else { // just remove from view
            console.log('FROM VIEW');
            let tmp = [...this.filesToAdd];
            tmp.splice(index, 1);
            this.filesToAdd = [...tmp];
        } 
    }

    handleFilePreview(event) {
        console.log('Show id' + event.target.dataset.documentId);
        const url = generateUrl(event.target.dataset.documentId);
        console.log('URL: ' + url);
        window.open(url, '_blank');
    }

    @api reportValidity() {
        return this.template.querySelector('lightning-file-upload').reportValidity();
    }

    @api
    upload(recordId) {
        console.log('UPLOAD' + recordId);
        let fileIds = [];

        this.filesToAdd.forEach((file) => {
            console.log('FILE: ' + file.documentId);
            fileIds.push(file.documentId);
        })

        console.log('File IDS ' + fileIds + ' ' +  fileIds.length);

        return uploadFiles({recordId: recordId, contentDocumentIds: fileIds});
    }

    removeFiles() {
        this.filesToAdd.forEach((file) => {
            if (!this.fileIsDefaultFile(file.documentId)) {
                removeFile({contentDocumentId: file.documentId});
            }
        })
    }

    @api
    clear() {
        // this.removeFiles();
        this.filesToAdd = [];
        this.defaultFiles = [];
    }
}