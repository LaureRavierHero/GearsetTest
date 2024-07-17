import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import buttonCancel from '@salesforce/label/c.Button_label_cancel';
import buttonSave from '@salesforce/label/c.lbl_button_label_save';
import editClarification from '@salesforce/label/c.lbl_clarification_edit_modal_header';

const labels = {
    save: buttonSave,
    cancel: buttonCancel,
    title: editClarification
}

export default class richTextEditorModal extends LightningModal {
    @api value;
    @api title;
    labels = labels;

	handleCloseClick() {
		this.close(null);
	}

    handleSaveClick() {
		this.value = this.template.querySelector('lightning-input-rich-text').value;
        this.close(this.value);
    }
}