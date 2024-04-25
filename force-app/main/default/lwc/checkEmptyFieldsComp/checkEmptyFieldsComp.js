import { LightningElement, api, track, wire } from 'lwc';
import checkFields from '@salesforce/apex/CheckEmptyFieldsController.checkEmptyFields';

export default class CheckEmptyFieldsComp extends LightningElement {
    @api recordId;
    @api fieldsetName;
    @api keyField;
    @api addCheckbox;
    @api fromFlow;
    @track showMsg;
    @track message;

    @wire(checkFields, {recordId: '$recordId', fieldsetName: '$fieldsetName', keyField: '$keyField', addCheckbox: '$addCheckbox', fromFlow: '$fromFlow'}) 
    results({ error, data}) {
        if(data) {
            console.log(data);
            console.log(data.fields);
            this.message = data.fields;
            this.showMsg = !data.isComplete;
        } else if(error) {
            console.log(error);
            console.log(error.body.message);

            this.message = error.body.message;
            this.showMsg = true;
        }
    }

}