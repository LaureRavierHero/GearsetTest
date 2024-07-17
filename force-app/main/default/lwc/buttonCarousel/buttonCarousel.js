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
    @api items;
    @api columnName;
    @api recordId;
    item;
    itemIndex;
    _value;
    @api value

    connectedCallback() {
        loadStyle(this, FontAwesome6 + '/css/all.min.css')
			.then(() => {});
        this.iconByValue = [
            {label: 'Yes', icon: 'fa-solid fa-circle-check fa-xl'},
            {icon: 'No', icon: 'fa-solid fa-circle-xmark fa-xl'},
            {icon: 'Open', icon: 'fa-solid fa-square fa-xl'}
        ];
        this.item = this.iconByValue[0];
        this.itemIndex = 0;        
    };

    handleClick(event) {
        if (this.itemIndex === this.iconByValue.length - 1) {
            this.itemIndex = 0;
        }
        else {
            this.itemIndex += 1;
        }

        this.item = this.iconByValue[this.itemIndex];
    }

}