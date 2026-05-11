import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getChecklistDocuments
    from '@salesforce/apex/DocumentChecklistSlideshowController.getChecklistDocuments';

export default class DocumentChecklistSlideshow extends NavigationMixin(LightningElement) {

    @api recordId; // Document_CheckList__c Id

    documents = [];
    currentIndex = 0;
    isPlaying = true;
    intervalId;
    isLoading = true;
    error;

    connectedCallback() {
        this.loadDocuments();
    }

    disconnectedCallback() {
        this.stopSlideshow();
    }

    loadDocuments() {
        getChecklistDocuments({ checklistId: this.recordId })
            .then(data => {
                this.documents = data.map((doc, index) => ({
                    ...doc,
                    dotClass: index === 0 ? 'dot active' : 'dot'
                }));
                this.isLoading = false;

                if (this.documents.length > 0) {
                    this.startSlideshow();
                }
            })
            .catch(err => {
                this.error = err.body?.message || 'Error loading documents';
                this.isLoading = false;
            });
    }

    /* ================= GETTERS ================= */

    get hasDocuments() {
        return this.documents.length > 0;
    }

    get currentDocument() {
        return this.documents[this.currentIndex];
    }

    get isImage() {
        return this.currentDocument &&
            ['png','jpg','jpeg','gif','bmp','svg']
                .includes(this.currentDocument.fileExtension?.toLowerCase());
    }

    get isPdf() {
        return this.currentDocument &&
            this.currentDocument.fileExtension?.toLowerCase() === 'pdf';
    }

    get playPauseIcon() {
        return this.isPlaying ? 'utility:pause' : 'utility:play';
    }

    get currentPosition() {
        return `${this.currentIndex + 1} / ${this.documents.length}`;
    }

    /* ================= SLIDESHOW ================= */

    startSlideshow() {
        this.stopSlideshow();
        this.intervalId = setInterval(() => {
            this.currentIndex =
                this.currentIndex < this.documents.length - 1
                    ? this.currentIndex + 1
                    : 0;
            this.updateDots();
        }, 5000);
    }

    stopSlideshow() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
    }

    togglePlayPause() {
        this.isPlaying = !this.isPlaying;
        this.isPlaying ? this.startSlideshow() : this.stopSlideshow();
    }

    previous() {
        this.currentIndex =
            this.currentIndex > 0
                ? this.currentIndex - 1
                : this.documents.length - 1;
        this.updateDots();
        this.restartIfPlaying();
    }

    next() {
        this.currentIndex =
            this.currentIndex < this.documents.length - 1
                ? this.currentIndex + 1
                : 0;
        this.updateDots();
        this.restartIfPlaying();
    }

    restartIfPlaying() {
        if (this.isPlaying) {
            this.startSlideshow();
        }
    }

    updateDots() {
        this.documents = this.documents.map((doc, index) => ({
            ...doc,
            dotClass: index === this.currentIndex ? 'dot active' : 'dot'
        }));
    }

    /* ================= ACTIONS ================= */

    previewFile() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: {
                selectedRecordId: this.currentDocument.contentDocumentId,
                recordIds: this.documents.map(d => d.contentDocumentId).join(',')
            }
        });
    }

    downloadFile() {
        window.open(this.currentDocument.downloadUrl, '_blank');
    }

    dotClick(event) {
        this.currentIndex = Number(event.target.dataset.index);
        this.updateDots();
        this.restartIfPlaying();
    }
}