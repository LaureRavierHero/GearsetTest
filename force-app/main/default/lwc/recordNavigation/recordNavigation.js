import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

/*
    Component creates link to a record. If you specify only a label, it will show just a <a> tag with an href set. 
    If you specify only an icon, it will render an icon-button. If you specify both, it wil render a lightning-button 
    with both icon and label set.
*/
export default class RecordNavigation extends NavigationMixin(LightningElement) {
    @api label;
    @api recordId;
    @api objectApiName;
    @api iconName;
    _labelVisible = false;
    _iconVisible = false;
    _labelAndIconVisible = false;

    pageRef = null;

    connectedCallback() {
        if (this.label)
            this._labelVisible = true;
        if (this.iconName)
            this._iconVisible = true;
        if (this._labelVisible && this._iconVisible)
            this._labelAndIconVisible = true;
    }

    renderedCallback() {
        this.pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        }
    }

    navigateToRecordView(event) {
        event.preventDefault();
        event.stopPropagation();
        this[NavigationMixin.Navigate](this.pageRef);
    } 
}