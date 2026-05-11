import { LightningElement, api, wire } from 'lwc';
import getPropertyManagerInfo from '@salesforce/apex/PropertyManagerContactController.getPropertyManagerInfo';
export default class PropertyManagerDisplay extends LightningElement {
    @api recordId;
    
    managerInfo;
    error;
    isLoading = true;

    @wire(getPropertyManagerInfo, { propertyId: '$recordId' })
    wiredManagerInfo({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.managerInfo = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : 'An unknown error occurred';
            this.managerInfo = undefined;
        }
    }

    // New computed property to control component visibility
    get shouldShowComponent() {
        // Hide component if "property record not found" message exists
        if (this.managerInfo && this.managerInfo.message && 
            this.managerInfo.message.toLowerCase().includes('property record not found')) {
            return false;
        }
        // Also hide if there's an error containing "property record not found"
        if (this.error && this.error.toLowerCase().includes('property record not found')) {
            return false;
        }
        return true;
    }

    get showManagerInfo() {

        return this.managerInfo && this.managerInfo.hasManager;
    }

    get showNoManager() {
        return this.managerInfo && !this.managerInfo.hasManager && 
               // Don't show "no manager" state if property record not found
               !(this.managerInfo.message && 
                 this.managerInfo.message.toLowerCase().includes('property record not found'));
    }

    get emailLink() {
        return this.managerInfo && this.managerInfo.managerEmail 
            ? `mailto:${this.managerInfo.managerEmail}` 
            : '';
    }

    get phoneLink() {
        return this.managerInfo && this.managerInfo.managerPhone 
            ? `tel:${this.managerInfo.managerPhone}` 
            : '';
    }

    handleEmailClick() {
        if (this.managerInfo && this.managerInfo.managerEmail) {
            window.location.href = `mailto:${this.managerInfo.managerEmail}`;
        }
    }

    handlePhoneClick() {
        if (this.managerInfo && this.managerInfo.managerPhone) {
            window.location.href = `tel:${this.managerInfo.managerPhone}`;
        }
    }
}