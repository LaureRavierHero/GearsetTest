import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DistributeToVendorsModal from 'c/distributeToVendorsModal';

import areRequiredFieldsFilled from '@salesforce/apex/VendorsByCategoryController.areRequiredFieldsFilled';

import distributeToVendorsMissingFieldsError from '@salesforce/label/c.lbl_Distribute_to_vendors_missing_fields_error';

export default class DistributePositionToVendors extends LightningElement {
    @api recordId;
    // showModal = false;

    labels = {
        distributeToVendorsMissingFieldsError: distributeToVendorsMissingFieldsError
    }

    showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});

		this.dispatchEvent(event);
	}

    @api async invoke() {
        let requiredFieldsFilled = await areRequiredFieldsFilled({positionId: this.recordId});
        console.log('Required fields filled: ' + JSON.stringify(requiredFieldsFilled));
        if (!requiredFieldsFilled) {
            this.showToast('Error', this.labels.distributeToVendorsMissingFieldsError, 'error');
        }
        else {
            const res = await DistributeToVendorsModal.open({
                label: "",
                recordId: this.recordId,
            });
        }
    }
}