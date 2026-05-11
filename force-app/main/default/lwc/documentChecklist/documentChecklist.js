import { LightningElement, api, track } from 'lwc';
import getChecklistData from '@salesforce/apex/DocumentChecklistController.getChecklistData';
import uploadFile from '@salesforce/apex/DocumentChecklistController.uploadFile';
import deletePropertyDocument from '@salesforce/apex/DocumentChecklistController.deletePropertyDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DocumentChecklist extends LightningElement {

    @api recordId;
    @api fieldsList =
        'Sale_Deed__c,Agreement_to_Sell__c,Agreement_to_Construct__c,E_Khata__c,Latest_Property_Tax_receipt__c,Aadhaar_copies_of_the_owner_seller__c,PAN_copies_of_the_owner_seller__c,Aadhaar_PAN_copies_of_co_owner__c,Property_Images__c,Property_videos__c,Car_Parking_Letter__c';

    @track items = [];
    @track loading = true;

    cardTitle = 'Document Checklist';

    connectedCallback() {
        setTimeout(() => {
            this.loadData();
        }, 0);
    }

    loadData() {
        this.loading = true;

        getChecklistData({
            propertyId: this.recordId,
            fieldsCsv: this.fieldsList
        })
            .then(res => {
                const rows = res[0];
                const name = res[1];

                this.items = rows.map(r => {
                    let iconName = 'utility:document';
                    if (r.uploaded) iconName = 'utility:check';
                    else if (r.checked) iconName = 'utility:close';

                    // Use documents array if available, otherwise create from single document
                    let documents = [];
                    if (r.documents && r.documents.length > 0) {
                        documents = r.documents;
                    } else if (r.uploaded) {
                        documents = [{
                            propertyDocumentId: r.propertyDocumentId,
                            contentDocumentId: r.contentDocumentId,
                            fileName: r.fileName || 'Document'
                        }];
                    }

                    return { 
                        ...r, 
                        iconName,
                        documents: documents
                    };
                });

                this.cardTitle = 'Document Checklist — ' + name;
                this.loading = false;
            })
            .catch(err => {
                this.loading = false;
                this.showToast('Error', err.body?.message, 'error');
            });
    }

    prepareUpload(event) {
        const label = event.target.dataset.label;
        const input = this.template.querySelector('input[type="file"]');
        input.dataset.label = label;
        input.value = null;
        input.click();
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        const label = event.target.dataset.label;
        if (!file) return;

        const reader = new FileReader();

        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.loading = true;

            uploadFile({
                propertyId: this.recordId,
                documentType: label,
                base64Data: base64,
                fileName: file.name,
                contentType: file.type
            })
                .then(res => {
                    if (res.success === 'true') {
                        this.showToast('Success', file.name + ' uploaded', 'success');

                        // Add to documents array
                        this.items = this.items.map(item => {
                            if (item.label === label) {
                                const newDoc = {
                                    propertyDocumentId: res.propertyDocumentId,
                                    contentDocumentId: res.contentDocumentId,
                                    fileName: file.name
                                };
                                
                                return {
                                    ...item,
                                    uploaded: true,
                                    documents: [...item.documents, newDoc],
                                    iconName: 'utility:check'
                                };
                            }
                            return item;
                        });

                        this.loading = false;
                    } else {
                        this.showToast('Error', res.error, 'error');
                        this.loading = false;
                    }
                })
                .catch(err => {
                    this.loading = false;
                    this.showToast('Error', err.body?.message, 'error');
                });
        };

        reader.readAsDataURL(file);
    }

    handleView(event) {
        const contentDocumentId = event.target.dataset.id;
        
        // For Experience Cloud, open file in new tab
        const baseUrl = window.location.origin;
        const fileUrl = `${baseUrl}/sfc/servlet.shepherd/document/download/${contentDocumentId}`;
        window.open(fileUrl, '_blank');
    }

    handleDelete(event) {
        const label = event.target.dataset.label;
        const propertyDocId = event.target.dataset.propertyDocId;
        const contentDocId = event.target.dataset.contentDocId;
        
        // Browser confirmation dialog
        const confirmed = window.confirm(
            `⚠️ WARNING: This will permanently delete this document.\n\n` +
            `This action cannot be undone. Do you want to proceed?`
        );
        
        if (confirmed) {
            this.deleteDocument(propertyDocId, contentDocId, label);
        }
    }

    deleteDocument(propertyDocId, contentDocId, label) {
        this.loading = true;
        
        deletePropertyDocument({ propertyDocumentId: propertyDocId })
            .then(() => {
                this.showToast('Success', 'Document deleted successfully', 'success');
                
                // Remove from documents array
                this.items = this.items.map(item => {
                    if (item.label === label) {
                        const updatedDocs = item.documents.filter(
                            doc => doc.contentDocumentId !== contentDocId
                        );
                        
                        return {
                            ...item,
                            documents: updatedDocs,
                            uploaded: updatedDocs.length > 0,
                            iconName: updatedDocs.length > 0 ? 'utility:check' : 
                                     (item.checked ? 'utility:close' : 'utility:document')
                        };
                    }
                    return item;
                });
                
                this.loading = false;
            })
            .catch(err => {
                this.loading = false;
                this.showToast('Error', err.body?.message || 'Failed to delete document', 'error');
            });
    }

    handleVerifyAll() {
        const missing = this.items.filter(i => i.checked && !i.uploaded);

        if (missing.length === 0)
            this.showToast('All Good', 'All required documents uploaded', 'success');
        else
            this.showToast(
                'Missing Documents',
                missing.map(i => i.label).join(', '),
                'warning'
            );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}