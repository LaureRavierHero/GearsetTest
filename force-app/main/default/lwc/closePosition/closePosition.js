import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from "lightning/refresh";

import checkCloseable from '@salesforce/apex/ClosePositionController.checkCloseable';
import positionNotCloseableLabel from '@salesforce/label/c.lbl_position_not_closeable_error';

export default class ClosePosition extends LightningElement {
    @api recordId;
    showModal = false;
    flowName = 'Close_position_with_reason';
    flowParameters;

    labels = {
        notCloseable: positionNotCloseableLabel
    }

    showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});

		this.dispatchEvent(event);
	}

    handleFlowStatusChange(event) {
        console.log(event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.showModal = false;
            this.dispatchEvent(new RefreshEvent());
        }
    }

    closeModal() {
        this.showModal = false;
    }

    @api async invoke() {
        let closeable = await checkCloseable({positionId: this.recordId});
        if (!closeable) {
            this.showToast('Error', this.labels.notCloseable, 'error');
        }
        else {
            // close position
            this.flowParameters = [{
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }];
            this.showModal = true;
        }
    }
}