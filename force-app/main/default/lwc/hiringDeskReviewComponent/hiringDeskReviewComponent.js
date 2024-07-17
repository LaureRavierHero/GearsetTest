import { LightningElement, api, track, wire } from 'lwc';
import getSettings from '@salesforce/apex/WorkcomponentApplicationsController.getSettings';
import getData from '@salesforce/apex/WorkcomponentApplicationsController.getApplicationsProcessable';
import handleApproveRejectApplications from '@salesforce/apex/WorkcomponentApplicationsController.handleRejectApproveApplicationsHiringDesk'
import {refreshApex} from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from "lightning/refresh";
import { subscribe, MessageContext, publish } from 'lightning/messageService';

import successTitle from '@salesforce/label/c.Vendors_notified_rejection_advancement_success_title';
import nothingToShow from '@salesforce/label/c.LBL_nothing_to_show'
import errorOpenTitle from '@salesforce/label/c.Vendors_notified_rejection_advancement_open_title';
import buttonRejectAdvance from '@salesforce/label/c.Button_label_reject_advance';
import buttonCancel from '@salesforce/label/c.Button_label_cancel';
import title from '@salesforce/label/c.Window_title_review_component';

import REFRESH_CHANNEL from "@salesforce/messageChannel/refreshMessageChannel__c";

const componentName = 'Hiring desk review component'

const labels = {
	success: successTitle,
	errorStatus: errorOpenTitle,
	windowTitle: title,
	submitLabel: buttonRejectAdvance,
	cancelLabel: buttonCancel,
	nothingToShow: nothingToShow
}

export default class HiringDeskReviewComponent extends LightningElement {
	loading = true;
	@track error = undefined;
	@api recordId;

	labels = labels;

	configuration;
	configurationJson;
	idColumn;
	columns;

	commentByRecordId = {};

	provisionedData;
	// backupData
	@track data;
	hasRecords = false;

	// draftValues = [];
	hasPagination = false;

	sortBy='sendToHiringManager';
	sortDirection='asc';

	@wire(MessageContext)
    messageContext;

	renderedCallback() {
		this.errors = [];
		if (this.configuration)
			return refreshApex(this.provisionedData);
	}

	@wire(getSettings, { componentName: componentName })
	wiredSettings({data, error}) {
		this.loading = true;
		if (data) {
			this.configuration = data;
			this.configurationJson = JSON.stringify(this.configuration);
			this.columns = [...this.configuration.columns];
			this.idColumn = this.configuration.idColumn;
		}
		else if (error) {
			this.error = error;
		}
	}

	@wire(getData, {componentConfigurationJson: '$configurationJson', sortCol: '$sortBy', 
	sortOrder: '$sortDirection', recordId: '$recordId'})
	wiredData(result) {
		this.loading = true;
		this.provisionedData = result;
		
		const {data, error} = result;
		if (data) {
			this.data = JSON.parse(JSON.stringify(data));
			this.hasRecords = !(this.data.length == 0);
			// this.backupData = [...data];
			this.loading = false;
			this.error = undefined;

			let openApplicationsCount = this.data.filter((elem) => elem.sendToHiringManager == 'Open').length;

			if (openApplicationsCount != 0) {
				this.showToast('warning', labels.errorStatus, '');
			}
		}
		else if (error) {
			this.error = error;
			this.loading = false;
			this.data = undefined;
		}
		this.loading = false;
	}

	handleCancel(event) {
		// Add your cancel button implementation here
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	showToast(variant, title, message) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}
	
	handleSubmit() {
		let openApplicationsCount = this.data.filter((elem) => elem.sendToHiringManager == 'Open').length;

		if (openApplicationsCount != 0) {
			this.showToast('error', labels.errorStatus, '');
		}
		else {
			try {
				console.log('HANDLE APPROVE REJECT' + JSON.stringify(this.data));
				handleApproveRejectApplications({ recordsJson: JSON.stringify(this.data),
				positionId: this.recordId})
				.then(() => {
					console.log('APPROVE REJECT HANDLED');
					this.dispatchEvent(new RefreshEvent());
					publish(this.messageContext, REFRESH_CHANNEL, {});
					this.showToast('success', labels.success, '');
					this.dispatchEvent(new CloseActionScreenEvent());
				})
				// notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
			}
			catch(error) {
				console.log('Other error!' +JSON.stringify(error));
				this.showToast('error', 'Error', error.body.message);
			}
		}
	}
}