import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createPlacement from '@salesforce/apex/PlacementFunctions.createPlacement';

import successMessage from '@salesforce/label/c.toast_header_placement_created';

const labels = {
    successMessage: successMessage
}

export default class CreatePlacementFromApplication extends NavigationMixin(LightningElement) {
    @api recordId;

    @api async invoke() {
        // TODO: make sure Professional__c is set OR Contact_email__c AND Contact_phone__c are filled
        // Get application
        createPlacement({applicationId: this.recordId})
        .then ((placementId) => {
            console.log('PLACEMENT ID' + placementId);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: placementId,
                    actionName: 'view'
                }
            })
    
            const evt = new ShowToastEvent({
                message: labels.successMessage,
                variant: 'success',
            });
            this.dispatchEvent(evt);
        })
        .catch((error) => {
            const evt = new ShowToastEvent({
                message: error.body.message,
                variant: 'error',
            });
            this.dispatchEvent(evt);
        });
    }
}