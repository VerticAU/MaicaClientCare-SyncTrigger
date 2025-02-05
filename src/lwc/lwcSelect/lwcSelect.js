import BaseElement, {showToast} from 'c/lwcBase';
import {api} from "lwc";

export default class LwcSelect extends BaseElement {
    @api disabled;
    @api placeholder;
    @api required;
    @api pseudoRequired;
    @api labelHidden = false;
    @api label;
    @api options;
    @api noneLabel;
    @api value;

    connectedCallback() {
        super.connectedCallback();

        this.setValue(this.value);
    }

    @api
    validate() {
        this.clearErrors();
        let hasNoError = this.required === true && this.value || this.required !== true || this.required === undefined;
        if (!hasNoError) {
            this.showErrors(['Complete this field.']);
        }
        return hasNoError;
    }

    @api
    setValue(value) {
        this.value = value || '';

        setTimeout(() => {
            let select = this.template.querySelector('select');
            select.value = this.value;
            select.style.color = this.value ? 'initial' : '#666666';
        }, 10);
    }


    handleChange(event) {
        this.value = event.target.value;
        this.validate();
        this.dispatchEvent(new CustomEvent('change', {
            bubbles: false,
            composed: false,
            detail: {
                value: event.target.value
            }
        }));
        let select = this.template.querySelector('select');
        select.style.color = this.value ? 'initial' : '#666666';
    }

    get elementContainerClasses() {
        let classes = 'slds-form-element';
        if (this.required) {
            classes += ' is-required';
        }
        if (this.errorMessages?.length > 0) {
            classes += ' slds-has-error';
        }
        return classes;
    }
}