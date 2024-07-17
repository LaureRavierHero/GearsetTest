import { LightningElement, api, track } from 'lwc';

export default class FilterComponent extends LightningElement {
    @track _tableData = [];
    @api
    get tableData() {
        return this._tableData;
    }
    set tableData(value) {
        console.log('SET TABLEDATA');
        this._tableData = value;
        // this.filterData = new Map();
        // this.setupFilters();
        this.setupFilters(); //updateFilterValues
    }
    @api filters;
    @track filterData = new Map();
    @track flatFilterData = []; // purely for passing in html
    @track pillData = new Map();
    @track flatPillData = []; // purely for passing in html
    
    connectedCallback() {
        this.setupFilters();
    }

    setupFilters() {
        console.log('SETUP FILTERS');
        console.log('SETUP FILTERS ' + JSON.stringify(this.filters));

        let tmp = new Map();
        this.filterData = new Map();
        this.filters.forEach((elem, index) => {
            console.log('ELEM ' + JSON.stringify(elem));
            tmp.set(elem.columnName,
                {
                    displayType: elem.displayType,
                    fieldIndex: index,
                    fieldName: elem.columnName,
                    fieldLabel: elem.columnLabel,
                    fieldValue: "",
                    fieldOptions: this.getFieldOptions(elem.columnName),
                    multiselectFilter: elem.multiselect,
                }
            );
        })

        this.filterData = tmp;
        console.log('SETUP FILTERS ' + JSON.stringify(this.filterData));
        this.flatFilterData = [...this.filterData.values()];
        console.log('FILTER DATA ' + JSON.stringify(this.flatFilterData));
    }
    
    setFilterValues() {
        console.log('SET FILTER VALUES');
        console.log('FILTERS ' + JSON.stringify(this.filterData));

        for (let [key, value] of this.filterData) {
            value.fieldOptions = this.getFieldOptions(key);
        }
        this.flatFilterData = this.filterData.values();
        console.log('FILTER DATA ' + JSON.stringify(this.flatFilterData));
    }

    getFieldOptions(columnName) {
        // Logic to keep only unique values in the filter picklist
        let toReturn = [];
        let tempValueArray = [];

        console.log('GET FIELD OPTIONS ' + columnName);
        this._tableData.forEach((currentElement) => {
            // console.log('currentElement' + JSON.stringify(currentElement));
            // Check if value already in array
            if ((currentElement[columnName] || currentElement[columnName] === false || currentElement[columnName] === 0) && tempValueArray.indexOf(currentElement[columnName]) < 0) {
                console.log('adding value' + currentElement[columnName]);
                tempValueArray.push(currentElement[columnName]);
                let sel = false;
                let pillMap = this.pillData.get(columnName);
                // Check for selected status
                if (pillMap) {
                    let values = pillMap.map(obj => obj.fieldValue);
                    sel = values.includes(currentElement[columnName]);
                }
                toReturn = [...toReturn,
                    { value: currentElement[columnName], label: currentElement[columnName], selected: sel }
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

        // Remove pills not in currentSelected values
        for (let i = 0; i < this.pillData.length; ++i) {
            if (this.pillData[i].fieldName === currentFieldName && !currentSelectedValues.includes(this.pillData[i].fieldValue)) {
                tmp.splice(i, 1);
            }
        }

        // Set pills for filter to currently selected values
        this.pillData.set(currentFieldName, currentSelectedValues.map((val, index) => {
            let obj = {
                fieldIndex: index,
                fieldValue: val,
                fieldName: currentFieldName,
                fieldLabel: currentFieldLabel + ': ' + val
            }
            return obj;
        }));

        this.flatPillData = Array.from(this.pillData.values()).flat();
        this.propagateFilters();
    }

    handleRemovePill(event) {
        let currentFieldName = event.target.name;
        let currentFieldValue = event.target.dataset.value;
        let fieldValArray = this.pillData.get(currentFieldName).map(obj => obj.fieldValue);
        let currentFieldIndex = fieldValArray.indexOf(currentFieldValue);

        this.pillData.get(currentFieldName).splice(currentFieldIndex, 1);
        this.flatPillData = Array.from(this.pillData.values()).flat();

        this.propagateFilters();
    }

    // Remove all pills and all selected items in comboboxes
    resetAll() {
        this.pillData.clear();
        this.flatPillData = Array.from(this.pillData.values()).flat();
        this.propagateFilters();
    }

    // Notify parent component of filter change so data can be filtered
    propagateFilters() {
        let res = [];
        for (const [key, value] of this.pillData) {
            res.push({name: key, values: value.map(obj => obj.fieldValue)});
        }
    
        const evt = new CustomEvent('filtersselected', {detail: res});
        this.dispatchEvent(evt);
    }

    // If one combobox is opened, close all others
    handleComboBoxOpened(event) {
        this.template.querySelectorAll('c-combo-box').forEach((currentElement) => {
            if (currentElement.name != event.detail.name) {
                currentElement.closeAllDropDown();
            }
        });
    }
}