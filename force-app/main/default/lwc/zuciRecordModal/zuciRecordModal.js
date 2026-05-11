import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ZuciRecordModal extends LightningElement {
    @api isOpen = false;
    @api recordId;
    @api objectApiName;
    @api fields = [];
    @api modalTitle = 'Record';

    get formMode() {
        return this.recordId ? 'edit' : 'edit';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdropClick() {
        this.handleClose();
    }

    stopPropagation(event) {
        event.stopPropagation();
    }

    handleSuccess(event) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: `Record ${this.recordId ? 'updated' : 'created'} successfully.`,
            variant: 'success'
        }));
        this.dispatchEvent(new CustomEvent('recordsaved', { detail: { id: event.detail.id } }));
    }

    handleError(event) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: event.detail.detail || 'An error occurred.',
            variant: 'error'
        }));
    }
}