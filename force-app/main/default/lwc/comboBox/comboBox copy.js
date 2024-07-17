import {LightningElement, api, track} from 'lwc';

export default class ComboBoxCPY extends LightningElement {
    @api key;
    @api label  = ''; //Name of the dropDown
    @api name = '';
    @api options = []; // List of items to display
    @api showfilterinput = false; //show filterbutton
    // @api showrefreshbutton = false; //show the refresh button
    // @api showclearbutton = false; //show the clear button
    // @api comboplaceholder = 'Search filter values';
	// @api pillsEnabled = false;
    
    @track _initializationCompleted = false;
    @track _selectedItems = 'Select a value';
    @track _filterValue = '';
    @track _mOptions = [];
    @track _mCurrentSelection = [];

    // constructor () {
    //     super();
    //     this._filterValue = '';
	// 	this.label = '';
	// 	// this.pillsEnabled = true;
	// 	// this.options = [{ key: 'k1', name: 'k1', label: 'val', value: 'val' }, 
	// 	// 				{key: 'k2', name: 'k2' , label: 'val2', value: 'val2'},
	// 	// 				{key: 'k3', name: 'k3' , label: 'bob', value: 'bob'}];
		
	// 	// this.showfilterinput = true;
	// 	// this.showclearbutton = true;
    //     //this.showfilterinput = true;
    //     //this.showrefreshbutton = true;
    //     //this.showclearbutton = true;
    // }
    connectedCallback () { 
        this.initArray (this);
    }

    renderedCallback () {
        let self = this;
        if (!this._initializationCompleted) {
            this.template.querySelector ('.ms-input').addEventListener ('click', function (event) {
                self.onDropDownClick(event.target);
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

    @api
    deselectValue(name) {
        this._mOptions.forEach (function (eachItem) {
            if (eachItem.value == name) {
                eachItem.selected = false;
                return;
            }
        });
    }

    @api
    deselectAll() {
        this._mOptions.forEach (function (eachItem) {
            eachItem.selected = false;
        });
    }

	// handleClosePill (event) {
	// 	console.log(event.detail);
    //     var tst = this._mCurrentSelection.splice(event.detail.index, 1)[0];
    //     console.log(tst.value);
	// 	this._mOptions.forEach (function (eachItem) {
    //         if (eachItem.value == tst.value) {
	// 			console.log('deselecting ' + event.detail.name);
    //             eachItem.selected = false;
    //             return;
    //         }
    //     });
	// }

    // @api
    handleItemSelected (event) {
        let self = this;
        this._mOptions.forEach (function (eachItem) {
            if (eachItem.value == event.detail.item.value) {
				// console.log('event selected ' + event.detail.selected);
                eachItem.selected = event.detail.selected;
                return;
            }
        });
        this.onItemSelected (event.detail.item.value, event.detail.selected);
    }

    filterDropDownValues (event) {
        this._filterValue = event.target.value;
		
        this.updateListItems (this._filterValue);
    }

    closeAllDropDown () {
        Array.from (this.template.querySelectorAll ('.ms-picklist-dropdown')).forEach (function (node) {
             node.classList.remove('slds-is-open');
        });
    }

    clearFilter(){
        this.template.querySelectorAll('input.slds-combobox__input').forEach(each => {
            // console.log(each.value);
            each.value = '';

        });
        this.updateListItems('');
    }

    onDropDownClick (dropDownDiv) {
        let classList = Array.from (this.template.querySelectorAll ('.ms-picklist-dropdown'));
        if(!classList.includes("slds-is-open")){
            this.closeAllDropDown();
            Array.from (this.template.querySelectorAll ('.ms-picklist-dropdown')).forEach (function (node) {
                node.classList.add('slds-is-open');
            });
        } else {
            this.closeAllDropDown();
        }
    }
    // onRefreshClick (event) {
    //     this._filterValue = '';
    //     this.initArray (this);
    //     this.updateListItems ('');
    //     this.onItemSelected ();
    // }
    // onClearClick (event) {
    //     this._filterValue = '';
    //     this.updateListItems ('');
    // }


    initArray (context) {
        context._mOptions = new Array ();
        // console.log('OPTIONS ' + context.options);
        context.options.forEach (function (eachItem) {
            context._mOptions.push(JSON.parse(JSON.stringify(eachItem)));
        });
    }

    updateListItems (inputText) {
        Array.from (this.template.querySelectorAll('c-pick-list-item')).forEach (function (node) {
            if(!inputText){
                node.style.display = "block";
            } else if(node.item.value.toString().toLowerCase().indexOf(inputText.toString().trim().toLowerCase()) != -1){
                node.style.display = "block";
            } else {
                node.style.display = "none";
            }
        });
    }

    @api
    getSelectedItems () {
        let resArray = new Array ();
        // console.log('_mOptions\n' + JSON.stringify(this._mOptions));
        this._mOptions.forEach (function (eachItem) {
            if (eachItem.selected) {
                resArray.push(eachItem.value);
            }
        });
        return resArray;
    }

    onItemSelected (selectedItem, wasSelect) {
        const evt = new CustomEvent ('itemselected', { detail : { selectedValues: this.getSelectedItems(), changedValue: selectedItem, selected: wasSelect, name: this.name, label: this.label}});
        this.dispatchEvent(evt);
        this._mCurrentSelection = this.getSelectedItems();
    }
}