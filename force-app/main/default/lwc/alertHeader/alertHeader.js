import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';

export default class AlertHeader extends LightningElement {
    @api text;
    
    connectedCallback() {
        loadStyle(this, FontAwesome6 + '/css/all.min.css')
			.catch(error => {
				console.error('Error loading FontAwesome:', error);
			});
	}

    closeAlert() {
        const evt = new CustomEvent ('closedalertheader');
        this.dispatchEvent(evt);
	}
}