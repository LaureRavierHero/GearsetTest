// import { LightningElement, api, track } from 'lwc';
// import { NavigationMixin } from 'lightning/navigation';

// export default class ClickableObjectName extends NavigationMixin(LightningElement) {
//        // contains json with id and label
//     @track label;             // Text to be displayed as the link
//     @api title;             // Text to be displayed when hovering on the link (optional, will default to label)

//     @api type;               // PageReference Type (default of "standard__recordPage" if recordId provided)
//     @track recordId;           // Id of the record
//     @api objectApiName;      // Object type
//     @api actionName;         // Action to perform when clicked (default of "view" if recordId provided)

//     @track url;
//     pageRef = null;

//     @api
//     set val(value) {
//         this.label = JSON.parse(value).Name;
//         this.recordId = JSON.parse(value).Id;
//         _value = value;
//     }
//     connectedCallback() {
//         super.connectedCallback();
//         console.log('HELLO I AM HERE CONNECTED');
//         console.log('Value' + this.value);
//         this.label = 'I aM FromConnetct';
//     }
//     renderedCallback() {
//         super.renderedCallback();
//         console.log('HELLO I AM HERE RENDERED');
//         console.log('Value' + this.value);
//         // var objVal = JSON.parse(this.value);

//         this.label = objVal.Name;
//         this.recordId = objVal.Id;
//         // check for errors
//         if (!this.type || !this.recordId) return;

//         // if (!this.title && this.label)
//         //     this.title = this.label;
//         if (this.recordId) {
//             if (!this.type) this.type = "standard__recordPage";
//             if (!this.actionName) this.actionName = 'view';
//         }

//         // Generate the page reference for NavigationMixin...
//         this.pageRef = {
//             type: this.type,
//             attributes: {
//                 recordId: this.recordId,
//                 objectApiName: this.objectApiName,
//                 actionName: this.actionName
//             }
//         };

//         // Set the link's HREF value so the user can click "open in new tab" or copy the link...
//         if (this.pageRef) this[NavigationMixin.GenerateUrl](this.pageRef)
//             .then((url) => { this.url = url });
//     }

//     handleClick(event) {
//         console.log('ON CLICK');
//         console.log('Page ref: ' + this.pageRef);
//         if (!this.pageRef) return;

//         // Stop the event's default behavior (don't follow the HREF link) and prevent click bubbling up in the DOM...
//         event.preventDefault();
//         event.stopPropagation();

//         // Navigate as requested...
//         this[NavigationMixin.Navigate](this.pageRef);

//     }
// }