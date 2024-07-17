import { LightningElement, api, wire, track } from 'lwc';
import {refreshApex} from '@salesforce/apex';

import getRatePercentages from '@salesforce/apex/RatePercentageSelectorController.getRatePercentages';
import saveRatePercentages from '@salesforce/apex/RatePercentageSelectorController.saveRatePercentages';

import lbl_rate_percentage_header from '@salesforce/label/c.lbl_rate_percentage_header';
import lbl_rate_percentage_select_options from '@salesforce/label/c.lbl_rate_percentage_select_options';
import lbl_rate_percentage_available from '@salesforce/label/c.lbl_rate_percentage_available';
import lbl_rate_percentage_selected from '@salesforce/label/c.lbl_rate_percentage_selected';
import lbl_save from '@salesforce/label/c.lbl_save';
import lbl_edit from '@salesforce/label/c.lbl_edit';

export default class RatePercentageSelector extends LightningElement {
    @api recordId;
    view = true;

    options = [];
    values = [];
    requiredOptions = [];

    selectedItems;
    selectedItemsUpdate;

    labels = {
		lbl_rate_percentage_header : lbl_rate_percentage_header,
		lbl_rate_percentage_select_options : lbl_rate_percentage_select_options,
		lbl_rate_percentage_available : lbl_rate_percentage_available,
		lbl_save : lbl_save,
		lbl_edit : lbl_edit,
        lbl_rate_percentage_selected : lbl_rate_percentage_selected,
	};

    @wire(getRatePercentages, {recordId: '$recordId'}) wiredRatePercentages(result){
		this.refreshView = result;
        if(result.data){
            this.selectedItems = result.data.selectedRatePercentageList;
            result.data.selectedRatePercentageList.forEach(item => {
                if(item.Rate_percentage__r.Is_standard__c){
                    this.requiredOptions.push(item.Rate_percentage__c);
                }else{
                    this.values.push(item.Rate_percentage__c);
                }
            });

            result.data.notSelectedRatePercentageList.forEach(item => {
                this.options.push({
                    label: item.Name,
                    value: item.Id,
                });
            });

            this.loading = false;
            this.visible = true;
        } else if (result.error) {
			this.error = result.error;
			console.log(this.error);
		}
    }

    
    handleEditClick(){
        this.view = !this.view;
    }

    handleChange(event) {
        this.selectedItemsUpdate = event.detail.value;
    }

    handleSaveClick(){
        saveRatePercentages({ratePercentageIds: this.selectedItemsUpdate, recordId: this.recordId})
		.then((result) => {
            console.log(result);
            this.options = [];
            this.values = [];
            this.requiredOptions = [];
            refreshApex(this.refreshView);
            this.view = !this.view;
		})

    }
}