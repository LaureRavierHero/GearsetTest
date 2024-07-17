import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';

import TIMESHEET_ENTRY_OBJECT from "@salesforce/schema/Timesheet_entry__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import AMOUNT_FIELD from '@salesforce/schema/Timesheet_entry__c.Amount__c';
import COMMENT_FIELD from '@salesforce/schema/Timesheet_entry__c.Comment__c';
import TYPE_FIELD from '@salesforce/schema/Timesheet_entry__c.Expense_type__c';

import date from '@salesforce/label/c.lbl_Date';
import newExpense from '@salesforce/label/c.lbl_New_expense';
import uploadedAttachment from '@salesforce/label/c.lbl_Uploaded_attachment';
import removeAttachment from '@salesforce/label/c.lbl_Remove_attachment';
import attachment from '@salesforce/label/c.lbl_Attachment';
import labelSave from '@salesforce/label/c.lbl_save';
import labelClose from '@salesforce/label/c.lbl_Close';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExpenseModal extends LightningModal {
	// Data is passed to api properties via .open({ options: [] })
	@api timesheetId;
	@api minDate;
	@api maxDate;

	labels = {
		date: date,
		newExpense: newExpense,
		uploadedAttachment: uploadedAttachment,
		removeAttachment: removeAttachment,
		attachment: attachment,
		labelSave: labelSave,
		labelClose: labelClose
	};

	objectApiName = TIMESHEET_ENTRY_OBJECT;

	RecordTypeId;
	date;
	amount;
	contentVersionId;
	documentId
	attachmentName
	fileUploaded = false;

	AMOUNT_FIELD = AMOUNT_FIELD;
	COMMENT_FIELD = COMMENT_FIELD;
	TYPE_FIELD = TYPE_FIELD;

	// connectedCallback() {
	// 	console.log('this.minDate');
	// 	console.log(this.minDate);

	// 	console.log('this.maxDate');
	// 	console.log(this.maxDate);
	// }

	@wire(getObjectInfo, { objectApiName: TIMESHEET_ENTRY_OBJECT }) wireTimesheetEntryData(objectInfo, error){
		if(objectInfo){
			let recordTypeInfo = objectInfo?.data?.recordTypeInfos;

			if(recordTypeInfo){
				this.RecordTypeId = Object.keys(recordTypeInfo).find(rtype=>(recordTypeInfo[rtype].name === 'Expense'));
			}
		}
	}

	get acceptedFormats(){
		return ['.pdf', '.png', '.jpg', '.jpeg'];
	}

	handleUploadFinished(event){
		// Get the list of uploaded files
		const uploadedFiles = event.detail.files;

		console.log('uploadedFiles');
		console.log(uploadedFiles);

		if(uploadedFiles.length > 0){
			// Get values from first array in object
			this.contentVersionId = uploadedFiles[0].contentVersionId;
			this.documentId = uploadedFiles[0].documentId;
			this.attachmentName = uploadedFiles[0].name;
			this.fileUploaded = true;
		}
	}

	resetFile(){
		this.contentVersionId = null;
		this.attachmentName = null;
		this.fileUploaded = false;
	}

	changeDate(event){
		this.date = event.target.value;
	}

	changeAmount(event){
		this.amount = event.target.value;
	}

	handleReset(event) {
		this.close('Modal reset');

		// const inputFields = this.template.querySelectorAll('lightning-input-field');

		// if (inputFields) {
		// 	inputFields.forEach(field => {
		// 		field.reset();
		// 	});

		// 	// this.date = null;
		// }
	}

	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting

		const fields = event.detail.fields;

		fields.RecordTypeId = this.RecordTypeId;
		fields.Timesheet__c = this.timesheetId;
		fields.Date__c = this.date;
		fields.Name = 'Expense ' + this.date;
		// fields.Amount__c = this.amount;

		fields.Attachment_content_version_ID__c = this.contentVersionId;
		fields.Attachment_document_ID__c = this.documentId;
		fields.Attachment_name__c = this.attachmentName;

		console.log('fields');
		console.log(fields);

		if(fields.Amount__c != null && fields.Date__c != null){
			this.template.querySelector('lightning-record-edit-form').submit(fields);
		}
	}

	handleSuccess(event) {
		this.dispatchEvent(new ShowToastEvent({
			title: 'Timesheet entry created',
			variant: 'success',
		}));

		this.close('Created');
	}

	handleError(event) {
	   this.dispatchEvent(new ShowToastEvent({
			title: JSON.stringify(event.detail),
			variant: 'error',
		}));
	}
}