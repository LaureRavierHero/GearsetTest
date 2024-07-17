import LightningModal from 'lightning/modal';
import { api } from 'lwc';

import complete from '@salesforce/label/c.lbl_complete';


export default class ApprovalCommentPopup extends LightningModal {
    @api label;

    labels = {
        complete: complete
    }
    
    handleCloseClick() {
        this.close('');
    }

    handleSubmit() {
        this.close(this.template.querySelector('lightning-textarea').value);
    }
}