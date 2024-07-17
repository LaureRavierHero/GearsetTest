import { LightningElement, wire } from 'lwc';
import { subscribe, MessageContext, publish } from 'lightning/messageService';
import REFRESH_CHANNEL from "@salesforce/messageChannel/refreshMessageChannel__c";
import APPLICATION_SELECTED from '@salesforce/messageChannel/Application_Selected__c';
import {
	registerRefreshContainer,
	unregisterRefreshContainer,
  } from "lightning/refresh";

export default class ApplicationFormView extends LightningElement {
    applicationSubscription = null;
    // refreshSubscription = null;
    applicationId = null;

    @wire(MessageContext)
    messageContext;

    handleActionExecuted() {
      console.log('ACTION EXECUTED BY PORTAL BUTTONS APPLICATION');
      publish(this.messageContext, REFRESH_CHANNEL, {});
      this.template.querySelector('c-intake-small-view').refresh();
    }

    handleIntakeChanged() {
      console.log('Handle intake changed');
      this.template.querySelector('c-portal-buttons').refreshButtons();
    }
    
    subscribeToMessageChannel() {
      if (!this.applicationSubscription) {
          this.applicationSubscription = subscribe(
          this.messageContext,
          APPLICATION_SELECTED,
          (message) => this.handleMessageApplication(message)
          );
      }
      // if (!this.refreshSubscription) {
      //   this.refreshSubscription = subscribe(
      //     this.messageContext,
      //     REFRESH_CHANNEL,
      //     (message) => this.handleMessageRefresh(message)
      //     );
      // }
    }

    handleMessageApplication(message) {
        console.log('HANDLE MESSAGE APPLICATION' + message.Id);
        this.applicationId = message.Id;
    }

  //   handleMessageRefresh(message) {
  //     console.log('HANDLE MESSAGE REFRESH');
  //     this.template.querySelector('c-portal-buttons').refreshButtons();
  //     let tmp = this.applicationId;
  //     this.applicationId = '';
  //     this.applicationId = tmp;
  // }

    clear() {
        this.applicationId = null;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        console.log('REGISTER REFRESH CONTAINER APPLICATION');
        this.refreshContainerID = registerRefreshContainer(
          this.template.host,
          this.refreshContainer.bind(this),
        );
    }

    // connectedCallback() {
		
	//   }

	  disconnectedCallback() {
		  unregisterRefreshContainer(this.refreshContainerID);
	  }

	  refreshContainer(refreshPromise) {
      console.log("REFRESHING APPLICATION\n\n");
      return refreshPromise.then((status) => {
          // publish(this.messageContext, REFRESH_CHANNEL, {});
          // this.template.querySelector('c-intake-small-view').refresh();
        });
		}
}