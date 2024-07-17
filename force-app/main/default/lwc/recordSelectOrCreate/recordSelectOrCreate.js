import { api, LightningElement } from 'lwc';
import NewRecordModal from 'c/newRecordModal'
import newCandidate from '@salesforce/label/c.lbl_New_candidate';

export default class RecordSelectOrCreate extends LightningElement {
    @api objectName = 'Candidate__c';
    @api hiddenFields = [];
    @api hideFields = [];
    @api label;
    @api placeholder;
    @api required = false;

    labels = {
        newCandidate : newCandidate
    }

    @api reportValidity() {
        return this.template.querySelector('lightning-record-picker').reportValidity();
    }

    @api clear() {
        this.template.querySelector('lightning-record-picker').clearSelection();

    }

    handleError(event) {
        console.log('Error: ' + JSON.stringify(event.detail));
    }

    handleSelection(event) {
        this.dispatchEvent(new CustomEvent('recordselected', {detail: {recordId: event.detail.recordId}}));
    }

    async handleCreateNew(event) {
        // call modal create new record
        NewRecordModal.open({
            hiddenFields: this.hiddenFields,
            hideFields: this.hideFields,
            title: this.label,
            objectName: this.objectName,
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
        })
        .then((res) => {
            if (res.status == 'success') {
                console.log('RESULT ' + JSON.stringify(res));
                this.template.querySelector('lightning-record-picker').value = res.recordId;
                console.log('After set');
                this.dispatchEvent(new CustomEvent('recordselected', {detail: {recordId: res.recordId}}));
            }
        })
        .catch((err) => {
            console.log('ERROR ' + JSON.stringify(err));
        })
    }
}