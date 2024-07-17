import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MyModal extends LightningModal {
    @api fileId;
    @api label;
    @api baseUrl;

    get fileURL(){
      return this.baseUrl + '/sfc/servlet.shepherd/version/download/' + this.fileId + '?operationContext=S1';
  }
    handleOkay() {
        this.close('okay');
    }
}