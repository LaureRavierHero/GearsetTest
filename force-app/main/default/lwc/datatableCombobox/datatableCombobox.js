import { LightningElement, api, track } from 'lwc';

export default class DatatableComboBox extends LightningElement {
    // @api label;
    @api locked;
    @api editable;
    @api fieldName;
    @api placeholder; // Select ...
    _options;
    @api
    get options() {
        return this._options;
    }
    set options(values) {
        let res = [];
        for (var val of values) {
            res.push({
                'value': val.itemName,
                'label': val.itemLabel
            });
        }
        this._options = [...res];
    }
    item;
    key;
    _label;
    value;
    @api
    get label() {
        return this._label;
    }
    set label(val) {
        this._label = val;
        if (this.options) {
            this.updateView();
        }
    }

    updateView() {
        for (var item of this.options) {
            if (this.label == item.label) {
                this.value = item.value;
                break;
            }
            else {
                this.value = undefined;
            }
        }
    }

    connectedCallback() {
        this.updateView();
    }
    @api recordId;

    handleChange(event) {
        this.value = event.detail.value;

        let evt = new CustomEvent('rowaction', { 
			composed: true,
            bubbles: true,
            // target: {
            //     fieldName: this.columnName
            // },
			detail: {
				action: { name: 'comboboxchanged' },
				'recordId': this.recordId,
                'value': this.value,
                fieldName: this.fieldName
		}});

        this.dispatchEvent(evt);
    }
}