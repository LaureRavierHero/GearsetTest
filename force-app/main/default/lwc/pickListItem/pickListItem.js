import { LightningElement, api } from 'lwc';

export default class PickListItem extends LightningElement {
    _value;
    @api get value() {
        return this._value;
    }
    set value(val) {
        console.log('PICKLIST VALUE' + val);

        this._value = val;
    }
    @api label;
    @api selected;

    displayCheckBox = false;
    displayStarRating = false;

    _displayType;
    @api get displayType() {
        return this._displayType;
    }
    set displayType(value) {
        if (value == 'checkBox')
            this.displayCheckBox = true;
        if (value == 'starRating')
            this.displayStarRating = true;
    }



    constructor () {
        super();
    }
    
    get itemClass () {
        return 'slds-listbox__item ms-list-item' + (this.selected ? ' slds-is-selected' : '');
    }

    onItemSelected (event) {
        const evt = new CustomEvent ('itemselected', { detail : {'value' : this.value, 'selected': !this.selected }});

        this.dispatchEvent (evt);
        event.stopPropagation();
    }
}