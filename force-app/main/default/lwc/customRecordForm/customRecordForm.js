import { LightningElement, wire, track, api } from 'lwc';
import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
import getFieldType from '@salesforce/apex/SchemaUtils.getFieldType';

export default class CustomRecordForm extends LightningElement {
	/* All this api stuff is just to ensure that IF a recordtypeid is provided,
	it is set AFTER the objectname is know to trigger the wires correctly */
	@api recordId;
	@track layout;
	@api readOnly = false;
	_objectName;
	@api 
	get objectName() {
		return this._objectName;
	}
	set objectName(value) {
		this._objectName = value;
		if (this._tmpRid) {
			this.recordTypeId = this._tmpRid;
		}
	}
	
	_recordTypeId;
	_tmpRid;
	@api 
	get recordTypeId() {
		return this._recordTypeId;
	}
	set recordTypeId(value) {
		if (this.objectName) {
			this._recordTypeId = value;
		}
		else {
			this._tmpRid = value;
		}
	}
	@api layoutType = 'Full'; // Compact or Full

	_hideFields = []; // Fields that ARE on the layout but should be removed (automatically set required values)
	@api 
	get hideFields() {
		return this._hideFields;
	}
	set hideFields(value) {
		console.log('before set hide fields');
		this._hideFields = value;
		this.hiddenFields = value;
		console.log('after set hide fields');
	}

	_hiddenFields = []; // Fields that are NOT in the layout but need to be submitted (have to be filled through fieldValues)
	@api 
	get hiddenFields() {
		return this._hiddenFields;
	}
	set hiddenFields(value) {
		console.log('before set hidden fields');
		this._hiddenFields = [...this._hiddenFields, ...value];
		console.log('after set hidden fields' + JSON.stringify(this._hiddenFields));
	}
	_fieldValues;
	wireArguments = { objectApiName: 'Account'};

	/* Set values automatically on the form */
	@api
	get fieldValues() {
		return this._fieldValues;
	}
	set fieldValues(value) {
		this._fieldValues = value;
		console.log('before set field values');
		if (this.template.querySelectorAll('lightning-input-field')) {
			this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
				if(this.fieldValues[elem.fieldName]){
					if (value[elem.fieldName]) {
						elem.value = value[elem.fieldName];
					}
				}
			});
		}
		console.log('after set field values');
	}

	connectedCallback() {
		console.log('CONNECTED CUSTOM RECORD FORM');
		console.log('Record type id ' + this.recordTypeId);
		console.log('Object name ' + this.objectName);
	}

	@api reportValidity() {
		let valid = true;
		this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
			if (!elem.reportValidity()) {
				valid = false;
			}
		});

		return valid;
	}

	@api getFields() {
		let fields = {};

		this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
			fields[elem.fieldName] = elem.value;
		});

		return fields;
	}

	/* Filter hideFields from layout, they are added as hidden fields (see above) */
	prepLayout(data) {
		data.layout.sections.forEach((section) => {
			section.numcols = 12 / section.columns;
			section.layoutRows.forEach((row) => {
				row.layoutItems.forEach((layoutItem) => {
					try {    
					 	layoutItem.layoutComponents = 
							layoutItem.layoutComponents.filter((layoutComponent) => !this.hideFields.includes(layoutComponent.apiName));
					}
					catch (err) {
						console.log('EROOR' + JSON.stringify(err));
					}
				})
			})
		});
		return data.layout;
	}

	@wire (getRecordCreateDefaults, { objectApiName: '$objectName', recordTypeId: '$recordTypeId' })
	wiredDefaultsRecordTypeId(res) {
		const {error, data} = res;
		console.log('joehoe 1' + JSON.stringify(res));
		if (data) {
			console.log('record create default with objname and recordtype id data');
			if (this.objectName && this.recordTypeId) {
				try {
					this.activeSections = data.layout.sections.map(elem => elem.id);
					this.layout = this.prepLayout(JSON.parse(JSON.stringify(data)));
					console.log('Layout set');
				}
				catch (err) {
					console.log('ERROR' + JSON.stringify(err));
				}
			}
		}
		else if (error) {
			console.log('Error' + JSON.stringif(error));
		}
	}

	@wire (getRecordCreateDefaults, { objectApiName: '$objectName' })
	wiredDefaults({error, data}) {
		console.log('joehoe 2');
		if (data) {
			console.log('record create default with objname data');
			if (this.objectName && !this.recordTypeId) {
				try {
					this.activeSections = data.layout.sections.map(elem => elem.id);
					this.layout = this.prepLayout(JSON.parse(JSON.stringify(data)));
					console.log('Layout set');
				}
				catch (err) {
					console.log('ERROR' + JSON.stringify(err));
				}
			}
		}
		else if (error) {
			console.log('Error' + JSON.stringif(error));
		}
	}

	renderedCallback() {
		console.log('Before render');
		// this.activeSections = this.layout.sections.map(elem => elem.id);
		if (this._fieldValues) {
			this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
				if(this._fieldValues[elem.fieldName]){
					elem.value = this._fieldValues[elem.fieldName];
				}
			});
		}
		console.log('After render');
	}

	handleError(event) {
		console.log('Could not submit error' + JSON.stringify(event.detail));
		this.dispatchEvent(new CustomEvent('recordsubmiterror'));
	}

	handleSuccess(event) {
		console.log('Submitted');
		this.dispatchEvent(new CustomEvent('recordcreated', { detail: {recordId: event.detail.id}}));
	}

	handleClickSave(event) {
		console.log('Handle click save');
		console.log('VALUES' + JSON.stringify(this.fieldValues));
		this.template.querySelectorAll('lightning-accordion-section').forEach((elem) => {
			elem.classList.remove('accordion-has-error');
		});

		this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
			console.log('FIELD ' + elem.fieldName + ' ' + elem.value);
			if (elem.reportValidity() === false) {
				elem.closest('lightning-accordion-section').classList.add('accordion-has-error');
			}
		});
	}

	handleSubmit(event) {
		console.log('SUBMIT:\n' + JSON.stringify(event.detail.fields));
	}

	@api
	clear() {
		this.template.querySelectorAll('lightning-input-field').forEach((elem) => {
			elem.reset();
		});
	}

	@api
	clickSubmit() {
		// This is a little hacky, but we do not get server side validation errors if we don't submit the 
		// form with a button click
		this.template.querySelector('.hidden-button').click();
	}
}