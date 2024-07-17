import { LightningElement, api } from 'lwc';

export default class CustomPageSection extends LightningElement {
	visible = true;
	@api title;

	handleClick() {
		this.visible = !this.visible;
		if (this.visible) {
			this.refs.outerContainer.classList.add('slds-is-open');
			this.refs.body.style.display = "block";
		}
		else {
			this.refs.outerContainer.classList.remove('slds-is-open');
			this.refs.body.style.display = "none";
		}
	}
}