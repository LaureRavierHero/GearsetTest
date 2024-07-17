import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';

import newPosition from '@salesforce/label/c.lbl_New_position';
import newPositionModal from 'c/newPositionForm';
import approvalCommentPopup from 'c/approvalCommentPopup';
import submitForApproval from '@salesforce/apex/PositionFormController.submitForApproval'
import createNewPosition from '@salesforce/label/c.lbl_create_new_position';
import here from '@salesforce/label/c.lbl_here';
import recordCreated from '@salesforce/label/c.lbl_record_created';
import recordCreatedSubmitted from '@salesforce/label/c.lbl_record_created_submitted';
import seeIt from '@salesforce/label/c.lbl_see_it';
import headerApprovalMessage from '@salesforce/label/c.lbl_add_message_to_hiring_desk';
import duplicateLabel from '@salesforce/label/c.lbl_duplicate';
import successLabel from '@salesforce/label/c.lbl_success';

export default class NewPositionButton extends NavigationMixin(LightningElement) {
    labels = {
        title: createNewPosition,
        button: newPosition,
        here: here,
        created: recordCreated,
        createdSubmitted: recordCreatedSubmitted,
        seeIt: seeIt,
        approvalMessageHeader: headerApprovalMessage, 
        success: successLabel
    }

    _recordId;

    @api 
    get recordId() {
        return this._recordId;
    }
    set recordId(value) { // IF we are on a record, we are duplicating, if not, we're creating a new record
        this._recordId = value;
        this.labels.button = duplicateLabel;
    }

    showRecordCreatedToast(recordId, submitted) {
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
                message: (submitted? this.labels.createdSubmitted: this.labels.created) + ' ' + this.labels.seeIt + ' {0}!',
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
        newPositionModal.open({
            label: this.labels.title,
            size: 'large',
            description: 'Modal for creation of new position',
            isTemplate: false,
            positionId: this.recordId,
        })
        .then ((result) => {
            if (result.status == 'success' && result.submit) {
                approvalCommentPopup.open({
                    label: this.labels.approvalMessageHeader,
                    size: 'small'
                })
                .then((comment) => {
                    return submitForApproval({positionId: result.recordId, comment: comment});
                })
                .then(() => {
                    this.showRecordCreatedToast(result.recordId, true);
                })
                .catch((err) => {
                    console.log('ERROR' + JSON.stringify(err));
                })
            }
            else if (result.status === 'success') {
                this.showRecordCreatedToast(result.recordId, false);
            }
            else if (result.status == 'canceled' && result.recordId) {
                deleteRecord(result.recordId)
                .then((res) => {
                    console.log('DELETED');
                })
                .catch((err) => {
                    console.log('ERROR ' + JSON.stringify(err));
                })
            }
        })
        .catch((err) => {
            console.log('ERROR ' + JSON.stringify(err));
        })
    }
}