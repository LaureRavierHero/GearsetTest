import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';

import newRecord from '@salesforce/label/c.lbl_new_record';
import cancelLabel from '@salesforce/label/c.lbl_Cancel';
import saveLabel from '@salesforce/label/c.lbl_save';

export default class NewRecordModal extends LightningModal {
    @api objectName;
    @api recordTypeId;
    @api hiddenFields;
    @api hideFields;
    @api title;

    labels = {
        cancelLabel : cancelLabel,
		saveLabel : saveLabel
	};

    handleCloseClick() {
        this.close({status: 'canceled', recordId: null});
    }

    handleCancel() {
        this.close({status: 'canceled', recordId: null});
    }

    handleSave(event) {
        this.template.querySelector('c-custom-record-form').clickSubmit();
    }

    handleSuccess(event) {
        this.close({status: 'success', recordId: event.detail.recordId});
    }
}