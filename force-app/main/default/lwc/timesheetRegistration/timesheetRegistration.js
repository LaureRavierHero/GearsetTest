import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { loadStyle } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/timesheetRegistrationStyling';
import FontAwesome6 from '@salesforce/resourceUrl/FontAwesome6';
import ExpenseModal from './expenseModal';
import TIMESHEET_ENTRY_OBJECT from "@salesforce/schema/Timesheet_entry__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { generateUrl } from "lightning/fileDownload";
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

// Apex
import getData from '@salesforce/apex/TimesheetRegistrationController.getData'
import saveTimesheetEntries from '@salesforce/apex/TimesheetRegistrationController.saveTimesheetEntries';
// import submitForApproval from '@salesforce/apex/TimesheetRegistrationController.submitForApproval';
// import reopen from '@salesforce/apex/TimesheetRegistrationController.reopen';

// Labels
import timeRegistration from '@salesforce/label/c.lbl_Time_Registration';
import date from '@salesforce/label/c.lbl_Date';
import hours from '@salesforce/label/c.lbl_hours';
import minutes from '@salesforce/label/c.lbl_Minutes';
import ratePercentage from '@salesforce/label/c.lbl_Rate_Percentage';
import comment from '@salesforce/label/c.lbl_Comment';
import selectAnOption from '@salesforce/label/c.lbl_Select_An_Option';
import save from '@salesforce/label/c.lbl_save';
import newExpense from '@salesforce/label/c.lbl_New_expense';
import travelExpenses from '@salesforce/label/c.lbl_Travel_expenses';
import amount from '@salesforce/label/c.lbl_Amount';
import attachment from '@salesforce/label/c.lbl_Attachment';
import typeLabel from '@salesforce/label/c.lbl_Type';
import exportToPDF from '@salesforce/label/c.lbl_Export_to_PDF';

export default class TimesheetRegistration extends NavigationMixin(LightningElement) {
	@api recordId;
	@track entries = [];
	@track originalTimesheetEntries = [];
	@track ratePercentages;
	@track disabled = true;
	@track loading = false;

	// ratePercentagesNamesById = new Map();
	ratePercentageOptions = [];
	updatedIds = [];
	removedIds = [];
	// toggledDays = [];
	travelCostEnabled;
	locked;
	expensesDisabled;
	reopenPossible;
	exportPossible = false;

	timesheetId;
	minDate;
	maxDate;
	defaultRecordTypeId;

	labels = {
		timeRegistration : timeRegistration,
		date : date,
		hours : hours,
		minutes : minutes,
		ratePercentage : ratePercentage,
		comment : comment,
		selectAnOption : selectAnOption,
		save : save,
		newExpense: newExpense,
		travelExpenses: travelExpenses,
		amount: amount,
		attachment: attachment,
		typeLabel: typeLabel,
		exportToPDF: exportToPDF
	};

	@wire(getData, {recordId: '$recordId'}) getData(result) {
		this.refreshView = result;
		this.loading = true;

		// console.log('result.data');
		// console.log(JSON.stringify(result, null, 2));

		if (result.data) {
			const data = result.data;
			// this.user = data.u;
			this.timesheetId = data.timesheetId;
			this.ratePercentages = data.ratePercentages;
			this.travelCostEnabled = data.travelCostEnabled;
			this.locked = data.locked;
			this.expensesDisabled = data.expensesDisabled;
			this.reopenPossible = data.reopenPossible;
			this.exportPossible = data.exportPossible;

			this.originalTimesheetEntries = data.entries;
			this.entries = JSON.parse(JSON.stringify(data.entries));

			const dates = this.entries
				.filter(obj => obj.day !== null) // Filter out entries where day is not null
				.map(obj => new Date(obj.day).getTime()); // Map to dates and convert to milliseconds

			// Finding the lowest and highest dates
			const minDate = new Date(Math.min(...dates));
			const maxDate = new Date(Math.max(...dates));
			
			// OPTIMIZE BE CAREFUL with this method as it first converts to the date to UTC
			// OPTIMIZE If you are in a + timezone and your time portion is early in the day, then it could roll-back a day
			// OPTIMIZE Alternatively, if you're in a - timezone and your time portion is late in the day, then it could roll forward a day
			// TODO https://stackoverflow.com/questions/23593052/format-javascript-date-as-yyyy-mm-dd
			this.minDate = minDate.toISOString().split('T')[0];
			this.maxDate = maxDate.toISOString().split('T')[0];

			// OPTIMIZE maybe do a check if the option exists before adding it
			// OPTIMIZE instead of clearing it and refilling it as a hotfix
			this.ratePercentageOptions = [];
			
			data.ratePercentages.forEach(element => {
				this.ratePercentageOptions.push({
					label:element.Name,
					value:element.Rate_percentage__c
				});
			});
			
			this.loading = false;
		} else if (result.error) {
			const error = result.error;
			console.log('testfail');
			console.log(error);
			this.loading = false;
		}
	}

	// OPTIMIZE maybe not in a wire but in constructor
	@wire(getObjectInfo, { objectApiName: TIMESHEET_ENTRY_OBJECT }) wireTimesheetEntryData(objectInfo, error){
		if(objectInfo){
			let recordTypeInfo = objectInfo?.data?.recordTypeInfos;

			if(recordTypeInfo){
				this.defaultRecordTypeId = Object.keys(recordTypeInfo).find(rtype=>(recordTypeInfo[rtype].name === 'Default'));
			}
		}
	}

	navigateToFile(event) {
		window.open(generateUrl(event.target.dataset.contentversionid));
	}

	handleTravelExpenseChange(event){
		const checked = event.target.checked;
		const day = event.target.dataset.day;

		const dayIndex = this.entries.findIndex(item => item.day === day);
		
		if (dayIndex !== -1) {
			this.entries[dayIndex].travelExpenses = checked;
			this.disabled = false;
		}
	}
	
	handleChange(event){
		const day = event.target.dataset.day;
		const value = event.detail.value;
		const recordId = event.target.dataset.recordid;
		const fieldName = event.target.dataset.fieldname;
		const index = event.target.dataset.index;
		const recordtype = event.target.dataset.recordtype;
		
		const dayIndex = this.entries.findIndex(item => item.day === day);

		// console.log('day index');
		// console.log(dayIndex);

		if (dayIndex !== -1) {
			const entry = this.entries[dayIndex][recordtype][index];
			const entryIndex = this.entries[dayIndex][recordtype].indexOf(entry);
			
			if (entryIndex !== -1) {
				// console.log('entryIndex found');
				this.entries[dayIndex][recordtype][entryIndex][fieldName] = value;
				// console.log('this.entries updated');

				if(!this.updatedIds.includes(recordId)){
					this.updatedIds.push(recordId);
					// console.log('this.updatedIds updated');
				}
			}

			// console.log('this.entries');
			// console.log(JSON.stringify(this.entries, null, 2));
			// console.log('this.updatedIds');
			// console.log(JSON.stringify(this.updatedIds));
		}

		this.disabled = false;
	}

	addRow(event) {
		const day = event.target.dataset.day;

		const newEntry = {
			"Id": null,
			"Timesheet__c": this.timesheetId,
			"Date__c": day,
			"Comment__c": null,
			"RecordTypeId": this.defaultRecordTypeId,
			"Is_record_type_default__c": true
		};

		// const obj = this.entries.find(item => item.day === day);

		// if (obj) {
		// 	obj.entries.push(newEntry);
		// }

		const dayIndex = this.entries.findIndex(item => item.day === day);

		if (dayIndex !== -1) {
			this.entries[dayIndex].timelogs.push(newEntry);
		}
	}

	removeEntry(event) {
		const day = event.target.dataset.day;
		const index = event.target.dataset.index;
		const recordId = event.target.dataset.recordid;
		const recordtype = event.target.dataset.recordtype;

		const dayIndex = this.entries.findIndex(item => item.day === day);

		if (dayIndex !== -1) {
			const entry = this.entries[dayIndex][recordtype][index];
			const entryIndex = this.entries[dayIndex][recordtype].indexOf(entry);
					
			if (entryIndex !== -1) {
				this.entries[dayIndex][recordtype].splice(entryIndex, 1);
				this.removedIds.push(recordId);
			}
		}

		this.disabled = false;
	}

	handleSave(event){
		// console.log('this.entries');
		// console.log(JSON.stringify(this.entries));
		this.disabled = true;
		this.loading = true;

		saveTimesheetEntries({entries: this.entries, idsToUpdate: this.updatedIds, idsToDelete: this.removedIds, u: this.user})
		.then(result => {
			console.log('Result: ' + result);
		})
		.catch(error => {
			console.error('Error: ', error);
			
		})
		.finally(() => {
			refreshApex(this.refreshView);
			this.loading = false;
		});
	}
	
	submitForApproval(event){
		this.disabled = true;
		this.loading = true;

		submitForApproval({recordId: this.recordId})
		.then(result => {
			console.log('Result: ' + result);
		})
		.catch(error => {
			console.error('Error: ', error);
			
		})
		.finally(() => {
			refreshApex(this.refreshView);
			this.loading = false;
		});
	}

	reopen(event){
		this.disabled = true;
		this.loading = true;

		reopen({recordId: this.recordId})
		.then(result => {
			console.log('Result: ' + result);
		})
		.catch(error => {
			console.error('Error: ', error);
			
		})
		.finally(() => {
			refreshApex(this.refreshView);
			this.loading = false;
		});
	}

	async openExpenseModal() {
		const result = await ExpenseModal.open({
			size: 'small',
			description: 'Accessible description of modal\'s purpose',
			timesheetId: this.timesheetId,
			minDate: this.minDate,
			maxDate: this.maxDate
		})
		.then((result) => {
			console.log(result);

			if(result == 'Created'){
				refreshApex(this.refreshView);
			}
		})
		.catch(error => {
			console.error('Error:', error);
		});
	}

	generatePDF(event) {
		event.preventDefault();

		let base = basePath.slice(0, -2);
		let preset_url = '/apex/TimesheetExport?recordid=' + this.recordId;

		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
			attributes: {
				url: base + preset_url
			}
		})
		.then(generatedUrl => {
			window.open(generatedUrl);
		});
	}

	constructor() {
		super();
		Promise.all([
			loadStyle(this, styles)
		])

		loadStyle(this, FontAwesome6 + '/css/all.min.css')
		.then(() => {
			this.initializeStars();
		})
		.catch(error => {
			console.error('Error loading FontAwesome:', error);
		});
	}
}