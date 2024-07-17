import { LightningElement, api, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import { subscribe, MessageContext, publish } from 'lightning/messageService';
import REFRESH_CHANNEL from "@salesforce/messageChannel/refreshMessageChannel__c";
import getSettings from '@salesforce/apex/WorkcomponentApplicationsController.getSettings';
import getData from '@salesforce/apex/WorkcomponentApplicationsController.getData';
import updateRecords from '@salesforce/apex/WorkcomponentApplicationsController.updateRecords';
import sectionTitle from '@salesforce/label/c.LBL_hiring_desk_cockpit_title';
import {
	registerRefreshContainer,
	unregisterRefreshContainer,
} from "lightning/refresh";
  

const componentName = 'Standard hiring desk workcomponent';

export default class HiringDeskCockpit extends LightningElement {
	loading = true;
	title = sectionTitle;
	@track error;
	@api recordId;

	configuration;
	idColumn;
	columns;
	configurationJson = '';
	provisionedData;
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
    
    subscribeToMessageChannel() {
        this.subscription = subscribe(
        this.messageContext,
        REFRESH_CHANNEL,
        (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        console.log('HANDLE REFRESH');
        return refreshApex(this.provisionedData);
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        console.log('REGISTER REFRESH CONTAINER');
		this.refreshContainerID = registerRefreshContainer(
		  this.template.host,
		  this.refreshContainer.bind(this),
		);
    }

    disconnectedCallback() {
      unregisterRefreshContainer(this.refreshContainerID);
      }
  
      refreshContainer(refreshPromise) {
        console.log("REFRESHING APPLICATION\n\n");
        return refreshPromise.then((status) => {
            // publish(this.messageContext, REFRESH_CHANNEL, {});
			return refreshApex(this.provisionedData);
          });
      }

	@wire(getSettings, { componentName: componentName })
	wiredSettings({data, error}) {
		this.loading = true;
		if (data) {
			this.configuration = data;
			// console.log('Configuration:');
			// console.log(JSON.stringify(this.configuration));
			this.configurationJson = JSON.stringify(this.configuration);
			this.hasPagination = this.configuration.showPagination;
			this.columns = this.configuration.columns;
			// console.log('COLUMNS: ');
			// console.log(JSON.stringify(this.columns));
			this.filters = this.configuration.filters;
			console.log('FILTERS ' + JSON.stringify(this.configuration.filters));
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

	/* Filtering */
	updateFiltering() {
		console.log('UPDATE FILTERING');
		console.log(JSON.stringify(this.filterInfo));
		this.filteredData = this.data.filter((currElement) => {
			for (const item of this.filterInfo) {
				let colName = item.name;
				console.log('item name ' + colName);
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
	updateValues(draftValues) {
		updateRecords({ recordsJson: draftValues}) //JSON.stringify(draftValues)
		.then((result) => {
			return refreshApex(this.provisionedData);
		})
		.catch ((error) => {
			console.log('Could not refresh view!');
		})
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
		let recordId = event.detail.recordId;
		let value = event.detail.value;
		let columnName = event.detail.fieldName;
		let draftValues = this.getDraftValueInList(recordId, value, columnName);
		console.log('DRAFT VALUES: ' + JSON.stringify(draftValues));

		this.updateValues(JSON.stringify(draftValues));
    }
}