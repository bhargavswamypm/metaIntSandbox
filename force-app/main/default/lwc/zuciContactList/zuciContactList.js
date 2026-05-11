import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getContacts from '@salesforce/apex/ZuciPortalController.getContacts';
import { NavigationMixin } from 'lightning/navigation';

const PAGE_SIZE = 10;

export default class ZuciContactList extends NavigationMixin(LightningElement) {
    @track isLoading    = true;
    @track searchKey    = '';
    @track records      = [];
    @track currentPage  = 1;
    wiredResult;

    @wire(getContacts)
    wiredContacts(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.records = result.data.map(rec => ({
                ...rec,
                accountName: rec.Account ? rec.Account.Name : '—'
            }));
        }
    }

    get allFilteredRecords() {
        if (!this.searchKey) return this.records;
        const key = this.searchKey.toLowerCase();
        return this.records.filter(r =>
            (r.Name        && r.Name.toLowerCase().includes(key))        ||
            (r.Email       && r.Email.toLowerCase().includes(key))       ||
            (r.MobilePhone && r.MobilePhone.toLowerCase().includes(key)) ||
            (r.MailingAddress && r.MailingAddress.toLowerCase().includes(key)) ||
            (r.Title       && r.Title.toLowerCase().includes(key))       ||
            (r.Department  && r.Department.toLowerCase().includes(key))
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
                objectApiName: 'Contact',
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
                objectApiName: 'Contact',
                actionName: 'edit'
            }
        });
    }

    handleRecordSaved() {
        this.isLoading = true;
        refreshApex(this.wiredResult).then(() => { this.isLoading = false; });
    }
}