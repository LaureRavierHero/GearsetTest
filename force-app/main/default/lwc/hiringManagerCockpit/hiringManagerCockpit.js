import { LightningElement, api, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';

// Import message service features required for subscribing and the message channel
import {
	subscribe,
	unsubscribe,
	APPLICATION_SCOPE,
	MessageContext,
  } from "lightning/messageService";
import REFRESH_CHANNEL from "@salesforce/messageChannel/refreshMessageChannel__c";

import getSettings from '@salesforce/apex/WorkcomponentApplicationsController.getSettings';
import getData from '@salesforce/apex/WorkcomponentApplicationsController.getData';
import updateRecords from '@salesforce/apex/WorkcomponentApplicationsController.updateRecords';
import sectionTitle from '@salesforce/label/c.LBL_hiring_desk_cockpit_title';
import checkVisibility from '@salesforce/apex/WorkcomponentApplicationsController.showHiringManagerCockpit';

const componentName = 'Standard hiring manager workcomponent';

export default class HiringManagerCockpit extends LightningElement {
	loading = true;
	title = sectionTitle;
	@track error;
	@api recordId;

	configuration;
	idColumn;
	columns;
	configurationJson = '';
	provisionedData;
	isVisible = false;
	@track data;

	filters;
	filterInfo=[];

	@track filteredData;
	@track paginatedData;

	draftValues = []; // For handling of inline editing
	
	sortBy='';
	sortDirection='asc';

	hasPagination = false;

	@wire(MessageContext)
	messageContext;

	// Encapsulate logic for Lightning message service subscribe and unsubsubscribe
	subscribeToMessageChannel() {
		if (!this.subscription) {
		this.subscription = subscribe(
			this.messageContext,
			REFRESH_CHANNEL,
			(message) => this.handleMessage(message),
			{ scope: APPLICATION_SCOPE },
		);
		}
	}

	unsubscribeToMessageChannel() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}

	// Handler for message received by component
	handleMessage(message) {
		console.log('REFRESH HIRING MANAGER COMPONENT');
		return refreshApex(this.provisionedData);
	}

	// Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
	connectedCallback() {
		this.subscribeToMessageChannel();
	}

	disconnectedCallback() {
		this.unsubscribeToMessageChannel();
	}

	@wire(checkVisibility, {positionId: '$recordId'})
	wiredIsVisible({data, error}) {
		if (data) {
			console.log('DATA CHECK VIS ' + JSON.stringify(data));
			this.isVisible = data;
		}
		else if (error) {
			console.log('ERROR ' + JSON.stringify(error));
		}
	}

	@wire(getSettings, { componentName: componentName })
	wiredSettings({data, error}) {
		this.loading = true;
		if (data) {
			this.configuration = data;
			console.log('Configuration:');
			console.log(JSON.stringify(this.configuration));
			this.configurationJson = JSON.stringify(this.configuration);
			this.hasPagination = this.configuration.showPagination;
			this.columns = this.configuration.columns;
			// console.log('COLUMNS: ');
			// console.log(JSON.stringify(this.columns));
			this.filters = this.configuration.filters;
			this.idColumn = this.configuration.idColumn;
			this.loading = false;
		}
		else if (error) {
			this.error = error;
			this.loading = false;
		}
	}

	@wire(getData, {componentConfigurationJson: '$configurationJson', sortCol: '$sortBy', sortOrder: '$sortDirection',
	recordId: '$recordId'})
	wiredData(result) {
		// console.log('DATA PROVISIONED: ' + JSON.stringify(result));

		this.loading = true;
		this.provisionedData = result;
		
		const {data, error} = result;
		if (data) {
			this.data = data;
			console.log('DATA');
			console.log(JSON.stringify(this.data));
			this.filteredData = [...this.data];
			this.paginatedData = [...this.filteredData];
			this.draftValues = [];
			this.updateFiltering();
			this.loading = false;
			this.error = undefined;
		}
		else if (error) {
			this.error = error;
			this.loading = false;
			this.data = undefined;
			this.filteredData = undefined;
			this.paginatedData = undefined;
		}
	}

	// renderedCallback() {
	// 	// console.log('SUBSCRIBE');
    //     if (!this.subscribed) {
    //         this.handleSubscribe();
    //         this.subscribed = true;
    //     }
    // }
	/* Filtering */
	updateFiltering() {
		// console.log('UPDATE FILTERING');
		console.log(JSON.stringify(this.filterInfo));
		this.filteredData = this.data.filter((currElement) => {
			for (const item of this.filterInfo) {
				let colName = item.name;
				
				if (item.values.length > 0 && !item.values.includes(currElement[colName])) {
					return false;
				}
			}
			return true;
		});
		if (this.hasPagination == false) {
			this.paginatedData = [...this.filteredData];
		}
	}

	handleFilters(event) {
		this.filterInfo = event.detail;

		this.updateFiltering();	
	}

	/* Pagination */
	handlePagination(event) {
		this.paginatedData = event.detail.records;
	}

	/* Update values */
	async updateValues(draftValues) {
		try {
			await updateRecords({ recordsJson: JSON.stringify(draftValues)});
		} catch (error) {
			this.error = error;
		}
	}

	/* Inline editing */
	async handleSave(event) {
		this.loading = true;
		this.draftValues = event.detail.draftValues;
		
		this.updateValues(this.draftValues);
	}

	/* SORTING */
	handleSorting(event) {
		/* Some columns are sorted by virtue of other columns, we need to make 
		sure we pass the right column name to apex */
		this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

		// console.log('sort by: ' +  this.sortBy + 'sort dir: ' + this.sortDirection);
		// return refreshApex(this.provisionedData);
	}

	/* ROW ACTIONS */
	getDraftValueInList(recordId, value, columnName) {
		let draftValues = [];
		let draftValue = {};

		draftValue[this.idColumn] = recordId;
		draftValue[columnName] = value.toString();

		draftValues.push(draftValue);

		return draftValues;
	}

	handleRowAction(event){

        const actionName = event.detail.action.name;
        const row = event.detail.row;
		console.log('HANDLE ROWACTION ' + actionName);
		// if(actionName === 'starclicked') {
			let recordId = event.detail.recordId;
			let value = event.detail.value;
			let columnName = event.detail.fieldName;
			let draftValues = this.getDraftValueInList(recordId, value, columnName);
			console.log('DRAFT VALUES: ' + JSON.stringify(draftValues));

			this.updateValues(draftValues);
		// }
		// else {
		// 	let recordId = event.detail.recordId;
		// 	let value = event.detail.value;
		// 	let columnName = event.detail.fieldName;
		// 	let draftValues = this.getDraftValueInList(recordId, value, columnName);
		// 	this.updateValues(draftValues);
		// }
    }
}