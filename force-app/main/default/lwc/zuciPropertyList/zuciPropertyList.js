import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getProperties from '@salesforce/apex/ZuciPortalController.getProperties';
import getPropertyById from '@salesforce/apex/ZuciPortalController.getPropertyById';
import getActivitiesForProperty from '@salesforce/apex/ZuciPortalController.getActivitiesForProperty';
import getSiteVisitsForProperty from '@salesforce/apex/ZuciPortalController.getSiteVisitsForProperty';
import getLeadsForProperty from '@salesforce/apex/ZuciPortalController.getLeadsForProperty';

const PAGE_SIZE   = 10;
const PREVIEW_MAX = 2;

export default class ZuciPropertyList extends LightningElement {

    // ── List state ────────────────────────────────────
    @track isLoading   = true;
    @track searchKey   = '';
    @track records     = [];
    @track currentPage = 1;
    wiredResult;

    // ── Detail state ──────────────────────────────────
    @track showDetail          = false;
    @track selectedRecordId    = null;
    @track detailProperty      = null;
    @track isDetailLoading     = true;
    @track activities          = [];
    @track siteVisits          = [];
    @track leads               = [];
    @track isActivitiesLoading = true;
    @track isSiteVisitsLoading = true;
    @track isLeadsLoading      = true;

    // ── Modal state ───────────────────────────────────
    @track showNewPropertyModal   = false;
    @track showEditPropertyModal  = false;
    @track showActivityModal      = false;
    @track showActivityDropdown   = false;
    @track showSiteVisitModal     = false;
    @track showAllActivitiesModal = false;
    @track showAllSiteVisitsModal = false;
    @track showAllLeadsModal      = false;
    @track editingActivityId      = null;
    @track editingSiteVisitId     = null;
    @track selectedActivityType   = 'Task';

    // ─────────────────────────────────────────────────
    // LIST: wire
    // ─────────────────────────────────────────────────
    @wire(getProperties)
    wiredProperties(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.records = result.data.map(rec => this.mapPropertyRow(rec));
        }
    }

    mapPropertyRow(rec) {
        return {
            ...rec,
            parentProjectName: (rec.Parent_Property__r && rec.Parent_Property__r.Name)
                                ? rec.Parent_Property__r.Name : '—',
            recordTypeName:    (rec.RecordType && rec.RecordType.Name)
                                ? rec.RecordType.Name : '—',
            formattedPrice:    this.formatPrice(rec.Asking_Price__c),
            Configuration__c:  rec.Configuration__c || '—',
            Facing__c:         rec.Facing__c        || '—',
            Position__c:       rec.Position__c      || '',
            statusStyle:       this.getStatusStyle(rec.Position__c || '')
        };
    }

    getStatusStyle(status) {
        const map = {
            'Available':          'background:#d1fae5;color:#065f46',
            'Self Occupied':      'background:#fef3c7;color:#92400e',
            'Sold':               'background:#fee2e2;color:#991b1b',
            'Rented':             'background:#dbeafe;color:#1e40af',
            'Under Construction': 'background:#ede9fe;color:#5b21b6'
        };
        return map[status] || 'background:#f3f4f6;color:#374151';
    }

    getLeadStatusStyle(status) {
        const map = {
            'Open':                    'background:#dbeafe;color:#1e40af',
            'Call done with customer': 'background:#dbeafe;color:#1e40af',
            'Interested':              'background:#ede9fe;color:#5b21b6',
            'Site Visit Scheduled':    'background:#fef3c7;color:#92400e',
            'Closed - Converted':      'background:#d1fae5;color:#065f46',
            'Not Interested':          'background:#fee2e2;color:#991b1b'
        };
        return map[status] || 'background:#f3f4f6;color:#374151';
    }

    formatPrice(p) {
        if (!p) return '—';
        if (p >= 10000000) return '₹' + (p / 10000000).toFixed(2) + ' Cr';
        if (p >= 100000)   return '₹' + (p / 100000).toFixed(2) + ' L';
        return '₹' + p.toLocaleString('en-IN');
    }

    // ─────────────────────────────────────────────────
    // LIST: computed
    // ─────────────────────────────────────────────────
    get allFilteredRecords() {
        if (!this.searchKey) return this.records;
        const key = this.searchKey.toLowerCase();
        return this.records.filter(r =>
            (r.Name               && r.Name.toLowerCase().includes(key))               ||
            (r.Position__c        && r.Position__c.toLowerCase().includes(key))        ||
            (r.parentProjectName  && r.parentProjectName.toLowerCase().includes(key))  ||
            (r.recordTypeName     && r.recordTypeName.toLowerCase().includes(key))     ||
            (r.Configuration__c   && r.Configuration__c.toLowerCase().includes(key))
        );
    }

    get pagedRecords()  { const s = (this.currentPage - 1) * PAGE_SIZE; return this.allFilteredRecords.slice(s, s + PAGE_SIZE); }
    get hasRecords()    { return this.allFilteredRecords.length > 0; }
    get totalCount()    { return this.allFilteredRecords.length; }
    get totalPages()    { return Math.max(1, Math.ceil(this.totalCount / PAGE_SIZE)); }
    get isFirstPage()   { return this.currentPage === 1; }
    get isLastPage()    { return this.currentPage >= this.totalPages; }
    get pageInfo() {
        const start = Math.min((this.currentPage - 1) * PAGE_SIZE + 1, this.totalCount);
        const end   = Math.min(this.currentPage * PAGE_SIZE, this.totalCount);
        return `${start}–${end} of ${this.totalCount}`;
    }

    // ─────────────────────────────────────────────────
    // LIST: handlers
    // ─────────────────────────────────────────────────
    handleSearch(event) { this.searchKey = event.target.value; this.currentPage = 1; }
    handlePrevPage()    { if (!this.isFirstPage) this.currentPage -= 1; }
    handleNextPage()    { if (!this.isLastPage)  this.currentPage += 1; }

    handleNew() { this.showNewPropertyModal = true; }
    handleCloseNewPropertyModal() { this.showNewPropertyModal = false; }
    handleNewPropertySaved() {
        this.showNewPropertyModal = false;
        this.showToast('Success', 'Property created successfully.', 'success');
        refreshApex(this.wiredResult);
    }

    handleEditInline(event) {
        this.selectedRecordId    = event.currentTarget.dataset.id;
        this.showEditPropertyModal = true;
    }
    handleNameClick(event) {
        this.openDetail(event.currentTarget.dataset.id);
    }

    // ─────────────────────────────────────────────────
    // DETAIL: open + fetch
    // ─────────────────────────────────────────────────
    openDetail(recordId) {
        this.selectedRecordId    = recordId;
        this.showDetail          = true;
        this.isDetailLoading     = true;
        this.isActivitiesLoading = true;
        this.isSiteVisitsLoading = true;
        this.isLeadsLoading      = true;
        this.detailProperty      = null;
        this.activities          = [];
        this.siteVisits          = [];
        this.leads               = [];
        this.showActivityDropdown = false;
        this.fetchPropertyDetail(recordId);
        this.fetchActivities(recordId);
        this.fetchSiteVisits(recordId);
        this.fetchLeads(recordId);
    }

    fetchPropertyDetail(recordId) {
        getPropertyById({ propertyId: recordId })
            .then(data  => { this.detailProperty = this.mapPropertyDetail(data); this.isDetailLoading = false; })
            .catch(err  => { console.error('getPropertyById', err); this.isDetailLoading = false; });
    }

    fetchActivities(recordId) {
        getActivitiesForProperty({ propertyId: recordId })
            .then(data => {
                this.activities = (data || []).map(a => {
                    const isEvent = a.RecordType === 'Event';
                    const isCall  = a.RecordType === 'Task' && !!a.CallType;
                    return {
                        ...a,
                        Subject:       a.Subject || '(No Subject)',
                        formattedDate: this.formatDate(isEvent ? a.StartDateTime : (a.ActivityDate || a.CreatedDate)),
                        iconName:      isEvent ? 'utility:event' : isCall ? 'utility:call' : 'utility:task',
                        typeBadge:     isEvent ? 'Event' : isCall ? 'Call' : 'Task',
                        isSynced:      a.IsRecurrence || false
                    };
                });
                this.isActivitiesLoading = false;
            })
            .catch(err => { console.error('getActivitiesForProperty', err); this.isActivitiesLoading = false; });
    }

    fetchSiteVisits(recordId) {
        getSiteVisitsForProperty({ propertyId: recordId })
            .then(data => {
                this.siteVisits = (data || []).map(sv => ({
                    ...sv,
                    leadName:      (sv.CustomLead__r && sv.CustomLead__r.Full_Name__c) ? sv.CustomLead__r.Full_Name__c : '',
                    managerName:   (sv.Property_Manager1__r && sv.Property_Manager1__r.Name) ? sv.Property_Manager1__r.Name : '',
                    formattedDate: this.formatDate(sv.Visit_Date_Time__c),
                    statusStyle:   this.getVisitStatusStyle(sv.Status__c || '')
                }));
                this.isSiteVisitsLoading = false;
            })
            .catch(err => { console.error('getSiteVisitsForProperty', err); this.isSiteVisitsLoading = false; });
    }

    fetchLeads(recordId) {
        getLeadsForProperty({ propertyId: recordId })
            .then(data => {
                this.leads = (data || []).map(lead => ({
                    ...lead,
                    Full_Name__c:  lead.Full_Name__c  || '—',
                    Phone__c:      lead.Phone__c      || '',
                    Lead_Status__c: lead.Lead_Status__c || '',
                    statusStyle:   this.getLeadStatusStyle(lead.Lead_Status__c || '')
                }));
                this.isLeadsLoading = false;
            })
            .catch(err => { console.error('getLeadsForProperty', err); this.isLeadsLoading = false; });
    }

    mapPropertyDetail(data) {
        return {
            Id:                data.Id               || '',
            Name:              data.Name             || '—',
            Position__c:       data.Position__c      || '',
            Configuration__c:  data.Configuration__c || '—',
            Facing__c:         data.Facing__c        || '—',
            Floor__c:          data.Floor__c         || '—',
            Area__c:           data.Area__c          || null,
            Asking_Price__c:   data.Asking_Price__c  || null,
            formattedPrice:    this.formatPrice(data.Asking_Price__c),
            formattedArea:     data.Area__c ? data.Area__c + ' sq.ft' : '—',
            parentProjectName: (data.Parent_Property__r && data.Parent_Property__r.Name)
                                ? data.Parent_Property__r.Name : '—',
            recordTypeName:    (data.RecordType && data.RecordType.Name)
                                ? data.RecordType.Name : '',
            statusStyle:       this.getStatusStyle(data.Position__c || '')
        };
    }

    // ─────────────────────────────────────────────────
    // DETAIL: computed
    // ─────────────────────────────────────────────────
    get hasDetailProperty()   { return !!this.detailProperty; }
    get detailPropertyName()  { return this.detailProperty ? (this.detailProperty.Name || '—') : ''; }

    // Activities
    get visibleActivities()      { return this.activities.slice(0, PREVIEW_MAX); }
    get hasActivities()          { return this.activities.length > 0; }
    get activityCount()          { return this.activities.length; }
    get hasMoreActivities()      { return this.activities.length > PREVIEW_MAX; }
    get viewAllActivitiesLabel() { return `VIEW ALL ${this.activities.length} ACTIVITIES`; }

    // Site Visits
    get visibleSiteVisits()      { return this.siteVisits.slice(0, PREVIEW_MAX); }
    get hasSiteVisits()          { return this.siteVisits.length > 0; }
    get siteVisitCount()         { return this.siteVisits.length; }
    get hasMoreSiteVisits()      { return this.siteVisits.length > PREVIEW_MAX; }
    get viewAllSiteVisitsLabel() { return `VIEW ALL ${this.siteVisits.length} SITE VISITS`; }

    // Leads
    get visibleLeads()           { return this.leads.slice(0, PREVIEW_MAX); }
    get hasLeads()               { return this.leads.length > 0; }
    get leadCount()              { return this.leads.length; }
    get hasMoreLeads()           { return this.leads.length > PREVIEW_MAX; }
    get viewAllLeadsLabel()      { return `VIEW ALL ${this.leads.length} LEADS`; }

    // Activity modal helpers
    get activityWhatId()     { return this.selectedRecordId; }
    get isEventType()        { return this.selectedActivityType === 'Event'; }
    get isCallType()         { return this.selectedActivityType === 'Call'; }
    get activityModalTitle() {
        if (this.editingActivityId) return 'Edit Activity';
        return this.selectedActivityType === 'Event' ? 'New Event' : 'Log a Call';
    }

    // ─────────────────────────────────────────────────
    // DETAIL: handlers
    // ─────────────────────────────────────────────────
    handleBackToList() {
        this.showDetail           = false;
        this.selectedRecordId     = null;
        this.detailProperty       = null;
        this.showActivityDropdown = false;
    }

    // ── Edit Property ─────────────────────────────────
    handleEditProperty()           { this.showEditPropertyModal = true; }
    handleCloseEditPropertyModal() { this.showEditPropertyModal = false; }
    handleEditPropertySaved() {
        this.showEditPropertyModal = false;
        this.showToast('Success', 'Property updated successfully.', 'success');
        this.isDetailLoading = true;
        this.fetchPropertyDetail(this.selectedRecordId);
    }

    // ── View All ──────────────────────────────────────
    handleViewAllActivities()  { this.showAllActivitiesModal = true; }
    handleCloseAllActivities() { this.showAllActivitiesModal = false; }
    handleViewAllSiteVisits()  { this.showAllSiteVisitsModal = true; }
    handleCloseAllSiteVisits() { this.showAllSiteVisitsModal = false; }
    handleViewAllLeads()       { this.showAllLeadsModal = true; }
    handleCloseAllLeads()      { this.showAllLeadsModal = false; }

    // ── New Activity ──────────────────────────────────
    handleNewActivity() { this.showActivityDropdown = !this.showActivityDropdown; }
    handleActivityTypeSelect(event) {
        this.selectedActivityType = event.currentTarget.dataset.type;
        this.showActivityDropdown = false;
        this.editingActivityId    = null;
        this.showActivityModal    = true;
    }
    handleCloseActivityModal() { this.showActivityModal = false; this.editingActivityId = null; }
    handleActivitySaved() {
        this.showActivityModal = false;
        this.editingActivityId = null;
        this.showToast('Success', 'Activity saved successfully.', 'success');
        this.isActivitiesLoading = true;
        this.fetchActivities(this.selectedRecordId);
    }

    // ── Edit Activity ─────────────────────────────────
    handleEditActivity(event) {
        this.editingActivityId = event.currentTarget.dataset.id;
        this.showActivityModal = true;
    }
    handleEditActivityFromModal(event) {
        this.showAllActivitiesModal = false;
        this.editingActivityId      = event.currentTarget.dataset.id;
        this.showActivityModal      = true;
    }

    // ── New/Edit Site Visit ───────────────────────────
    handleNewSiteVisit()        { this.editingSiteVisitId = null; this.showSiteVisitModal = true; }
    handleCloseSiteVisitModal() { this.showSiteVisitModal = false; this.editingSiteVisitId = null; }
    handleSiteVisitSaved() {
        this.showSiteVisitModal  = false;
        this.editingSiteVisitId  = null;
        this.showToast('Success', 'Site visit saved successfully.', 'success');
        this.isSiteVisitsLoading = true;
        this.fetchSiteVisits(this.selectedRecordId);
    }
    handleEditSiteVisit(event) {
        this.editingSiteVisitId = event.currentTarget.dataset.id;
        this.showSiteVisitModal = true;
    }
    handleEditSiteVisitFromModal(event) {
        this.showAllSiteVisitsModal = false;
        this.editingSiteVisitId     = event.currentTarget.dataset.id;
        this.showSiteVisitModal     = true;
    }

    handleFormError(event) {
        const msg = (event.detail && event.detail.detail) ? event.detail.detail : 'Something went wrong.';
        this.showToast('Error', msg, 'error');
    }

    // ─────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    formatDate(dateStr) {
        if (!dateStr) return '—';
        return new Date(dateStr).toLocaleString('en-IN', {
            year: 'numeric', month: 'short', day: '2-digit',
            hour: '2-digit', minute: '2-digit', hour12: true
        });
    }

    getVisitStatusStyle(status) {
        const map = {
            'Scheduled': 'background:#fef3c7;color:#92400e',
            'Completed': 'background:#d1fae5;color:#065f46',
            'Cancelled': 'background:#fee2e2;color:#991b1b'
        };
        return map[status] || 'background:#f3f4f6;color:#374151';
    }
}