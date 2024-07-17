import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import checkSite from '@salesforce/apex/LWCApexUtils.isCommunityContext';
import { generateUrl } from "lightning/fileDownload";

export default class DocumentLink extends NavigationMixin(LightningElement) {
    @api urlPrefix; // orgUrl + '/sfc/servlet.shepherd/version/download/' for DocumentVersion for example
    @api urlPostfix = ''; // '?operationContext=S1' for DocumentVersion
    @api documentId;
    @api versionId;
    @api iconName;
    @api iconVariant;
    @api title;
    isCommunity;

    url;

    connectedCallback() {
        checkSite()
        .then((isSite) => {
            this.isCommunity = isSite;
        });


        this.url = window.origin + generateUrl(this.documentId);
    }

    handleClick(event) {
        if (!this.isCommunity) {
            this[NavigationMixin.Navigate]({
                type: "standard__namedPage",
                attributes: {
                    pageName: "filePreview",
                },
                state: {
                    selectedRecordId: this.versionId,
                },
            });
        }
        else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.url
                }
            })
        }
    }
}