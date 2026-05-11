import { LightningElement, api, track } from 'lwc';
import getAssignmentsData from '@salesforce/apex/PropertyAssignmentController.getAssignmentsData';
import getAssignedRecords from '@salesforce/apex/PropertyAssignmentController.getAssignedRecords';
import saveAssignments from '@salesforce/apex/PropertyAssignmentController.saveAssignments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PropertyAssignmentComponent extends LightningElement {
    @api recordId; // Property__c Id
    @track isEditMode = false;
    @track editingType = '';
    @track availableOptions = [];
    @track selectedValues = [];
    @track assignedUsers = [];
    @track assignedGroups = [];
    originalValues = [];

    userColumns = [
        { label: 'User Name', fieldName: 'Name', type: 'text' },
        { label: 'Assignment Type', fieldName: 'Assignment_Type__c', type: 'text' }
    ];

    groupColumns = [
        { label: 'Group Name', fieldName: 'Group_Name__c', type: 'text' },
        { label: 'Assignment Type', fieldName: 'Assignment_Type__c', type: 'text' }
    ];

    get listLabel() {
        return this.editingType === 'User'
            ? 'Select Users to Assign'
            : 'Select Groups to Assign';
    }

    get showTables() {
        return !this.isEditMode;
    }

    get showEditor() {
        return this.isEditMode;
    }

    get hasUsers() {
        return this.assignedUsers.length > 0;
    }

    get hasGroups() {
        return this.assignedGroups.length > 0;
    }

    connectedCallback() {
        console.log('connectedCallback called, recordId:', this.recordId);
        if (this.recordId) {
            this.loadAssignedData();
        }
    }

    renderedCallback() {
        // Load data when recordId becomes available
        //if (this.recordId && !this._dataLoaded) {
        //    this._dataLoaded = true;
            this.loadAssignedData();
        //}
    }

    @api
    refresh() {
        if (this.isEditMode) {
            this.loadEditData();
        } else {
            this.loadAssignedData();
        }
    }

    async loadAssignedData() {
        try {
            const result = await getAssignedRecords({ propertyId: this.recordId });
            this.assignedUsers = result.users || [];
            this.assignedGroups = result.groups || [];
        } catch (error) {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Loading Data',
                    message: error.body?.message || 'An error occurred while loading assignments',
                    variant: 'error'
                })
            );
        }
    }

    async loadEditData() {
        try {
            const result = await getAssignmentsData({
                propertyId: this.recordId,
                type: this.editingType
            });

            this.availableOptions = result.availableList.map(item => ({
                label: item.Name,
                value: item.Id
            }));
            this.selectedValues = [...result.assignedIds];
            this.originalValues = [...result.assignedIds];
        } catch (error) {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Loading Data',
                    message: error.body?.message || 'An error occurred while loading assignments',
                    variant: 'error'
                })
            );
        }
    }

    handleEditUsers() {
        this.isEditMode = true;
        this.editingType = 'User';
        this.loadEditData();
    }

    handleEditGroups() {
        this.isEditMode = true;
        this.editingType = 'Group';
        this.loadEditData();
    }

    handleSelectChange(e) {
        this.selectedValues = e.detail.value;
    }

    async handleSave() {
        try {
            await saveAssignments({
                propertyId: this.recordId,
                type: this.editingType,
                newSelectedIds: this.selectedValues,
                previousSelectedIds: this.originalValues
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Assignments updated successfully!',
                    variant: 'success'
                })
            );

            this.isEditMode = false;
            this.editingType = '';
            await this.loadAssignedData();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Updating Assignments',
                    message: error.body?.message || 'An error occurred while saving assignments',
                    variant: 'error'
                })
            );
        }
    }

    handleCancel() {
        this.selectedValues = [...this.originalValues];
        this.isEditMode = false;
        this.editingType = '';
    }
}