import { LightningElement, api } from 'lwc';
import richTextEditorModal from 'c/richTextEditorModal';

export default class DatatableTextInput extends LightningElement {
	@api value;
	@api fieldName;
	@api recordId;
	@api editable = false;
	@api isRichText;
	@api isFullView;

	editMode = false;
	draftValue;
	saveInProgress;

	renderedCallback() {
		// Set classes on rich text fields (either fully expanded or with line-clamp)
		if (this.isFullView) {
			Array.from(this.template.querySelectorAll('lightning-formatted-rich-text')).forEach((elem) => {
				console.log('elem: ' + elem);
				elem.classList.remove('slds-line-clamp');
				elem.classList.add('wrap-text-full-view');
			});
			Array.from(this.template.querySelectorAll('lightning-formatted-text')).forEach((elem) => {
				console.log('elem: ' + elem);
				elem.classList.remove('slds-line-clamp');
				elem.classList.add('wrap-text-full-view');
			});
		}
	}

	handleStartEdit(event) {
		this.editMode = true;
		setTimeout(() => {
			this.template.querySelector('input').focus();
		});
	}

	async handleStartModalEdit() {
		const newVal = await richTextEditorModal.open({
			size: 'medium',
			value: this.value
		})
		// If newVal is null, user clicked cancel
		if (newVal != null) {
			this.value = newVal;
			let evt = new CustomEvent('rowaction', {
				composed: true,
				bubbles: true,
				detail: {
					action: { name: 'textchanged' },
					'recordId': this.recordId,
					'value': this.value,
					'fieldName': this.fieldName
				}
			});

			this.dispatchEvent(evt);
		}
	}

	handleClickInProgress(event) {
		this.saveInProgress = true;
	}

	handleSave(event) {
		let newVal = this.template.querySelector('input').value;
		this.value = newVal;
		this.saveInProgress = false;
		this.editMode = false;

		let evt = new CustomEvent('rowaction', {
			composed: true,
            bubbles: true,
			detail: {
				action: { name: 'textchanged' },
				'recordId': this.recordId,
				'value': this.value,
				'fieldName': this.fieldName
			}
		})

		this.dispatchEvent(evt);
	}

	handleBlur(event) {
		if (!this.saveInProgress)
			this.editMode = false;
	}
}