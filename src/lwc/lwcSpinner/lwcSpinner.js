import {api, LightningElement} from 'lwc';

export default class LwcSpinner extends LightningElement {
    @api label;
    @api isBusy;
    @api size = 'medium';
    @api variant = 'brand';
}