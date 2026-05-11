import { LightningElement, api, wire } from 'lwc';
import isPropertyRecord from '@salesforce/apex/SalesProcessVisibilityController.isPropertyRecord';

export default class SalesProcessFinal extends LightningElement {
    @api recordId;
    isProperty = false;

    @wire(isPropertyRecord, { recordId: '$recordId' })
    wiredCheck({ data, error }) {
        if (data === true) {
            this.isProperty = true;
        } else {
            this.isProperty = false;
        }
    }

    get shouldShowComponent() {
        return this.isProperty;
    }
}