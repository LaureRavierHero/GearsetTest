import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';
import LightningModal from 'lightning/modal';
import getVendors from '@salesforce/apex/VendorsByCategoryController.getVendors';
import sendToVendorsMethod from '@salesforce/apex/VendorsByCategoryController.sendToVendors';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import doesPositionCategoryExist from '@salesforce/apex/VendorsByCategoryController.doesPositionCategoryExist';

import matchingVendors from '@salesforce/label/c.LWC_Matching_Vendors';
import remainingVendors from '@salesforce/label/c.LWC_Remaining_Vendors';
import noMatchingVendors from '@salesforce/label/c.LWC_No_Matching_Vendors';
import sendToVendors from '@salesforce/label/c.LWC_Send_To_Vendors';
import sendToVendorsSuccess from '@salesforce/label/c.LWC_Vendors_To_Mail_Return_Success';
import noCategoriesSelected from '@salesforce/label/c.LWC_No_Categories_Selected';
import recentlyDistributed from '@salesforce/label/c.lbl_Recently_distributed';
import vendorsToMail from '@salesforce/label/c.LWC_Vendors_To_Mail';

export default class DistributeToVendorsModal extends LightningModal {
    @api recordId;
    @api label;
    @track matchingVendors = [];
	@track remainingVendors = [];
	@track disabled = false;
	@track loading = false;
	matchingVendorsVisible = false;
	remainingVendorsVisible = false;
    alertVisible = false;
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
	};

    connectedCallback() {
		loadStyle(this, FontAwesome6 + '/css/all.min.css')
        .catch(error => {
            console.error('Error loading FontAwesome:', error);
        });

		doesPositionCategoryExist({positionId: this.recordId})
		.then((res) => {
			this.error = undefined;

			if (res == 0) {
				this.alertVisible = true;
			}
		})
		.catch((err) => {
			this.error = err.message.body;
		})

		getVendors({positionId: this.recordId})
		.then((data) => {
			if(data) {
				this.error = undefined;
	
				if (data.matchingVendors.length >= 1) {
					this.matchingVendors = data.matchingVendors;
					this.matchingVendorsVisible = true;
					
					this.matchingVendors.forEach(vendor => {
						if(vendor.Checked == true) {
							this.selectedVendors.push(vendor.Id);
						}
					});
				}
				if (data.remainingVendors.length >= 1) {
					this.remainingVendors = data.remainingVendors;
					this.remainingVendorsVisible = true;
				}
			}
		})
		.catch((err) => {
			console.log('ERROR ' + JSON.stringify(err));
			this.error = err.message.body;
		})
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
    showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});

		this.dispatchEvent(event);
	}

	closeAlert() {
		this.alertVisible = false;
	}

    handleCloseClick() {
        this.close({status: 'canceled'});
    }

    handleCancel() {
        this.close({status: 'canceled'});
    }

	handleSubmit() {
		this.disabled = true;
		this.loading = true;

		sendToVendorsMethod({
			positionId: this.recordId,
			vendorIds: JSON.stringify(this.selectedVendors)
		})
		.then(() => {
			this.showToast('Succes', this.labels.sendToVendorsSuccess, 'success');
			this.disabled = false;
			this.loading = false;
            this.close({status: 'success'});
			// notifyRecordUpdateAvailable([{recordId: this.recordId}]);
		})
		.catch((error) => {
			this.showToast('Something went wrong', error.body.message, 'error');
			this.disabled = false;
			this.loading = false;
		});
	}
}