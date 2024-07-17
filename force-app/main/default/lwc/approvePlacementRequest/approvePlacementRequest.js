import { LightningElement, api, wire } from 'lwc';
import handlePlacementRequestInformation from '@salesforce/apex/PlacementFunctions.handlePlacementRequestInformation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import successLabel from '@salesforce/label/c.lbl_success';
import errorMessage from '@salesforce/label/c.lbl_info_request_sent_error';
import successMessage from '@salesforce/label/c.lbl_info_request_sent';

export default class ApprovePlacementRequest extends LightningElement {
    @api recordId;

    @api async invoke() {
        handlePlacementRequestInformation({recordId: this.recordId})
        .then(() => {
            const event = new ShowToastEvent({
                variant: 'success',
                title: successLabel,
                message: successMessage
            });
            this.dispatchEvent(event);
        })
        .catch((err) => {
            console.log(JSON.stringify(err));
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error',
                message: errorMessage + err.body.message
            });
            this.dispatchEvent(event);
        })
    }
}