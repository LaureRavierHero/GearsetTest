import {LightningElement, api, track} from 'lwc';
import applyLabel from '@salesforce/label/c.LBL_apply';

export default class ComboBox extends LightningElement {
    @api key;
    @api label  = '';
    @api name = '';
    @api multiselect = false;
    @api showSelection = false;
    @api displayType;
    open = false;

    @track isDisabled = false;
    @track _options = [];
    _originalOptions = [];
    @api
    get options () {
        return this._options;
    }
    set options(value) {
        console.log('SET OPTIONS ' + JSON.stringify(value));
        this._options = [...value];
        this._originalOptions = [...value];
        // Sort filter
        if (this.displayType == 'starRating') {
            this._options.sort((a, b) => parseFloat(a.value) - parseFloat(b.value));
        }
        if (this._options.length == 0) {
            this.isDisabled = true;
        }
        else {
            this.isDisabled = false;
        }
    }
    
    @track _initializationCompleted = false;

    labels = {
        apply: applyLabel
    }
    _filterValue = '';
    get filterValue () {
        return this._filterValue;
    }
    set filterValue (value) {
        this._filterValue = value;
        this.updateListItems(this._filterValue);
    }

    /* utilities */
    renderedCallback () {
        let self = this;
        if (!this._initializationCompleted) {
            this.template.querySelector('.ms-input').addEventListener ('click', function (event) {
                self.handleToggle();
                event.stopPropagation ();
            });
            this.template.addEventListener ('click', function (event) {
                event.stopPropagation ();
            });
            document.addEventListener ('click', function (event) {
                self.closeAllDropDown();
            });
            this._initializationCompleted = true;
        }
    }

    /* Open and close */
    @api
    closeAllDropDown () {
        Array.from (this.template.querySelectorAll('.ms-picklist-dropdown')).forEach (function (node) {
            node.classList.remove('slds-is-open');
        });

        this.open = false;
        this._options = [...this._originalOptions]; // clears all selections that haven't been applied yet
        this.clearFilter();
    }

    openDropDown() {
        if (!this.open)  {
            Array.from (this.template.querySelectorAll ('.ms-picklist-dropdown')).forEach ((node) => {
                node.classList.add('slds-is-open');
            });
            this.open = true;
            const evt = new CustomEvent ('comboboxopened', { detail : { name: this.name }});
            this.dispatchEvent(evt);
        }
    }

    handleToggle () {
        if(!this.open) {
            this.openDropDown();
        } else {
            this.closeAllDropDown();
        }
    }

    /* Filtering */

    clearFilter() {
        this.filterValue = '';
    }

    updateListItems (inputText) {
        Array.from (this.template.querySelectorAll('c-pick-list-item')).forEach (function (node) {
            console.log(node.label.toString().toLowerCase());
            if(!inputText){
                node.style.display = "block";
            } else if (node.label.toString().toLowerCase().indexOf(inputText.toString().trim().toLowerCase()) != -1){
                console.log('display');
                node.style.display = "block";
            } else {
                console.log('hide');
                node.style.display = "none";
            }
        });
    }

    handleFilterInput(event) {
        this.filterValue = event.target.value;
    }

    /* Selecting */

    // Deselect all other values if not multiselect and item was selected
    handleSingleSelect(currentValue) {
        let tmp = JSON.parse(JSON.stringify(this._options));
        tmp.forEach ((eachItem) => {
            if (eachItem.value == currentValue) {
                eachItem.selected = true;
            }
            else {
                eachItem.selected = false;
            }
        });
        this._options = [...tmp];
    }

    // We can stop looping if value is found and multiselect or deselect
    handleMultiSelectOrDeselect(currentValue, currentSelected) {
        // We have to create a deep copy, so we need to rebuild the array
        let tmp = JSON.parse(JSON.stringify(this._options));
        tmp.forEach((eachItem) => {
            if (eachItem.value == currentValue) {
                eachItem.selected = currentSelected;
                return;
            }
        });
        this._options = [...tmp];
    }

    handleItemSelected(event) {
        const currentSelected = event.detail.selected;
        const currentValue = event.detail.value;
    
        if (currentSelected == true && !this.multiselect) {
            this.handleSingleSelect(currentValue);
        }
        else {
            this.handleMultiSelectOrDeselect(currentValue, currentSelected);
        }
    }

    getSelectedValues() {
        let selectedValues = [];

        this._options.forEach((elem ) => {
            if (elem.selected)
                selectedValues.push(JSON.parse(JSON.stringify(elem)).value);
        });
        return selectedValues;
    }

    handleApply() {
        const evt = new CustomEvent ('itemselected', { detail : { selectedValues: this.getSelectedValues(), name: this.name, label: this.label}});

        this.dispatchEvent(evt);
        this.closeAllDropDown();
    }
}