import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import newPositionModal from 'c/newPositionForm';

import seeIt from '@salesforce/label/c.lbl_see_it';
import newTemplate from '@salesforce/label/c.lbl_new_template';
import createNewTemplate from '@salesforce/label/c.lbl_create_new_template';
import here from '@salesforce/label/c.lbl_here';
import recordCreated from '@salesforce/label/c.lbl_record_created';
import successLabel from '@salesforce/label/c.lbl_success';

export default class NewPositionTemplateButton extends NavigationMixin(LightningElement) {
    labels = {
        button: newTemplate,
        title: createNewTemplate,
        here: here,
        created: recordCreated,
        seeIt: seeIt,
        success: successLabel
    }

    showRecordCreatedToast(recordId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        }).then((url) => {
            const event = new ShowToastEvent({
                variant: 'success',
                title: (this.labels.success + '!'),
                message: this.labels.created + ' ' + this.labels.seeIt + ' {0}!',
                messageData: [
                    {
                        url,
                        label: this.labels.here,
                    },
                ],
            });
            this.dispatchEvent(event);
        });
    }

    async handleClick() {
        const result = await newPositionModal.open({
            label: this.labels.title,
            size: 'large',
            isTemplate: true,
            mode: 'Create'
        });
      
        if (result.status === 'success') {
            this.showRecordCreatedToast(result.recordId, false);
        }
    }
}