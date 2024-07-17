import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';

export default class IconCarousel extends LightningElement {
    /* Shows picklist as button carrousel (switch on click)
        Every item is: { icon: '', value: ''}

        In collection: 
        typeAttributes {
            icons: [
                { icon: '', value: ''},
                { icon: '', value: ''}
            }], 
            values: { fieldName: picklistValues }
        }
    */
    @api items
    @api fieldName;
    @api recordId;
    @api editable;
    item;
    itemIndex;
    _value;
    @api
    set value (val) {
        this._value = val;
        if (this.items) {
            this.updateView();
        }
    }
    get value() {
        return this._value;
    }

    updateView() {
        
        for (let i = 0; i < this.items.length; i++) {
            let item = this.items[i];
            if (item.value === this.value) {
                this.item = item;
                this.itemIndex = i;
                break;
            }
        }
    }

    connectedCallback() {
        loadStyle(this, FontAwesome6 + '/css/all.min.css')
            .then(() => {
                this.updateView();
            })
            .catch((error) => {
                console.log('ERROR' + error);
            })   
    };

    renderedCallback() {
        if (!this.editable && this.refs.icon) {
            this.refs.icon.classList.add('view-only');
        }
    }

    handleClick(event) {
        if (!this.editable)
            return ;
        if (this.itemIndex === this.items.length - 1) {
            this.itemIndex = 0;
        }
        else {
            this.itemIndex += 1;
        }

        this.item = this.items[this.itemIndex];
        this.value = this.item.value;
        const evt = new CustomEvent('rowaction', { 
            composed: true,
            bubbles: true,
            detail: {
                action: { name: 'comboboxchanged' },
                'recordId': this.recordId,
                'value': this.value,
                'fieldName': this.fieldName
        }});

        this.dispatchEvent(evt);
    }
}