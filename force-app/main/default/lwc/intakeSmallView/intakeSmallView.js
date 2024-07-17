import { LightningElement, api, wire } from 'lwc';
// import {
// 	subscribe,
// 	APPLICATION_SCOPE,
// 	MessageContext,
//   } from "lightning/messageService";
// import REFRESH_CHANNEL from '@salesforce/messageChannel/refreshMessageChannel__c';
// import {
// 	registerRefreshContainer,
// 	unregisterRefreshContainer,
//   } from "lightning/refresh";
import {refreshApex} from '@salesforce/apex'

import getMostRecentIntake from '@salesforce/apex/IntakeViewController.getMostRecentIntake';
import dateLabel from '@salesforce/label/c.lbl_Date';

export default class IntakeSmallView extends LightningElement {
    @api applicationId;
    intakes;

    provisionedData;
    // subscription = null;

    labels = {
        date: dateLabel
    }

    // @wire(MessageContext)
    // messageContext;
    
    // subscribeToMessageChannel() {
    //     if (!this.subscription) {
    //         this.subscription = subscribe(
    //         this.messageContext,
    //         REFRESH_CHANNEL,
    //         (message) => this.handleMessage(message), 
    //         { scope: APPLICATION_SCOPE }
    //         );
    //     }
    // }

    // handleMessage(message) {
    //     console.log('REFRESH INTAKE LWC');
    //     this.template.querySelector('c-portal-buttons').refreshButtons();
    //     return refreshApex(this.provisionedData);
    // }

    // connectedCallback() {
    //     console.log('AM HERE');
    //     this.subscribeToMessageChannel();
    //     console.log('REGISTER REFRESH CONTAINER INTAKE');
    //     this.refreshContainerID = registerRefreshContainer(
    //       this.template.host,
    //       this.refreshContainer.bind(this),
    //     );
    // }

    // disconnectedCallback() {
    //     unregisterRefreshContainer(this.refreshContainerID);
    // }

    // refreshContainer(refreshPromise) {
    //     console.log("REFRESHING INTAKE\n\n");
    //     return refreshPromise.then((status) => {
    //         // publish(this.messageContext, REFRESH_CHANNEL, {});
    //         // this.template.querySelector('c-intake-small-view').refresh();
    //         refreshApex(this.provisionedData);
    //     });
    // }

    @wire(getMostRecentIntake, { applicationId: '$applicationId' })
    wiredRecentIntake(res) {
        this.provisionedData = res;
        const {error, data} = res;
        if (data) {
            console.log('DATA ' + JSON.stringify(data));
            this.intakes = data;
        }
        else if (error) {
            console.log(JSON.stringify('ERROR: ' + JSON.stringify(error)));
        }
    }

    @api refresh() {
        console.log('REFRESH INTAKE LWC');
        refreshApex(this.provisionedData);
        this.template.querySelector('c-portal-buttons').refreshButtons();
    }

    handleActionExecuted() {
        console.log('ACTION EXECUTED BY PORTAL BUTTONS INTAKE');
        // publish(this.messageContext, REFRESH_CHANNEL, {});
        this.dispatchEvent(new CustomEvent('intakestatuschanged'));
        refreshApex(this.provisionedData);
        // this.template.querySelector('c-intake-small-view').refresh();
      }

    // @api
    // refresh() {
    //     getMostRecentIntake({applicationId: this.applicationId })
    //     .then(() => {
    //         console.log('DATA ' + JSON.stringify(data));
    //         this.intake = data;
    //     })
    //     .catch ((error) => {
    //         console.log(JSON.stringify('ERROR: ' + JSON.stringify(error)));
    //     })
    // }
}