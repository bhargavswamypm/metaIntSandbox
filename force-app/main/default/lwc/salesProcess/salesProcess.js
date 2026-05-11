import { LightningElement, api, wire } from 'lwc';
import getObjectApiName from '@salesforce/apex/RecordHelper.getObjectApiName';

export default class SalesProcess extends LightningElement {
    @api recordId;
    objectApiName;
    isLoading = true;
    error;
    
    @wire(getObjectApiName, { recordId: '$recordId' })
    wiredObjectName({ error, data }) {
        if (data) {
            this.objectApiName = data;
            this.isLoading = false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.objectApiName = undefined;
            this.isLoading = false;
            console.error('Error fetching object name:', error);
        }
    }
    
    get isPropertyObject() {
        return this.objectApiName === 'Property__c';
    }
    
    get shouldDisplay() {
        return !this.isLoading && this.isPropertyObject;
    }
}