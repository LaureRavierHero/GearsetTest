import { LightningElement, api, track } from 'lwc';

export default class FilterComponentCopy extends LightningElement {
    @track _tableData = [];
    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        this._tableData = value;
        this.setupFilters();
        // this.setFilterValues(); //updateFilterValues
    }
    @api filterColumnsApiNames = [];
    @api filterColumnLabels = [];
    @track filterData = new Map(); // [] needs to be a list of objects by index
    @track flatFilterData = [];
    @track pillData = new Map();//[];
    @track flatPillData = [];
    
    connectedCallback() {
        this.setupFilters();
    }

    setupFilters() {
        console.log('setup filters');
        // this.filterData = new Map();
        this.filterColumnsApiNames.forEach((elem, index) => {
            // this.pillData.set(elem, []);
            this.filterData.set(elem,
                {
                    fieldIndex: index,
                    fieldName: elem,
                    fieldLabel: this.filterColumnLabels[index],
                    fieldValue: "",
                    fieldOptions: this.getFieldOptions(elem)
                }
            );
            // console.log(JSON.stringify(this.filterData.get(elem)));
        })
        // for (const [key, value] of this.filterData) { // Using the default iterator (could be `map.entries()` instead)
        //     console.log(`The value for key ${key} is ${value}`);
        // }
        console.log('Filterdata len' + JSON.stringify(Object.fromEntries([...this.filterData.entries()])));
        this.flatFilterData = this.filterData.values();
        // this.filterColumnsApiNames.forEach((currentElement, index) => {
            // this.filterData = [
            //     ...this.filterData,
            //     {
            //         fieldIndex: index,
            //         fieldName: currentElement,
            //         fieldLabel: this.filterColumnLabels[index],
            //         fieldValue: "",
            //         fieldOptions: this.getFieldOptions(currentElement)
            //     }
            // ];
        // });
    }
    
    setFilterValues() {
        for (let [key, value] of this.filterData) {
            value.fieldOptions = this.getFieldOptions(key);
        }
        this.flatFilterData = this.filterData.values();
        // this.filterData.forEach((filter) => {
        //     filter.fieldOptions = this.getFieldOptions(filter.fieldName);
        // })

        // this.filterData = [...this.filterData];
    }

    getFieldOptions(fieldApiName) {
        // Logic to keep only unique values in the filter picklist
        let toReturn = [];
        let tempValueArray = [];

        this._tableData.forEach((currentElement) => {
            // Check if value already in array
            if (currentElement[fieldApiName] && tempValueArray.indexOf(currentElement[fieldApiName]) < 0) {
                console.log('FIELD API NAME: ' + fieldApiName);
                console.log('ITEM: ' + currentElement[fieldApiName]);
                tempValueArray.push(currentElement[fieldApiName]);
                let sel = false;
                let filterMap = this.filterData.get(fieldApiName);
                if (filterMap) {
                    sel = filterMap.fieldOptions.includes(currentElement[fieldApiName]);
                    console.log('Filtermap includes item');
                }
                toReturn = [...toReturn,
                    // currentElement[fieldApiName]
                    { value: currentElement[fieldApiName], selected: sel }
                ];
            }
        });
        return toReturn;
    }

    handleSelect(event) {
        // Update pills when a user clicks 'apply' on a combobox
        let currentFieldName = event.detail.name;
        let currentFieldLabel = event.detail.label;
        let currentSelectedValues = event.detail.selectedValues;

        // let tmp = [...this.pillData];

        // Remove pills not in currentSelected values
        // for (let i = 0; i < this.pillData.length; ++i) {
        //     if (this.pillData[i].fieldName === currentFieldName && !currentSelectedValues.includes(this.pillData[i].fieldValue)) {
        //         tmp.splice(i, 1);
        //     }
        // }
        console.log('CURRENT SELECTED: ' + currentFieldName + ' ' + JSON.stringify(currentSelectedValues));
        console.log(JSON.stringify(this.pillData));

        // this.filterData.get(currentFieldName).fieldOptions = 
        this.pillData.set(currentFieldName, currentSelectedValues.map((val, index) => {
            let obj = {
                fieldIndex: index,
                fieldValue: val,
                fieldName: currentFieldName,
                fieldLabel: currentFieldLabel + ': ' + val
            }
            console.log('IN THE THING: ' + JSON.stringify(obj));
            return obj;
        }));

        console.log(this.pillData.size);
        console.log('Pill data: ' + JSON.stringify(Object.fromEntries([...this.pillData.entries()])));
        console.log(this.pillData.values.size);
        this.flatPillData = Array.from(this.pillData.values()).flat();
        console.log('FLAT PILLDATA ' + JSON.stringify(this.flatPillData));
        // this.flatFilterData = this.filterData.values();
        // Add only selected elements not yet in pills
        // currentSelectedValues.forEach((elem) => {
        //     let exists = false;
        //     for (let i = 0; i < this.pillData.length; ++i) {
        //         if (this.pillData[i].fieldValue === elem && this.pillData[i].fieldName === currentFieldName) {
        //             exists = true;
        //         }
        //     }
        //     if (!exists) {
        //         tmp = [...tmp, {
        //             fieldIndex: tmp.length,
        //             fieldValue: elem,
        //             fieldName: currentFieldName,
        //             fieldLabel: currentFieldLabel + ': ' + elem
        //         }];
        //     }
        // });
        // this.pillData = [...tmp];


        this.propagateFilters();
    }

    handleRemovePill(event) {
        console.log('HANDLE REMOVE PILL');
        let currentFieldName = event.target.name;
        let currentFieldValue = event.target.dataset.value;
        let currentFieldIndex = this.flatPillData[event.target.dataset.index].fieldIndex;

        console.log('Current field: ' + currentFieldName);
        console.log('Current index: ' + currentFieldIndex);
        console.log('Pill filters: ' + JSON.stringify(this.pillData.get(currentFieldName)));
        this.pillData.get(currentFieldName).splice(currentFieldIndex, 1);
        this.flatPillData = Array.from(this.pillData.values()).flat();
        // Name and value
        // this.pillData.splice(currentFieldIndex, 1);

        // Update comboboxes if pill is removed
        this.template.querySelectorAll('c-combo-box').forEach((currentElement) => {
            if (currentElement.name == currentFieldName)
                currentElement.deselectValue(currentFieldValue, true);
        });
        this.propagateFilters();
    }

    // Remove all pills and all selected items in comboboxes
    resetAll() {
        this.template.querySelectorAll('c-combo-box').forEach((currentElement) => {
            currentElement.deselectAll(true);
        });
        this.pillData.clear();
        this.flatPillData = Array.from(this.pillData.values()).flat();
        this.propagateFilters();
    }

    // Notify parent component of filter change so data can be filtered
    propagateFilters() {
        let res = [];
        this.template.querySelectorAll('c-combo-box').forEach((currentElement) => {
                let values = currentElement.getSelectedItems();
                if (values.length != 0)
                    res.push({name: currentElement.name, values: values});
        });
        const evt = new CustomEvent('filtersselected', {detail: res});
        this.dispatchEvent(evt);
    }

    // If one combobox is opened, close all others
    handleComboBoxOpened(event) {
        this.template.querySelectorAll('c-combo-box').forEach((currentElement) => {
            if (currentElement.name != event.detail.name && currentElement.open) {
                currentElement.closeAllDropDown();
            }
        });
    }
}