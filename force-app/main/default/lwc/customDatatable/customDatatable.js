import LightningDatatable from "lightning/datatable";
import recordViewNavigationLink from './recordViewNavigationType.html';
import starRaterView from './starRatingType.html'
import datatableComboboxView from './datatableComboboxType.html'
import iconCarouselView from './iconCarouselType.html'
import documentLinkView from './documentLinkType.html'
import iconFromPicklistView from './iconFromPicklistType.html'
import customTextView from './customTextType.html'
import customApplicationMessageView from './customApplicationMessage.html'

import { loadStyle } from 'lightning/platformResourceLoader';

import DataTableStyle from '@salesforce/resourceUrl/datatableStyling';
import ModalStyle from "@salesforce/resourceUrl/modalContainerStyling";

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        recordViewNavigation: {
          template: recordViewNavigationLink,
          standardCellLayout: true,
          typeAttributes: ["recordName", "recordId", "objectApiName", "iconName"],
        },
        starRating: {
          template: starRaterView,
          standardCellLayout: true,
          typeAttributes: ["recordId", "fieldName", "rating", "rowEditable"],
        },
        datatableCombobox: {
          template: datatableComboboxView,
          standardCellLayout: true,
          typeAttributes: ["recordId", "fieldName", "locked", "options", "value", "placeholder", "rowEditable"], //"label", 'value', 'placeholder', 'context', 'contextName', 'fieldName'
        },
        iconCarousel: {
          template: iconCarouselView,
          standardCellLayout: true,
          typeAttributes: ["recordId", "fieldName", "locked", "items", "value", "rowEditable"],
        },
        documentLink: {
          template: documentLinkView,
          standardCellLayout: true,
          typeAttributes: ["documentId", "versionId", "iconName", "iconVariant", "title", "urlPrefix", "urlPostfix"],
        },
        iconFromPicklist: {
          template: iconFromPicklistView,
          standardCellLayout: true,
          typeAttributes: ["fieldName", "items", "value"]
        },
        customText: {
          template: customTextView,
          standardCellLayout: true,
          typeAttributes: ["recordId", "fieldName", "value", "rowEditable", "isRichText", "isFullView"]
        },
        applicationMessage: {
          template: customApplicationMessageView,
          standardCellLayout: true,
          typeAttributes: ["recordId", "recordName"]
        }
        // richTextType: {
        //   template: richTextView,
        //   standardCellLayout: true,
        //   typeAttributes: ["recordId", "fieldName", "value", "rowEditable"]
        // }
    }

    constructor() {
      super();
      Promise.all([
          loadStyle(this, DataTableStyle),
          loadStyle(this, ModalStyle)
      ])
      .then(() => {})
      .catch((error) => console.log(e))
  }
}