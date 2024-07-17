import { LightningElement, api } from 'lwc';

export default class CustomRelatedList extends LightningElement {
	@api title;
	@api iconName;
	@api iconClass;
	@api count;
}