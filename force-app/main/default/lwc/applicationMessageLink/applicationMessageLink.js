import { LightningElement, api,wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import APPLICATION_SELECTED from '@salesforce/messageChannel/Application_Selected__c';

export default class ApplicationMessageLink extends LightningElement {
    @api label;
    @api recordId;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        console.log('RECORD ID' + this.recordId);
        console.log('LABEL' + this.label);
    }

    handleClick(event) {
        // this.counter *= factor;
        const payload = {
            Id: this.recordId
        };
        publish(this.messageContext, APPLICATION_SELECTED, payload);
    }
}