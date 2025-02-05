import {api, LightningElement} from 'lwc';

export default class LwcErrorMessages extends LightningElement {
    @api title = 'Errors:';
    @api errors;
}