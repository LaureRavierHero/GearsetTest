import { LightningElement, api,wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import APPLICATION_SELECTED from '@salesforce/messageChannel/Application_Selected__c';

export default class ApplicationMessageButton extends LightningElement {
    @api label;
    @api recordId;

    @wire(MessageContext)
    messageContext;

    handleClick(event) {
        // this.counter *= factor;
        const payload = {
            Id: 'a0RVe000000iviXMAQ'
        };
        publish(this.messageContext, APPLICATION_SELECTED, payload);
    }
}