import doesPositionCategoryExist from '@salesforce/apex/VendorsByCategoryController.doesPositionCategoryExist';
import getVendors from '@salesforce/apex/VendorsByCategoryController.getVendors';
import sendToVendorsMethod from '@salesforce/apex/VendorsByCategoryController.sendToVendors';
import areRequiredFieldsFilled from '@salesforce/apex/VendorsByCategoryController.areRequiredFieldsFilled';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import vendorsToMail from '@salesforce/label/c.LWC_Vendors_To_Mail';
import matchingVendors from '@salesforce/label/c.LWC_Matching_Vendors';
import remainingVendors from '@salesforce/label/c.LWC_Remaining_Vendors';
import noMatchingVendors from '@salesforce/label/c.LWC_No_Matching_Vendors';
import sendToVendors from '@salesforce/label/c.LWC_Send_To_Vendors';
import sendToVendorsSuccess from '@salesforce/label/c.LWC_Vendors_To_Mail_Return_Success';
import noCategoriesSelected from '@salesforce/label/c.LWC_No_Categories_Selected';
import recentlyDistributed from '@salesforce/label/c.lbl_Recently_distributed';
import distributeToVendorsMissingFieldsError from '@salesforce/label/c.lbl_Distribute_to_vendors_missing_fields_error';

import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';

export default class VendorsByCategory extends LightningElement {
	@track matchingVendors = [];
	@track remainingVendors = [];
	@track disabled = false;
	@track loading = false;
	canDistribute;
	matchingVendorsVisible = false;
	remainingVendorsVisible = false;
	alertVisible = false;
	recordId;
	selectedVendors = [];
	error;

	labels = {
		vendorsToMail: vendorsToMail,
		matchingVendors: matchingVendors,
		remainingVendors: remainingVendors,
		noMatchingVendors: noMatchingVendors,
		sendToVendors: sendToVendors,
		sendToVendorsSuccess: sendToVendorsSuccess,
		noCategoriesSelected: noCategoriesSelected,
		recentlyDistributed: recentlyDistributed,
		distributeToVendorsMissingFieldsError: distributeToVendorsMissingFieldsError
	};

	showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});

		this.dispatchEvent(event);
	}

	@wire(areRequiredFieldsFilled, {positionId: '$recordId'}) wiredRequiredFieldsFilled({data, error}) {
		console.log(JSON.stringify(data));
		
		this.canDistribute = data;

		if(this.canDistribute === false) {
			this.showToast('Error', this.labels.distributeToVendorsMissingFieldsError, 'error');
			this.dispatchEvent(new CloseActionScreenEvent());
		}
	}

	connectedCallback() {
		// TODO stop al dit in een eigen javascript/html situatie (aparte modal) die geopend wordt als canDistribute true is (zie timesheetRegistration voor voorbeeld)
		// TODO dit zodat we niet de lelijke schaduw effect hebben wat we nu hebben
		if(this.canDistribute === false) {
			this.showToast('Error', this.labels.distributeToVendorsMissingFieldsError, 'error');
			this.dispatchEvent(new CloseActionScreenEvent());
		}

		loadStyle(this, FontAwesome6 + '/css/all.min.css')
			.catch(error => {
				console.error('Error loading FontAwesome:', error);
			});
	}

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.recordId = currentPageReference.state.recordId;
		}
	}

	@wire(doesPositionCategoryExist, {positionId: '$recordId'}) wiredExistingCategory({data, error}) {
		this.error = undefined;

		if(data == 0) {
			this.alertVisible = true;
		}else if (error) {
			this.error = error;

			console.log('this.error matching');
			console.log(this.error);
		}
	}

	closeAlert() {
		this.alertVisible = false;
	}

	@wire(getVendors, {positionId: '$recordId'}) vendors({data, error}) {
		if(data) {
			// console.log('data');
			// console.log(JSON.stringify(data));

			this.error = undefined;

			if(data.matchingVendors.length >= 1) {
				this.matchingVendors = data.matchingVendors;
				this.matchingVendorsVisible = true;
				
				this.matchingVendors.forEach(vendor => {
					if(vendor.Checked == true) {
						this.selectedVendors.push(vendor.Id);
					}
				});
			}

			// console.log('this.selectedVendors');
			// console.log(JSON.stringify(this.selectedVendors));

			if(data.remainingVendors.length >= 1) {
				this.remainingVendors = data.remainingVendors;
				this.remainingVendorsVisible = true;
			}

			// console.log('this.matchingVendors');
			// console.log(JSON.stringify(this.matchingVendors));

			// console.log('this.remainingVendors');
			// console.log(JSON.stringify(this.remainingVendors));
		}else if (error) {
			this.error = error;
			this.matchingVendorsVisible = false;
			this.selectedVendors = []; // Clear selected vendors in case of error

			console.log('this.error matching');
			console.log(this.error);
		}
	}

	handleCheckboxChange(event) {
		const vendorId = event.target.value;
		const checked = event.target.checked;
		
		if (checked && !this.selectedVendors.includes(vendorId)) {
			// Add vendor ID to the selectedVendors array if the checkbox is checked and not already in the array
			this.selectedVendors.push(vendorId);
		} else if (!checked) {
			// Remove vendor ID from selectedVendors array if the checkbox is unchecked
			this.selectedVendors = this.selectedVendors.filter(id => id !== vendorId);
		}
	}

	handleSubmit() {
		console.log('Handle submit');
		this.disabled = true;
		this.loading = true;
		
		// const fields = {};
		// fields['Id'] = this.recordId;
		// fields['Status__c'] = 'Open';
		// fields['Processing_status__c'] = 'Distributed'; // set the field value here

		// const recordInput = { fields };

		sendToVendorsMethod({
			positionId: this.recordId,
			vendorIds: JSON.stringify(this.selectedVendors)
		})
		.then(() => {
			// console.log('then reached');

			this.showToast('Succes', this.labels.sendToVendorsSuccess, 'success');

			this.disabled = false;
			this.loading = false;
			
			// console.log('UPDATE RECORD' + JSON.stringify(recordInput));
			// updateRecord(recordInput);
			this.dispatchEvent(new CloseActionScreenEvent());
			notifyRecordUpdateAvailable([{recordId: this.recordId}]);

		})
		.catch((error) => {
			this.showToast('Something went wrong', error.body.message, 'error');
			this.disabled = false;
			this.loading = false;
		});
	}
}