import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedDocuments from '@salesforce/apex/DocumentSlideshowController.getRelatedDocuments';
import { NavigationMixin } from 'lightning/navigation';

export default class DocumentSlideshow extends NavigationMixin(LightningElement) {
    @api recordId;
    
    documents = [];
    currentIndex = 0;
    isPlaying = true;
    intervalId;
    isLoading = true;
    error;

    get currentDocument() {
        return this.documents.length > 0 ? this.documents[this.currentIndex] : null;
    }

    get isImage() {
        if (!this.currentDocument) return false;
        const ext = this.currentDocument.fileExtension.toLowerCase();
        return ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'svg'].includes(ext);
    }

    get isPdf() {
        if (!this.currentDocument) return false;
        return this.currentDocument.fileExtension.toLowerCase() === 'pdf';
    }

    get isDocument() {
        if (!this.currentDocument) return false;
        const ext = this.currentDocument.fileExtension.toLowerCase();
        return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv'].includes(ext);
    }

    get hasDocuments() {
        return this.documents.length > 0;
    }

    get playPauseIcon() {
        return this.isPlaying ? 'utility:pause' : 'utility:play';
    }

    get playPauseLabel() {
        return this.isPlaying ? 'Pause' : 'Play';
    }

    get currentPosition() {
        return this.documents.length > 0 ? `${this.currentIndex + 1} / ${this.documents.length}` : '0 / 0';
    }

    get hasPrevious() {
        return this.currentIndex > 0;
    }

    get hasNext() {
        return this.currentIndex < this.documents.length - 1;
    }

    get disablePrevious() {
        return !this.hasPrevious;
    }

    get disableNext() {
        return !this.hasNext;
    }

    connectedCallback() {
        this.loadDocuments();
    }

    disconnectedCallback() {
        this.stopSlideshow();
    }

    loadDocuments() {
        getRelatedDocuments({ recordId: this.recordId })
            .then(data => {
                // Add dotClass to each document
                this.documents = data.map((doc, index) => ({
                    ...doc,
                    dotClass: index === this.currentIndex ? 'dot active' : 'dot'
                }));
                this.isLoading = false;
                this.error = undefined;
                
                if (this.documents.length > 0 && this.isPlaying) {
                    this.startSlideshow();
                }
            })
            .catch(error => {
                this.error = error.body?.message || 'Error loading documents';
                this.isLoading = false;
                this.showToast('Error', this.error, 'error');
            });
    }

    startSlideshow() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
        
        this.intervalId = setInterval(() => {
            if (this.currentIndex < this.documents.length - 1) {
                this.currentIndex++;
            } else {
                this.currentIndex = 0; // Loop back to first
            }
            this.updateDotClasses();
        }, 5000); // 5 seconds
    }

    stopSlideshow() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
    }

    handlePlayPause() {
        this.isPlaying = !this.isPlaying;
        
        if (this.isPlaying) {
            this.startSlideshow();
        } else {
            this.stopSlideshow();
        }
    }

    handlePrevious() {
        if (this.currentIndex > 0) {
            this.currentIndex--;
            this.updateDotClasses();
            this.resetSlideshow();
        }
    }

    handleNext() {
        if (this.currentIndex < this.documents.length - 1) {
            this.currentIndex++;
        } else {
            this.currentIndex = 0; // Loop back to first
        }
        this.updateDotClasses();
        this.resetSlideshow();
    }

    resetSlideshow() {
        if (this.isPlaying) {
            this.stopSlideshow();
            this.startSlideshow();
        }
    }

    handleDocumentClick() {
        if (this.currentDocument) {
            // Navigate to file preview with all document IDs for navigation
            const recordIds = this.documents.map(doc => doc.contentDocumentId).join(',');
            
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: this.currentDocument.contentDocumentId,
                    recordIds: recordIds
                }
            });
        }
    }

    handleDotClick(event) {
        const index = parseInt(event.target.dataset.index, 10);
        if (index !== undefined && index !== this.currentIndex) {
            this.currentIndex = index;
            this.updateDotClasses();
            this.resetSlideshow();
        }
    }

    updateDotClasses() {
        this.documents = this.documents.map((doc, index) => ({
            ...doc,
            dotClass: index === this.currentIndex ? 'dot active' : 'dot'
        }));
    }

    handleDownload() {
        if (this.currentDocument) {
            window.open(`/sfc/servlet.shepherd/document/download/${this.currentDocument.contentDocumentId}`, '_blank');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}