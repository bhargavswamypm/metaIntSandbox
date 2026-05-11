import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeads from '@salesforce/apex/ZuciPortalController.getLeads';
import getLeadById from '@salesforce/apex/ZuciPortalController.getLeadById';
import getActivitiesForLead from '@salesforce/apex/ZuciPortalController.getActivitiesForLead';
import getSiteVisitsForLead from '@salesforce/apex/ZuciPortalController.getSiteVisitsForLead';

const PAGE_SIZE   = 10;
const PREVIEW_MAX = 2;

const PIPELINE_STAGES = [
    { value: 'Open',                    label: 'OPEN' },
    { value: 'Call done with customer', label: 'CALL DONE' },
    { value: 'Interested',              label: 'Interested' },
    { value: 'Not Interested',          label: 'Not Interested' },
    { value: 'Site Visit Scheduled',    label: 'SITE VISIT' },
    { value: 'Needs Time',              label: 'Needs Time' },
    { value: 'Follow Up',               label: 'Follow Up' },
    { value: 'Closed - Converted',      label: 'CONVERTED' }
];

export default class ZuciLeadList extends LightningElement {

    // ── List state ────────────────────────────────────
    @track isLoading    = true;
    @track searchKey    = '';
    @track records      = [];
    @track currentPage  = 1;
    wiredResult;

    // ── Detail state ──────────────────────────────────
    @track showDetail          = false;
    @track selectedRecordId    = null;
    @track detailLead          = null;
    @track isDetailLoading     = true;
    @track activities          = [];
    @track siteVisits          = [];
    @track isActivitiesLoading = true;
    @track isSiteVisitsLoading = true;
    @track showAllActivities      = false;
    @track showAllSiteVisits      = false;
    @track showAllActivitiesModal = false;
    @track showAllSiteVisitsModal = false;

    // ── Modal state ───────────────────────────────────
    @track showNewLeadModal       = false;
    @track showEditLeadModal      = false;
    @track showActivityModal      = false;
    @track showActivityDropdown   = false;
    @track showSiteVisitModal     = false;
    @track showEditActivityModal  = false;
    @track showEditSiteVisitModal = false;
    @track editingActivityId      = null;
    @track editingSiteVisitId     = null;
    @track selectedActivityType   = 'Task';

    // ─────────────────────────────────────────────────
    // LIST: wire
    // ─────────────────────────────────────────────────
    @wire(getLeads)
    wiredLeads(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.records = result.data.map(rec => ({
                ...rec,
                Full_Name__c:     rec.Full_Name__c     || '—',
                Email__c:         rec.Email__c         || '—',
                Phone__c:         rec.Phone__c         || '—',
                Lead_Status__c:   rec.Lead_Status__c   || '',
                Lead_Source__c:   rec.Lead_Source__c   || '—',
                Configuration__c: rec.Configuration__c || '—',
                propertyName:     (rec.Property_Interested_in__r && rec.Property_Interested_in__r.Name)
                                    ? rec.Property_Interested_in__r.Name : '—',
                statusStyle:      this.getStatusStyle(rec.Lead_Status__c || '')
            }));
        }
    }

    getStatusStyle(status) {
        const map = {
            'Open':                    'background:#dbeafe;color:#1e40af',
            'Call done with customer': 'background:#dbeafe;color:#1e40af',
            'Interested':              'background:#ede9fe;color:#5b21b6',
            'Site Visit Scheduled':    'background:#fef3c7;color:#92400e',
            'Meeting Scheduled':       'background:#fef3c7;color:#92400e',
            'Token Advance':           'background:#fef3c7;color:#92400e',
            'Closed - Converted':      'background:#d1fae5;color:#065f46',
            'Not Interested':          'background:#fee2e2;color:#991b1b'
        };
        return map[status] || 'background:#f3f4f6;color:#374151';
    }

    // ─────────────────────────────────────────────────
    // LIST: computed
    // ─────────────────────────────────────────────────
    get allFilteredRecords() {
        if (!this.searchKey) return this.records;
        const key = this.searchKey.toLowerCase();
        return this.records.filter(r =>
            (r.Full_Name__c     ? r.Full_Name__c.toLowerCase().includes(key)     : false) ||
            (r.Email__c         ? r.Email__c.toLowerCase().includes(key)         : false) ||
            (r.Phone__c         ? r.Phone__c.toLowerCase().includes(key)         : false) ||
            (r.Lead_Source__c   ? r.Lead_Source__c.toLowerCase().includes(key)   : false) ||
            (r.Configuration__c ? r.Configuration__c.toLowerCase().includes(key) : false) ||
            (r.Lead_Status__c   ? r.Lead_Status__c.toLowerCase().includes(key)   : false) ||
            (r.propertyName     ? r.propertyName.toLowerCase().includes(key)     : false)
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

    // ─────────────────────────────────────────────────
    // LIST: handlers
    // ─────────────────────────────────────────────────
    handleSearch(event) { this.searchKey = event.target.value; this.currentPage = 1; }
    handlePrevPage()    { if (!this.isFirstPage) this.currentPage -= 1; }
    handleNextPage()    { if (!this.isLastPage)  this.currentPage += 1; }

    handleNew() {
        this.showNewLeadModal = true;
    }
    handleCloseNewLeadModal() {
        this.showNewLeadModal = false;
    }
    handleNewLeadSaved() {
        this.showNewLeadModal = false;
        this.showToast('Success', 'Lead created successfully.', 'success');
        // re-wire will auto refresh since getLeads is wired
    }
    handleEdit(event) {
        const recordId = event.currentTarget.dataset.id;
        window.open(`${window.location.origin}/lightning/r/Lead__c/${recordId}/edit`, '_blank');
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
        this.detailLead          = null;
        this.activities          = [];
        this.siteVisits          = [];
        this.showAllActivities   = false;
        this.showAllSiteVisits   = false;
        this.fetchLeadDetail(recordId);
        this.fetchActivities(recordId);
        this.fetchSiteVisits(recordId);
    }

    fetchLeadDetail(recordId) {
        getLeadById({ leadId: recordId })
            .then(data  => { this.detailLead = this.mapLead(data); this.isDetailLoading = false; })
            .catch(err  => { console.error('getLeadById', err);    this.isDetailLoading = false; });
    }

    fetchActivities(recordId) {
        getActivitiesForLead({ leadId: recordId })
            .then(data => {
                this.activities = (data || []).map(a => {
                    const isEvent = a.RecordType === 'Event';
                    const isCall  = a.RecordType === 'Task' && !!a.CallType;
                    return {
                        ...a,
                        Subject:       a.Subject  || '(No Subject)',
                        Priority:      a.Priority || '',
                        formattedDate: this.formatDate(
                            isEvent ? a.StartDateTime : (a.ActivityDate || a.CreatedDate)
                        ),
                        iconName:      isEvent ? 'utility:event'
                                     : isCall  ? 'utility:call'
                                     : 'utility:task',
                        typeBadge:     isEvent ? 'Event' : isCall ? 'Call' : 'Task',
                        isSynced:      a.IsRecurrence || false,
                        priorityStyle: this.getPriorityStyle(a.Priority || 'Normal')
                    };
                });
                this.isActivitiesLoading = false;
            })
            .catch(err => { console.error('getActivitiesForLead', err); this.isActivitiesLoading = false; });
    }

    fetchSiteVisits(recordId) {
        getSiteVisitsForLead({ leadId: recordId })
            .then(data => {
                this.siteVisits = (data || []).map(sv => ({
                    ...sv,
                    Name:            sv.Name            || '—',
                    Status__c: sv.Status__c || '',
                    propertyName:    (sv.Property__r && sv.Property__r.Name) ? sv.Property__r.Name : '',
                    managerName:     (sv.Property_Manager1__r && sv.Property_Manager1__r.Name) ? sv.Property_Manager1__r.Name : '',
                    formattedDate:   this.formatDate(sv.Visit_Date_Time__c),
                    statusStyle:     this.getVisitStatusStyle(sv.Status__c || '')
                }));
                this.isSiteVisitsLoading = false;
            })
            .catch(err => { console.error('getSiteVisitsForLead', err); this.isSiteVisitsLoading = false; });
    }

    mapLead(data) {
        return {
            Id:                        data.Id || '',
            Full_Name__c:              data.Full_Name__c              || '—',
            Email__c:                  data.Email__c                  || '—',
            Phone__c:                  data.Phone__c                  || '—',
            Lead_Status__c:            data.Lead_Status__c            || '',
            Lead_Source__c:            data.Lead_Source__c            || '—',
            Configuration__c:          data.Configuration__c          || '—',
            Property_Interested_in__c: data.Property_Interested_in__c || '',
            propertyName:              (data.Property_Interested_in__r && data.Property_Interested_in__r.Name)
                                        ? data.Property_Interested_in__r.Name : '—'
        };
    }

    // ─────────────────────────────────────────────────
    // DETAIL: computed
    // ─────────────────────────────────────────────────
    get pipelineStages() {
        if (!this.detailLead) return [];
        const currentStatus = this.detailLead.Lead_Status__c || '';
        const currentIdx    = PIPELINE_STAGES.findIndex(s => s.value === currentStatus);
        return PIPELINE_STAGES.map((s, i) => ({
            ...s,
            isDone:      i < currentIdx,
            isActive:    i === currentIdx,
            circleClass: i < currentIdx    ? 'pipeline-circle done'
                       : i === currentIdx  ? 'pipeline-circle active'
                       : 'pipeline-circle future',
            lineClass:   i === 0           ? 'pipeline-line hidden'
                       : i <= currentIdx   ? 'pipeline-line filled'
                       : 'pipeline-line empty'
        }));
    }

    get pipelinePercent() {
        if (!this.detailLead) return 0;
        const idx = PIPELINE_STAGES.findIndex(s => s.value === (this.detailLead.Lead_Status__c || ''));
        return idx < 0 ? 0 : Math.round((idx / (PIPELINE_STAGES.length - 1)) * 100);
    }

    get hasDetailLead()  { return !!this.detailLead; }
    get detailLeadName() { return this.detailLead ? (this.detailLead.Full_Name__c || '—') : ''; }

    // Activities: preview = first 3, view all = entire list
    get visibleActivities()     { return this.showAllActivities ? this.activities : this.activities.slice(0, PREVIEW_MAX); }
    get hasActivities()         { return this.activities.length > 0; }
    get activityCount()         { return this.activities.length; }
    get hasMoreActivities()     { return !this.showAllActivities && this.activities.length > PREVIEW_MAX; }
    get remainingActivityCount(){ return this.activities.length - PREVIEW_MAX; }

    // Site visits: preview = first 3, view all = entire list
    get visibleSiteVisits()     { return this.showAllSiteVisits ? this.siteVisits : this.siteVisits.slice(0, PREVIEW_MAX); }
    get hasSiteVisits()         { return this.siteVisits.length > 0; }
    get siteVisitCount()        { return this.siteVisits.length; }
    get hasMoreSiteVisits()     { return !this.showAllSiteVisits && this.siteVisits.length > PREVIEW_MAX; }
    get remainingSiteVisitCount(){ return this.siteVisits.length - PREVIEW_MAX; }

    get viewAllActivitiesLabel()  { return `VIEW ALL ${this.activities.length} ACTIVITIES`; }
    get viewAllSiteVisitsLabel()  { return `VIEW ALL ${this.siteVisits.length} SITE VISITS`; }

    get activityWhatId()     { return this.selectedRecordId; }
    get isEventType()        { return this.selectedActivityType === 'Event'; }
    get isCallType()         { return this.selectedActivityType === 'Call'; }
    get activityObjectName() { return this.selectedActivityType === 'Event' ? 'Event' : 'Task'; }
    get activityModalTitle() {
        if (this.editingActivityId) return 'Edit Activity';
        return this.selectedActivityType === 'Event' ? 'New Event' : 'Log a Call';
    }
    get siteVisitLeadId()   { return this.selectedRecordId; }
    get siteVisitPropertyId() {
        return (this.detailLead && this.detailLead.Property_Interested_in__c)
            ? this.detailLead.Property_Interested_in__c : '';
    }

    // ─────────────────────────────────────────────────
    // DETAIL: handlers
    // ─────────────────────────────────────────────────
    handleBackToList() {
        this.showDetail           = false;
        this.selectedRecordId     = null;
        this.detailLead           = null;
        this.showActivityDropdown = false;
        this.showAllActivities    = false;
        this.showAllSiteVisits    = false;
    }

    // ── View all toggles ──────────────────────────────
    handleViewAllActivities()      { this.showAllActivitiesModal = true; }
    handleCloseAllActivities()     { this.showAllActivitiesModal = false; }
    handleViewAllSiteVisits()      { this.showAllSiteVisitsModal = true; }
    handleCloseAllSiteVisits()     { this.showAllSiteVisitsModal = false; }
    handleCollapsActivities()      { this.showAllActivities = false; }
    handleCollapseSiteVisits()     { this.showAllSiteVisits = false; }

    // ── Edit Lead ─────────────────────────────────────
    handleEditLead()           { this.showEditLeadModal = true; }
    handleCloseEditLeadModal() { this.showEditLeadModal = false; }
    handleEditLeadSaved() {
        this.showEditLeadModal = false;
        this.showToast('Success', 'Lead updated successfully.', 'success');
        this.isDetailLoading = true;
        this.fetchLeadDetail(this.selectedRecordId);
    }

    // ── New Activity ──────────────────────────────────
    handleNewActivity()         { this.showActivityDropdown = !this.showActivityDropdown; }
    handleActivityTypeSelect(event) {
        this.selectedActivityType = event.currentTarget.dataset.type;
        this.showActivityDropdown = false;
        this.editingActivityId    = null;
        this.showActivityModal    = true;
    }
    handleCloseActivityModal()  { this.showActivityModal = false; this.editingActivityId = null; }
    handleActivitySaved() {
        this.showActivityModal = false;
        this.editingActivityId = null;
        this.showToast('Success', 'Activity saved successfully.', 'success');
        this.isActivitiesLoading = true;
        this.fetchActivities(this.selectedRecordId);
    }

    // ── Edit from view-all modal ─────────────────────
    handleEditActivityFromModal(event) {
        this.showAllActivitiesModal = false;
        this.editingActivityId      = event.currentTarget.dataset.id;
        this.showActivityModal      = true;
    }

    handleEditSiteVisitFromModal(event) {
        this.showAllSiteVisitsModal = false;
        this.editingSiteVisitId     = event.currentTarget.dataset.id;
        this.showSiteVisitModal     = true;
    }

    // ── Edit Activity ─────────────────────────────────
    handleEditActivity(event) {
        this.editingActivityId   = event.currentTarget.dataset.id;
        this.showActivityModal   = true;
    }

    // ── New Site Visit ────────────────────────────────
    handleNewSiteVisit()           { this.editingSiteVisitId = null; this.showSiteVisitModal = true; }
    handleCloseSiteVisitModal()    { this.showSiteVisitModal = false; this.editingSiteVisitId = null; }
    handleSiteVisitSaved() {
        this.showSiteVisitModal  = false;
        this.editingSiteVisitId  = null;
        this.showToast('Success', 'Site visit saved successfully.', 'success');
        this.isSiteVisitsLoading = true;
        this.fetchSiteVisits(this.selectedRecordId);
    }

    // ── Edit Site Visit ───────────────────────────────
    handleEditSiteVisit(event) {
        this.editingSiteVisitId = event.currentTarget.dataset.id;
        this.showSiteVisitModal = true;
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

    getPriorityStyle(priority) {
        const map = {
            'High':   'background:#fee2e2;color:#991b1b',
            'Normal': 'background:#f3f4f6;color:#374151',
            'Low':    'background:#d1fae5;color:#065f46'
        };
        return map[priority] || 'background:#f3f4f6;color:#374151';
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