import { LightningElement, api } from 'lwc';
import sendPlacementForContracting from '@salesforce/apex/PlacementFunctions.sendPlacementForContracting';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class SendPlacementForContracting extends LightningElement {
    @api recordId; 

    @api async invoke() {
        sendPlacementForContracting({recordId: this.recordId})
        .then(() => {
            // Approve approval request

        })
        .then(() => {
            const event = new ShowToastEvent({
                variant: 'success',
                title: 'Success!',
                message: 'Sent placement for contracting'
            });
            this.dispatchEvent(event);
        })
        .catch((err) => {
            console.log(JSON.stringify(err));
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error',
                message: 'Error sending to contracts: ' + err.body.message
            });
            this.dispatchEvent(event);
        })
    }
}