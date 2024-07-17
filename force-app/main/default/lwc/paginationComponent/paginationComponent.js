import { LightningElement, api } from 'lwc';
import previousLabel from '@salesforce/label/c.Previous_label';
import nextLabel from '@salesforce/label/c.Next_label';
import lastLabel from '@salesforce/label/c.Last_label';
import firstLabel from '@salesforce/label/c.First_label';
import pageLabel from '@salesforce/label/c.Page_label';
import ofLabel from '@salesforce/label/c.Of_label';
import totalRecordsLabel from '@salesforce/label/c.Total_records_label';
import recordsPerPageLabel from '@salesforce/label/c.Records_per_page_label';

export default class PaginationComponent extends LightningElement {
	pageSizeOptions = [5, 10, 25, 50, 75, 100];
	pageSize;
	pageNumber = 1;
	totalPages;
	totalRecords;
	recordsToDisplay = [];
	_tableData = [];

    labels = {
        next: nextLabel,
        previous: previousLabel,
        first: firstLabel,
        last: lastLabel,
        page: pageLabel,
        of: ofLabel,
        totalRecords: totalRecordsLabel,
        recordsPerPage: recordsPerPageLabel
    };

	get onFirstPage() {
        return this.pageNumber == 1;
    }
    get onLastPage() {
        return this.pageNumber == this.totalPages;
    }
	@api
	get tableData() {
		return this._tableData;
	}
	set tableData(value) {
		this._tableData = [...value];
		this.totalRecords = this._tableData.length;
		this.updatePagination();
	}

	constructor() {
		super();

		this.pageSize = this.pageSizeOptions[0];
	}

	handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.updatePagination();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.updatePagination();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.updatePagination();
    }
    firstPage() {
        this.pageNumber = 1;
        this.updatePagination();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.updatePagination();
    }

	updatePagination() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.tableData[i]);
        }

		const evt = new CustomEvent('visiblerecordsupdated', { detail : { records: this.recordsToDisplay }});
		this.dispatchEvent(evt);
    }
}