import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import TITLE_FIELD from '@salesforce/schema/User.Title';
import zuciLogo from '@salesforce/resourceUrl/Zucitech_Logo';

export default class ZuciSidebar extends NavigationMixin(LightningElement) {
    @api activeNav = 'home';
    userId = Id;
    logoUrl = zuciLogo;

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD, TITLE_FIELD] })
    currentUser;

    get userName() {
        return getFieldValue(this.currentUser.data, NAME_FIELD) || 'User';
    }

    get showBackButton() {
        return this.isMobile && this.activeNav !== 'home';
    }

    get userRole() {
        return getFieldValue(this.currentUser.data, TITLE_FIELD) || 'System Administrator';
    }

    get navItems() {
        const items = [
            { id: 'home',        label: 'Home',          iconName: 'utility:home' },
            { id: 'leads',       label: 'Leads',         iconName: 'utility:lead' },
            { id: 'property',    label: 'Properties',    iconName: 'utility:home' },
            { id: 'contact',     label: 'Contacts',      iconName: 'utility:contact' },
            { id: 'opportunity', label: 'Opportunities', iconName: 'utility:opportunity' }
            // Commented out — to be added later
            // { id: 'orders',         label: 'Orders',          iconName: 'utility:orders' },
            // { id: 'purchaseorders', label: 'Purchase Orders', iconName: 'utility:contract' },
            // { id: 'payments',       label: 'Payments',        iconName: 'utility:payment_gateway' }
        ];
        return items.map(item => ({
            ...item,
            cssClass: `nav-item${item.id === this.activeNav ? ' active' : ''}`
        }));
    }

    handleNavClick(event) {
        const target = event.currentTarget.dataset.target;
        this.dispatchEvent(new CustomEvent('navigate', { detail: { target } }));
    }

    handleBack() {
        this.dispatchEvent(
            new CustomEvent('navigate', {
                detail: { target: 'home' }
            })
        );
    }

    handleSignOut() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'logout' }
        });
    }

    isMobile = window.innerWidth <= 600;

connectedCallback() {
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
}

disconnectedCallback() {
    window.removeEventListener('resize', this.handleResize);
}

handleResize() {
    this.isMobile = window.innerWidth <= 600;
}
}