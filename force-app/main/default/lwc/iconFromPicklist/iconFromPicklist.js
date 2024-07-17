import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';

export default class IconFromPicklist extends LightningElement {
    @api items
    @api fieldName;
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
}