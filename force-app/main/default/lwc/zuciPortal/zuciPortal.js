import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class ZuciPortal extends LightningElement {
    @track activeNav = 'home';
    userId = Id;

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    currentUser;

    get userName() {
        return getFieldValue(this.currentUser.data, NAME_FIELD) || 'User';
    }

    dashboardCards = [
        {
            id: 'leads',
            title: 'My Leads',
            iconName: 'standard:lead',
            accentColor: '#c97a1e',
            navTarget: 'leads'
        },
        {
            id: 'property',
            title: 'Properties',
            iconName: 'standard:home',
            accentColor: '#10b981',
            navTarget: 'property'
        },
        {
            id: 'contact',
            title: 'Contacts',
            iconName: 'standard:contact',
            accentColor: '#3b82f6',
            navTarget: 'contact'
        },
        {
            id: 'opportunity',
            title: 'Opportunities',
            iconName: 'standard:opportunity',
            accentColor: '#8b5cf6',
            navTarget: 'opportunity'
        }
        // Commented out — to be added later
        // { id: 'orders',         title: 'Orders',          iconName: 'standard:orders',           accentColor: '#d1d5db', navTarget: 'orders' },
        // { id: 'purchaseorders', title: 'Purchase Orders', iconName: 'standard:contract',         accentColor: '#d1d5db', navTarget: 'purchaseorders' },
        // { id: 'payments',       title: 'Payments',        iconName: 'standard:payment_gateway',  accentColor: '#d1d5db', navTarget: 'payments' }
    ];

    get isHome()        { return this.activeNav === 'home'; }
    get isLeads()       { return this.activeNav === 'leads'; }
    get isProperty()    { return this.activeNav === 'property'; }
    get isContact()     { return this.activeNav === 'contact'; }
    get isOpportunity() { return this.activeNav === 'opportunity'; }

    handleNavigate(event) {
        this.activeNav = event.detail.target;
    }

    handleViewAll(event) {
        this.activeNav = event.detail.target;
    }
}