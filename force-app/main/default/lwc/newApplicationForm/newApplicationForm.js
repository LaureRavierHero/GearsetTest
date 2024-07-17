import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'
import getRecordTypeId from '@salesforce/apex/ApplicationFormController.getApplicationRecordTypeId';
import getNumApplications from '@salesforce/apex/ApplicationFormController.getNumApplications';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import newCandidate from '@salesforce/label/c.lbl_New_candidate';
import cancelLabel from '@salesforce/label/c.lbl_Cancel';
import submitLabel from '@salesforce/label/c.LBL_submit';
import uploadResume from '@salesforce/label/c.lbl_Upload_resume';
import title from  '@salesforce/label/c.LBL_new_application';
import maxApplication from '@salesforce/label/c.lbl_max_number_of_applications_message'
import selectCandidate from '@salesforce/label/c.lbl_select_a_candidate';
import clear from '@salesforce/label/c.lbl_clear';
import here from '@salesforce/label/c.lbl_here';
import recordCreated from '@salesforce/label/c.lbl_record_created';
import seeIt from '@salesforce/label/c.lbl_see_it';
import successLabel from '@salesforce/label/c.lbl_success';

export default class NewApplicationForm extends NavigationMixin(LightningElement) {
	objectName = 'Application__c'
	createCandidate = false;
	fieldValues = {};
	hideFields = ['Candidate__c', 'Position__c', 'Name'];
	hiddenFields = ['recordTypeId', 'Is_preferred_candidate__c'];
	candidateHideFields = ['Name'];
	@track numApplications;
	@track numAllowed;
	applicationsAllowed = false;
	_recordId;
	recordTypeId;
	provisionedData;
	loading = false;

	labels = {
		newCandidate : newCandidate,
		cancelLabel : cancelLabel,
		submitLabel : submitLabel,
		uploadResume : uploadResume,
		title : title,
		maxApplication : maxApplication,
		selectCandidate : selectCandidate,
		clear : clear,
		created: recordCreated,
        seeIt: seeIt,
        success: successLabel,
		here: here,
	};

	hiringManagerContext = false;
	vendorContext = false;

	_audienceType;
	@api 
	get audienceType() {
		return this._audienceType;
	}
	set audienceType(value) {
		console.log('AUDIENCE TYPE ' + value);
		this._audienceType = value;
		if (this.audienceType === 'HiringManager') {
			this.hiringManagerContext = true;
			this.fieldValues['Is_preferred_candidate__c'] = true;
			console.log('HM context');
		}
		else if (this.audienceType === 'Vendor') {
			this.vendorContext = true;
			this.applicationsAllowed = true;
			this.fieldValues['Is_preferred_candidate__c'] = false;
			console.log('Vendor context');
		}
	}

	@api 
	get recordId() {
		return this._recordId;
	}
	set recordId(value) {
		this._recordId = value;
		this.addValueToFieldValues('Position__c', this._recordId);
	}

	addValueToFieldValues(fieldName, value) {
		let tmp = JSON.parse(JSON.stringify(this.fieldValues));
		tmp[fieldName] = value;
		this.fieldValues = tmp;
	}

	@wire(getRecordTypeId, {positionId: '$recordId'})
	wiredRecordTypeId({error, data}){
		if (error) {
			console.log('ERROR' + error);
		} else if (data) {
			console.log('RECORD TYPE ID ' + data);
			this.recordTypeId = data;
			this.addValueToFieldValues('recordTypeId', this.recordTypeId);
		}
	}

	@wire(getNumApplications, {recordId: '$recordId'})
	wiredNumApps(result) {
		this.provisionedData = result;
		let {error, data} = result;
		if (error) {
			console.log('ERROR' + error);
		} else if (data) {
			this.numApplications = data.numApplications;
			this.numAllowed = data.numAllowed;
			if (this.vendorContext) {
				this.applicationsAllowed = (this.numApplications < this.numAllowed);
			}
			else {
				this.applicationsAllowed = true;
			}
			this.labels.title = title;
			if (this.applicationsAllowed) {
				if (this.vendorContext) {
					this.labels.title += ' ' + '(' +  (this.numApplications + 1) + '/' + (this.numAllowed) + ')';
				}
			}
		}
	};

	handleCandidateSelection(event) {
		this.addValueToFieldValues('Candidate__c', event.detail.recordId);
	}

	clear() {
		this.template.querySelector('c-custom-record-form').clear();
		this.template.querySelector('c-record-select-or-create').clear();
		this.template.querySelector('c-file-upload-component').clear();
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

	handleRecordSubmitted(event) {
		console.log('HANDLE SUBMITTED' + event.detail.recordId);
		this.template.querySelector('c-file-upload-component').upload(event.detail.recordId)
		.then(() => {
			console.log('FILES UPLIADED');
			this.showRecordCreatedToast(event.detail.recordId);
			// this.clear();
			this.loading = true;
			setTimeout(() => {
				this.loading = false;
			}, 0);
			return refreshApex(this.provisionedData);
		})
		.catch((err) => {
			console.log('ERROR' + JSON.stringify(err));
		})
	}

	handleSave() {
		// Check if candidate selected and CV chosen
		let fileSelected = this.template.querySelector('c-file-upload-component').reportValidity();
		let candidateSelected = this.template.querySelector('c-record-select-or-create').reportValidity();
		let applicationValid = this.template.querySelector('c-custom-record-form').reportValidity();

		if (fileSelected && candidateSelected && applicationValid) { // 
			this.template.querySelector('c-custom-record-form').clickSubmit();
		}
	}
}