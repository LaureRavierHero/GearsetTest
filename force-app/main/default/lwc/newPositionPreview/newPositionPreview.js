import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import returnLabel from '@salesforce/label/c.lbl_return';
import confirmLabel from '@salesforce/label/c.lbl_confirm';
import header from '@salesforce/label/c.lbl_confirm_position_creation';

export default class NewPositionPreview extends LightningModal {
    @api label;
    @api fields;
    @api recordTypeId;

    labels = {
        return: returnLabel,
        confirm: confirmLabel,
        tite: header
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