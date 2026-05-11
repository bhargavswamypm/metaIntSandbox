import { LightningElement, api } from 'lwc';

export default class ZuciDashboardCard extends LightningElement {
    @api title;
    @api iconName;
    @api accentColor;
    @api navTarget;

    get accentStyle() {
        return `background: ${this.accentColor || '#c97a1e'};`;
    }

    handleViewAll() {
        this.dispatchEvent(new CustomEvent('viewall', {
            bubbles: true,
            composed: true,
            detail: { target: this.navTarget }
        }));
    }
}