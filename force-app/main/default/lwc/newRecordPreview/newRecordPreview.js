import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import returnLabel from '@salesforce/label/c.lbl_return';
import confirmLabel from '@salesforce/label/c.lbl_confirm';

export default class NewRecordPreview extends LightningModal {
    @api label;
    @api objectName;
    @api recordTypeId;
    @api recordId;
    @api fieldValues;

    labels = {
        return: returnLabel,
        confirm: confirmLabel
    }

    handleCloseClick() {
        this.close({status: 'cancelled'});
    }

    handleConfirm() {
        this.close({status: 'confirmed'});
    }

    handleReturn() {
        this.close({status: 'cancelled'});
    }
}