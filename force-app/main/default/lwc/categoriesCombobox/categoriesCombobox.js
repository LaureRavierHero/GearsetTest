import { LightningElement, wire, api, track } from 'lwc';
import getCategories from '@salesforce/apex/CategoriesController.getCategories';
import addCategories from '@salesforce/apex/CategoriesController.addCategories';
import removeCategory from '@salesforce/apex/CategoriesController.removeCategory';
import sectionTitle from '@salesforce/label/c.LBL_categories_section_title';

export default class CategoriesCombobox extends LightningElement {
    @api availableActions = []
    @api selectedCategoryIds = [];
    originallySelectedCategoryIds = [];
    @api deletedIds = [];
    @api addedIds = [];
    @api selectedItems = [];
    @track _options;
    type;
    count;
    title = sectionTitle;
    @api 
    get options() {
        return this._options;
    }
    set options(value) { 
        this._options = [...value];
        let selectedIds = [];
        this._options.forEach((obj) => {
            if (obj.selected == true) {
                selectedIds.push(obj.value);
            }
        });
        this.originallySelectedCategoryIds = [...selectedIds];
        this.count = this.originallySelectedCategoryIds.length;
    }
    _record;
    @api recordId;
    @api
    get record() {
        return this._record;
    }
    set record(val) {
        this._record = val;
        this.recordId = val;
    }
    error;
    name = sectionTitle;
    label = sectionTitle;
    connectedCallback() {
        /* If component is in a flow, set type to flow, otherwise set to record */
        if (this.availableActions.includes('FINISH')) {
            this.type = 'flow';
        }
        else {
            this.type = 'record';
        }
    }

    renderedCallback() {
        if (typeof this.recordId === 'undefined') {
            this.recordId = '';
        }
    }

    @wire(getCategories, {recordId: '$recordId', type: '$type'})
    wiredCategories({error, data}) {
        if (data) {
            let tmp = [];
            data.forEach((elem) => {
                tmp.push({
                    value: elem.id,
                    label: elem.label,
                    selected: elem.selected
                })
            });

            this.options = [...tmp];
            this.setSelectedValues();
        }
        else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    setSelectedValues() {
        let currentSelectedValues = [];
        let index = 0;

        this.options.forEach((elem) => {
            if (elem.selected == true) {
                currentSelectedValues.push({
                    name: elem.value,
                    label: elem.label,
                    index: index
                });
                index++;
            }
        });

        this.selectedItems = [...currentSelectedValues];
        this.selectedCategoryIds = this.selectedItems.map(obj => obj.name);
        this.count = this.selectedCategoryIds.length;
    }

    updateOnSelect(selectedValues) {
        this.options.forEach((elem) => {
            if (selectedValues.includes(elem.value)) {
                elem.selected = true;
            }
            else {
                elem.selected = false;
            }
        });

        

        if (this.type == 'record') {
            /* Check which ids were added in the operation by removing any id's 
            that wer in the previous selection */
            let previousSelection = [...this.selectedCategoryIds];
            this.setSelectedValues();
            let newlySelectedIds = this.selectedCategoryIds.filter((elem) => {
                return !previousSelection.includes(elem);
            });
            addCategories({recordId: this.recordId, categoryIds: newlySelectedIds});
        }
        else if (this.type == 'flow') {
            /* Add ids that were not in the original selection but are in 
            the current selection */
            let originalIds = [...this.originallySelectedCategoryIds];
            this.setSelectedValues();
            this.addedIds = this.selectedCategoryIds.filter((elem) => {
                return !originalIds.includes(elem);
            });
            /* Delete ids that were in the original selection but are not in 
            the current selection */
            let selectedIds = [...this.selectedCategoryIds];
            this.deletedIds = this.originallySelectedCategoryIds.filter((elem) => {
                return !selectedIds.includes(elem);
            });
        }
    }

    updateOnPillRemove(removedValue, removedIndex) {
        // let tmp = [...this.options];
        this.options.forEach((elem) => {
            // console.log('ITEM ' + JSON.stringify(elem));
            if (removedValue == elem.value) {
                // console.log('contained');
                elem.selected = false;
            }
        });

        this.selectedItems.splice(removedIndex, 1);
        this.selectedCategoryIds = this.selectedItems.map(obj => obj.name);

        if (this.type == 'record') {
            removeCategory({recordId: this.recordId, categoryId: removedValue});
        }
        else if (this.type == 'flow') {
            if (this.originallySelectedCategoryIds.includes(removedValue)) {
                this.deletedIds.push(removedValue);
            }
        }
        this.count--;
    }

    handleSelect(event) {
        let selected = event.detail.selectedValues;

        this.updateOnSelect(selected);
    }

    handleItemRemove(event) {
        const name = event.detail.item.name;
        const index = event.detail.index;

        this.updateOnPillRemove(name, index);
    }
}