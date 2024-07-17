import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getTemplate from '@salesforce/apex/PositionFormController.getTemplate';
import getRecordTypeId from '@salesforce/apex/PositionFormController.getRecordTypeId';
import getTemplateRecordTypeId from '@salesforce/apex/PositionFormController.getTemplateRecordTypeId';
import getRecord from '@salesforce/apex/PositionFormController.getRecord';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import newPosition from '@salesforce/label/c.lbl_New_position';
import addFiles from '@salesforce/label/c.lbl_Add_files';
import cancelLabel from '@salesforce/label/c.lbl_Cancel';
import saveLabel from '@salesforce/label/c.lbl_save';
import saveAndSubmit from '@salesforce/label/c.lbl_Save_and_submit';
import selectTemplate from '@salesforce/label/c.lbl_template_placeholder';
import selectTemplateLabel from '@salesforce/label/c.lbl_template_selector_label';
import previewHeader from '@salesforce/label/c.lbl_confirm_position_creation';

import newRecordPreview from 'c/newRecordPreview';

export default class NewPositionForm extends LightningModal {
	isDuplication = false;
	_positionId;
	@api
	get positionId() { // filled if on record page, therefor we're duplicating a record
		return this._positionId;
	}
	set positionId(value) {
		if (value) {
			this._positionId = value;
			this.isDuplication = true;
		}
	}

	get showTemplatePicker() {
		console.log('duplication: ' + this.isDuplication);
		console.log('template: ' + this.isTemplate);
		return (!this.isDuplication && !this.isTemplate)
	}
	objectName = 'Position__c';
	recordTypeId;
	hiddenFields = ['Is_template_position__c', 'Status__c'];
	showTemplateSelector;
	loading;
	isConcept = false;
	rId;
	saveOnly;
	createdRecordId;

	labels = {
		newPosition : newPosition,
		addFiles : addFiles,
		cancel : cancelLabel,
		save : saveLabel,
		saveAndSubmit : saveAndSubmit,
		recordPickerPlaceholder: selectTemplate, 
		recordPickerName: selectTemplateLabel,
		previewHeader: previewHeader
	};

	@api label;
	_isTemplate = false;

	@api
	get isTemplate() {
		return this._isTemplate;
	}
	set isTemplate(value) {
		this._isTemplate = value;
		this.isActualPosition = !value;
	}
	@track fieldValues = {};

	filter = {
		criteria: [
			{
				fieldPath: 'Is_template_position__c',
				operator: 'eq',
				value: 'Template_position'
			}
		]
	}

	@wire(getObjectInfo, { objectApiName: 'Position__c' })
	wiredObjectInfo ({error, data}) {
		if (data) {
			console.log('Get recordtype');
			console.log(data);
			console.log(JSON.stringify(data));
			if (!this.recordTypeId) {
				console.log('Default recordtype: ' + data.defaultRecordTypeId);
				if (!this.isTemplate) {
					this.recordTypeId = data.defaultRecordTypeId;
				}
				else {
					getTemplateRecordTypeId({typeId: data.defaultRecordTypeId})
					.then((typeId) => {
						console.log(typeId);
						console.log('RECORD TYPE ID TEMPLATE');
						this.recordTypeId = typeId;
					})
				}
			}
		}
	}

	@wire(getRecord, { recordId: '$positionId'})
	wiredRecordToDuplicate({error, data}) {
		console.log('POS ID: ' + this.positionId);

		if (data) {
			console.log('GET RECORD');
			let tmp = JSON.parse(JSON.stringify(data));
			tmp.Id = ''; // we want to duplicate a record, not edit it, so we remove the id from field values
			this.fieldValues = tmp;
			console.log('RECORD: ' + JSON.stringify(tmp));
			// console.log('FILE UPLOAD' + JSON.stringify(this.template.querySelector('c-file-upload-component')));

			// if (this.template.querySelector('c-file-upload-component')) {
			// 	this.template.querySelector('c-file-upload-component').setFiles(this.positionId);
			// }
		}
	}

	handleCloseClick() {
		this.close({status: 'canceled', recordId: this.createdRecordId});
	}

	handleCancel() {
		this.close({status: 'canceled', recordId: this.createdRecordId});
	}

	handleTemplateSelect(event) {
		console.log('Template selected/deselected ' + JSON.stringify(event.detail.recordId));
		let templateId = event.detail.recordId;

		if (templateId) {
			getTemplate({templateId: templateId})
			.then(function(res) {
				res.Id = '';
				res.Is_template_position__c = 'Actual_position';
				res.Name = res.Name.replace(/(\s*[tT]emplate\s*)/, '');
				this.fieldValues = res;

				this.template.querySelector('c-file-upload-component').setFiles(templateId);
			}.bind(this))
			.catch((err) => {
				console.log('ERROR' + JSON.stringify(reduceErrors(this.error)));
			})
		}
		else {
			this.fieldValues = {};
		}
	}

	handleSave() {
		console.log('HANDLE SAVE');
		if (!this.template.querySelector('c-custom-record-form').reportValidity()) { // If still input errors, return
			return ;
		}

		this.lock();
		let tmp = {};

		if (this.saveOnly) {
			if (!this.isTemplate) { // Save as concept
				tmp['Is_template_position__c'] = 'Actual_position';
				tmp['Status__c'] = 'Concept';
				this.isConcept = true;
			}
			else { // Save template
				tmp['Is_template_position__c'] = 'Template_position';
				tmp['Status__c'] = 'New';
				this.isConcept = false;
			}
		}
		else {
			tmp['Is_template_position__c'] = 'Actual_position';
			tmp['Status__c'] = 'New';
			this.isConcept = false;
		}
		this.fieldValues = tmp;

		console.log('SAVE ONLY ' + this.saveOnly);
		console.log('IS VALID ' + this.template.querySelector('c-custom-record-form').reportValidity());


		this.template.querySelector('c-custom-record-form').clickSubmit();
	}

	handleSaveOnly(event) {
		console.log("Handle save concept");
		this.saveOnly = true;
		this.handleSave();
	}

	handleSaveSubmit(event) {
		console.log("Handle save submit");
		this.saveOnly = false;
		this.handleSave();
	}

	release() {
		this.loading = false;
		this.disableClose = false;
	}

	lock() {
		this.loading = true;
		this.disableClose = true;
	}

	handleRecordSubmitted(event) {
		console.log('Handle submitted' + JSON.stringify(event.detail));
		this.createdRecordId = event.detail.recordId;

		// Does client side field validation, if successful, shows preview popup for save & submit flow
		if (!this.saveOnly & !this.isTemplate) {
			newRecordPreview.open({
				label: this.labels.previewHeader,
				objectName: this.objectName,
				recordTypeId: this.recordTypeId,
				recordId: this.createdRecordId,
				size: "large"
			})
			.then ((res) => {
				console.log(JSON.stringify(res));
				if (res.status == 'confirmed') {
					this.template.querySelector('c-file-upload-component').upload(this.createdRecordId)
					.then(() => {
						console.log('Files uploaded');
						this.release();
						this.close({status: 'success', submit: !this.isConcept, recordId: this.createdRecordId});
					})
					.catch((err) => {
						console.log('ERROR: ' + JSON.stringify(err));
						this.release();
					})
				}
				else {
					console.log('Canceled');
					this.release();
				}
			})
			.catch((err) => {
				console.log('ERROR ' + JSON.stringify(err));
				this.release();
			})
		}
		else { // saving as concept we skip confirm step
			this.template.querySelector('c-file-upload-component').upload(this.createdRecordId)
			.then(() => {
				console.log('Files uploaded');
				this.release();
				this.close({status: 'success', submit: !this.isConcept, recordId: this.createdRecordId});
			})
			.catch((err) => {
				console.log('ERROR: ' + JSON.stringify(err));
				this.release();
			})
		}
	}

	handleRecordSubmitError(event) {
		this.release();
	}
}