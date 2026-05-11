// addCredentials.js
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getRelatedFiles from '@salesforce/apex/CredentialsController.getRelatedFiles';
import deleteFile from '@salesforce/apex/CredentialsController.deleteFile';
import tagFilesWithCredentialType from '@salesforce/apex/CredentialsController.tagFilesWithCredentialType';

export default class AddCredentials extends NavigationMixin(LightningElement) {
    @api recordId;
    
    credentialType = '';
    uploadedFiles = [];
    wiredFilesResult;
    isLoading = false;

    credentialOptions = [
        { label: 'Aadhaar Card', value: 'Aadhaar_Card' },
        { label: 'PAN Card', value: 'PAN_Card' },
        { label: 'Passport Photo', value: 'Passport_Photo' }
    ];

    @wire(getRelatedFiles, { recordId: '$recordId' })
    wiredFiles(result) {
        this.wiredFilesResult = result;
        if (result.data) {
            this.uploadedFiles = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Error loading files', 'error');
        }
    }

    handleCredentialTypeChange(event) {
        this.credentialType = event.detail.value;
    }

    async handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        
        // Tag the uploaded files with credential type
        if (this.credentialType && uploadedFiles.length > 0) {
            try {
                const contentVersionIds = uploadedFiles.map(file => file.contentVersionId);
                await tagFilesWithCredentialType({ 
                    contentVersionIds: contentVersionIds, 
                    credentialType: this.credentialType 
                });
                
                this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
                
                // Wait a bit for the async operation to complete, then refresh
                setTimeout(() => {
                    refreshApex(this.wiredFilesResult);
                }, 1000);
            } catch (error) {
                console.error('Error tagging files:', error);
                this.showToast('Error', 'Error tagging files: ' + error.body?.message, 'error');
                refreshApex(this.wiredFilesResult);
            }
        } else {
            this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
            refreshApex(this.wiredFilesResult);
        }
        
        // Reset credential type
        this.credentialType = '';
    }

    async handleDelete(event) {
        const fileId = event.target.dataset.id;
        this.isLoading = true;
        
        try {
            await deleteFile({ contentDocumentId: fileId });
            this.showToast('Success', 'File deleted successfully', 'success');
            refreshApex(this.wiredFilesResult);
        } catch (error) {
            this.showToast('Error', 'Error deleting file: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleViewFile(event) {
        const fileId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: fileId
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    get isUploadDisabled() {
        return !this.credentialType;
    }

    get hasFiles() {
        return this.uploadedFiles && this.uploadedFiles.length > 0;
    }
}