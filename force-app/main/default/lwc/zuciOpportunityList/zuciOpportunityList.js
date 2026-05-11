import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpportunities from '@salesforce/apex/ZuciPortalController.getOpportunities';
import { NavigationMixin } from 'lightning/navigation';

const PAGE_SIZE = 10;

export default class ZuciOpportunityList extends NavigationMixin(LightningElement) {
    @track isLoading    = true;
    @track searchKey    = '';
    @track records      = [];
    @track currentPage  = 1;
    wiredResult;

    @wire(getOpportunities)
    wiredOpportunities(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.records = result.data.map(rec => ({
                ...rec,
                stageStyle:      this.getStageStyle(rec.Stage__c),
                formattedAmount: this.formatAmount(rec.Amount__c),
                propertyName:    rec.Property__r ? rec.Property__r.Name : '—'
            }));
        }
    }

    getStageStyle(stage) {
        const map = {
            'Prospecting':   'background:#dbeafe;color:#1e40af',
            'Qualification': 'background:#ede9fe;color:#5b21b6',
            'Proposal':      'background:#fef3c7;color:#92400e',
            'Negotiation':   'background:#ffedd5;color:#9a3412',
            'Closed Won':    'background:#d1fae5;color:#065f46',
            'Closed Lost':   'background:#fee2e2;color:#991b1b'
        };
        return map[stage] || 'background:#f3f4f6;color:#374151';
    }

    formatAmount(amount) {
        if (!amount) return '—';
        if (amount >= 10000000) return '₹' + (amount / 10000000).toFixed(2) + ' Cr';
        if (amount >= 100000)   return '₹' + (amount / 100000).toFixed(2) + ' L';
        return '₹' + amount.toLocaleString('en-IN');
    }

    get allFilteredRecords() {
        if (!this.searchKey) return this.records;
        const key = this.searchKey.toLowerCase();
        return this.records.filter(r =>
            (r.Name         && r.Name.toLowerCase().includes(key))         ||
            (r.Stage__c     && r.Stage__c.toLowerCase().includes(key))     ||
            (r.propertyName && r.propertyName.toLowerCase().includes(key))
        );
    }

    get pagedRecords() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        return this.allFilteredRecords.slice(start, start + PAGE_SIZE);
    }

    get hasRecords()  { return this.allFilteredRecords.length > 0; }
    get totalCount()  { return this.allFilteredRecords.length; }
    get totalPages()  { return Math.max(1, Math.ceil(this.totalCount / PAGE_SIZE)); }
    get isFirstPage() { return this.currentPage === 1; }
    get isLastPage()  { return this.currentPage >= this.totalPages; }

    get pageInfo() {
        const start = Math.min((this.currentPage - 1) * PAGE_SIZE + 1, this.totalCount);
        const end   = Math.min(this.currentPage * PAGE_SIZE, this.totalCount);
        return `${start}–${end} of ${this.totalCount}`;
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.currentPage = 1;
    }

    handlePrevPage() { if (!this.isFirstPage) this.currentPage -= 1; }
    handleNextPage() { if (!this.isLastPage)  this.currentPage += 1; }

    handleNew() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity__c',
                actionName: 'new'
            }
        });
    }

    handleEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity__c',
                actionName: 'edit'
            }
        });
    }

    handleRecordSaved() {
        this.isLoading = true;
        refreshApex(this.wiredResult).then(() => { this.isLoading = false; });
    }
}