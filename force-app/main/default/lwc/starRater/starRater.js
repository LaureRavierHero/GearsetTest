import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';

export default class StarRater extends LightningElement {
	@api fieldName;
	@api recordId;
	@track stars = [];
	_ratingValue;
	@api get ratingValue() {
		return this._ratingValue;
	}
	set ratingValue(val) {
		this._ratingValue = val;
		this.initializeStars();
	}

	hoverValue = 0;
	@api editable;

	connectedCallback() {
		loadStyle(this, FontAwesome6 + '/css/all.min.css')
			.then(() => {
				this.initializeStars();
			})
			.catch(error => {
				console.error('Error loading FontAwesome:', error);
			});
		console.log('EDITABLE STAR: ' + this.editable);
	}

	initializeStars() {
		this.stars = Array.from({ length: 5 }, (_, i) => ({
			value: i + 1,
			class: `fa fa-star ${this.ratingValue >= i + 1 ? 'star-yellow' : ''} ${this.ratingValue >= i + 1 && this.editable == false ? 'view-only' : ''}`,
			key: i
		}));
	}

	updateStarClasses(state) {
		// Update the class of each star based on the current ratingValue and hoverValue.
		this.stars = this.stars.map(star => ({
			...star,
			class: this.getStarClass(star.value, state)
		}));
	}

	getStarClass(starValue, state) {
		if(state == 'hover'){
			return `fa fa-star ${this.hoverValue >= starValue ? 'star-yellow' : ''}`;
		}else{
			return `fa fa-star ${this.ratingValue >= starValue ? 'star-yellow' : ''}`;
		}
	}

	handleMouseover(event) {
		if (!this.editable) return;
		
		const starValue = parseInt(event.target.dataset.starValue, 10);
		this.hoverValue = starValue;
		this.updateStarClasses('hover');
	}

	handleStarClick(event) {
		if (!this.editable) return;
		
		const starValue = parseInt(event.target.dataset.starValue, 10);

		if(starValue == this.ratingValue){
			this.ratingValue = 0;
			this.initializeStars();
		}else{
			this.ratingValue = starValue;
			this.updateStarClasses('click');
		}

		const evt = new CustomEvent('rowaction', { 
			composed: true,
            bubbles: true,
			detail: {
				action: { name: 'starclicked' },
				fieldName: this.fieldName,
				'recordId': this.recordId,
				'value': this.ratingValue
		}});
		this.dispatchEvent(evt);
	}
	
	handleMouseout() {
		if (!this.editable) return;
		
		if (this.ratingValue === 0) {
			this.initializeStars();
		}else{
			this.updateStarClasses('click');
		}
	}
}