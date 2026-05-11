import { LightningElement, wire, track } from 'lwc';
    import getVendorsByRecordType from '@salesforce/apex/VendorController.getVendorRecords';
    import { ShowToastEvent } from 'lightning/platformShowToastEvent';

    export default class VendorDetails extends LightningElement {
        @track vendorGroups = [];
        @track error;
        @track isLoading = true;

        /**
         * Wire method to fetch vendor data from Apex
         */
        @wire(getVendorsByRecordType)
        wiredVendors({ data, error }) {
            this.isLoading = true;

            if (data) {
                try {
                    this.processVendorData(data);
                    this.error = undefined;
                } catch (err) {
                    this.handleError('Error processing vendor data', err);
                } finally {
                    this.isLoading = false;
                }
            } else if (error) {
                this.handleError('Error loading vendors', error);
                this.vendorGroups = [];
                this.isLoading = false;
            }
        }

        /**
         * Process vendor data and format for display
         * @param {Object} data - Raw vendor data from Apex
         */
        processVendorData(data) {
            this.vendorGroups = Object.keys(data).map(recordTypeName => {
                const vendors = data[recordTypeName];

                return {
                    recordType: recordTypeName,
                    rowCount: vendors.length,
                    iconName: this.getIconForRecordType(recordTypeName),
                    records: vendors.map((vendor, index) => ({
                        Id: vendor.Id,
                        Name: vendor.Name || 'N/A',
                        Phone__c: vendor.Phone__c || '',
                        Email__c: vendor.Email__c || '',
                        isFirst: index === 0,
                        emailLink: vendor.Email__c ? `mailto:${vendor.Email__c}` : null,
                        phoneLink: vendor.Phone__c ? `tel:${vendor.Phone__c}` : null
                    }))
                };
            });
        }

        /**
         * Get appropriate icon based on record type name
         * @param {String} recordTypeName - Name of the record type
         * @returns {String} Icon name
         */
        getIconForRecordType(recordTypeName) {
            const iconMap = {
                'Painter': 'utility:brush',
                'Carpenter': 'utility:builder',
                'Electrician': 'utility:power',
                'Interior Designer': 'utility:home',
                'Lawyer': 'utility:case',
                'Plumber': 'utility:custom_apps',
                'Stamp Vendor': 'utility:approval'
            };

            return iconMap[recordTypeName] || 'standard:account';
        }

        /**
         * Handle errors and show toast notification
         * @param {String} title - Toast title
         * @param {Object} error - Error object
         */
        handleError(title, error) {
            this.error = error;
            
            let message = 'Unknown error';
            if (error && error.body) {
                if (error.body.message) {
                    message = error.body.message;
                } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    message = error.body.pageErrors[0].message;
                }
            } else if (error && error.message) {
                message = error.message;
            }

            console.error('Vendor Details Error:', message);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: title,
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }

        /**
         * Computed property to check if vendors exist
         * @returns {Boolean}
         */
        get hasVendors() {
            return this.vendorGroups && this.vendorGroups.length > 0;
        }

        /**
         * Computed property to get total vendor count
         * @returns {Number}
         */
        get totalVendorCount() {
            return this.vendorGroups.reduce((total, group) => total + group.rowCount, 0);
        }

        /**
         * Handle refresh button click
         */
        handleRefresh() {
            this.isLoading = true;
            // Force wire service to refresh
            return refreshApex(this.wiredVendorsResult);
        }
    }