import { LightningElement, api, wire, track } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import { subscribe, MessageContext, publish } from 'lightning/messageService';

import getButtons from '@salesforce/apex/PortalButtonsController.getButtons';
import callAction from '@salesforce/apex/PortalButtonsController.callAction';
// import { RefreshEvent } from "lightning/refresh";
import REFRESH_CHANNEL from "@salesforce/messageChannel/refreshMessageChannel__c";


export default class TEST extends LightningElement {
	@api 
	recordId;
	@track buttons;
	flow;
    showModal = false;
    flowParameters;
	apexParameters;
	showDuplicatePosition = false;

	@wire(MessageContext)
    messageContext;
	// newPositionButtonConstructor;
	// newPositionButtonProps;

	connectedCallback() {
		// this.props = {'recordId': this.recordId};
		// import("c/newPositionButton")
		// .then(({ default: ctor }) => (this.newPositionButtonConstructor = ctor))
		// .catch((err) => console.log("Error importing component"));
    }

	@wire(getButtons, {recordId: '$recordId'})
    wiredSettings(result) {
        this.settings = result;
        const {data, error} = this.settings;
        this.loading = true;
        if (data) {
            console.log('BUTTONS:' + JSON.stringify(data.buttons));
            this.buttons = data.buttons.filter((elem) => {return elem.visible == true})
			this.props = {'recordId': this.recordId};
			this.showDuplicatePosition = (data.audience == 'HIRING_MANAGER' && data.objectName == 'Position__c');
            this.loading = false;
        }
        else if (error) {
            console.log(error);
            this.loading = false;
        }
    }

	@api refreshButtons() {
		console.log('REFRESH PORTAL BUTTONS');
		return refreshApex(this.settings);
	}

	refresh() {
		// console.log('REFRESH PORTAL BUTTONS ' + this.recordId);
		this.apexParameters = null;
		this.flowParameters = null;
		this.showModal = false;
		this.showFlowName = null;
		// console.log('Dispatch refresh event!');
		// this.dispatchEvent(new RefreshEvent());
		publish(this.messageContext, REFRESH_CHANNEL, {});
		this.dispatchEvent(new CustomEvent('actionexecuted'));
		return refreshApex(this.settings);
	}

	handleButtonClick(event){
		console.log(JSON.stringify(event.target.dataset));
		console.log(JSON.stringify(this.buttons[event.target.dataset.index]));
		var button = this.buttons[event.target.dataset.index];

        if(button.actionType == 'Flow'){
			console.log('FLOW');
            this.flow = button;
            // if(this.flow.RecordIdParameterName != null){
                this.flowParameters = this.getFlowParameters(button);
            // }
            this.showModal = true;
        } else if(button.actionType === 'Apex'){
			console.log('APEX');
            callAction({actionName:button.actionName})
            .then(result => {
				// this.dispatchEvent(new RefreshEvent());
                // console.log(result);
				this.refresh();
            })
        } else if (button.actionType == 'Approval action') {
			console.log('APPROVAL ACTION');
			if (button.actionName == 'Submit approval') {
				console.log('SUBMIT FOR APPROVAL');

				if (button.approvalFlowName) {
					console.log('FLOW');
					this.flowParameters = this.getFlowParameters(button);
					this.flow = JSON.parse(JSON.stringify(button));
					this.flow.flowName = button.approvalFlowName;
					console.log('FLOW PARAMETERS' + JSON.stringify(this.flowParameters));
					console.log('FLOW INFO' + JSON.stringify(this.flow));
					this.showModal = true;
				}
				else {
					this.apexParameters = this.getApexParameters(button);
					console.log('APEX PARAMETERS' + JSON.stringify(this.apexParameters));
					callAction({actionName: button.actionName, arguments: this.apexParameters})
					.then(result => {
						console.log(result);
						
						this.refresh();
					})
				}
			}
			else if (button.actionName == 'Recall approval') {
				console.log('RECALL APPROVAL');
				// console.log('APEX PARAMETERS' + this.apexParameters);
				// Prompt for comment?
				if (button.approvalFlowName) {
					console.log('FLOW');
					this.flowParameters = this.getFlowParameters(button);
					this.flow = JSON.parse(JSON.stringify(button));
					this.flow.flowName = button.approvalFlowName;
					console.log('FLOW PARAMETERS' + JSON.stringify(this.flowParameters));
					console.log('FLOW INFO' + JSON.stringify(this.flow));
					this.showModal = true;
				}
				else {
					console.log('APEX');
					this.apexParameters = this.getApexParameters(button);
					callAction({actionName: button.actionName, arguments: this.apexParameters})
					.then(result => {
						// console.log(result);
						// this.apexParameters = null;
						// this.dispatchEvent(new RefreshEvent());
						// return refreshApex(this.settings);
						this.refresh();
					})
				}
			}
			else if (button.actionName == 'Approve approval' || button.actionName == 'Reject approval') {
				console.log('APPROVE REJECT APPROVAL');
				if (button.approvalFlowName) {
					console.log('FLOW');
					this.flowParameters = this.getFlowParameters(button);
					this.flow = JSON.parse(JSON.stringify(button));
					this.flow.flowName = button.approvalFlowName;
					console.log('FLOW PARAMETERS' + JSON.stringify(this.flowParameters));
					console.log('FLOW INFO' + JSON.stringify(this.flow));
					this.showModal = true;
				}
				else {
					console.log('APEX');
					this.apexParameters = this.getApexParameters(button);
					callAction({actionName: button.actionName, arguments: this.apexParameters})
					.then(result => {
						// console.log(result);
						// this.apexParameters = null;
						// this.dispatchEvent(new RefreshEvent());
						// return refreshApex(this.settings);
						this.refresh();
					})
				}
			}
			else if (button.actionName == 'Placement request') {
				console.log('REQUEST PLACEMENT');
				this.apexParameters = this.getApexParameters(button);
				callAction({actionName: button.actionName, arguments: this.apexParameters})
				.then(result => {
					// console.log(result);
					// this.apexParameters = null;
					// this.dispatchEvent(new RefreshEvent());
					// return refreshApex(this.settings);
					this.refresh();
				})
			}
		}
	}

	getFlowParameters(button){
		var action;
		switch (button.actionName) {
			case 'Approve approval':
				action = 'Approve';
				break;
			case 'Reject approval':
				action = 'Reject';
				break;
			case 'Recall approval':
				action = 'Removed';
				break;
			case 'Submit approval':
				action = 'Submit'
				break;
		}
        // return [
        //     {
        //         name: 'recordId',
        //         type: 'String',
        //         value: this.recordId
        //     }, 
		// 	{
		// 		name: 'approvalProcessName',
		// 		type: 'String',
		// 		value: button.approvalProcessName? button.approvalProcessName: ""
		// 	},
		// 	{
		// 		name: 'approveRejectProcessInstanceWorkItemId',
		// 		type: 'String',
		// 		value: button.approveRejectWorkItemId? button.approveRejectWorkItemId: ""
		// 	},
			// {
			// 	name: 'recallProcessInstanceWorkItemIds',
			// 	type: 'SObject',
			// 	value: button.recallWorkItemIds
			// },
			// {
			// 	name: 'action',
			// 	type: 'String',
			// 	value: action
			// },
			// {
			// 	name: 'approverContactId',
			// 	type: 'String',
			// 	value: button.approverContactId? button.approverContactId: ""
			// },
        // ]

		var res = [];

		if (this.recordId) {
			res.push({
                name: 'recordId',
                type: 'String',
                value: this.recordId
            })
		}
		if (button.approvalProcessName) {
			res.push(
				{
					name: 'approvalProcessName',
					type: 'String',
					value: button.approvalProcessName
				}
			)
		}
		if (button.approveRejectWorkItemId) {
			res.push ({
				name: 'approveRejectProcessInstanceWorkItemId',
				type: 'String',
				value: button.approveRejectWorkItemId
			})
		}
		if (button.recallWorkItemIds) {
			res.push({
				name: 'recallProcessInstanceWorkItemIds',
				type: 'SObject',
				value: button.recallWorkItemIds
			})
		}
		if (action) {
			res.push({
				name: 'action',
				type: 'String',
				value: action
			})
		}
		if (button.approverContactId) {
			res.push(
				{
					name: 'approverContactId',
					type: 'String',
					value: button.approverContactId
				}
			)
		}

		console.log('FLOW ARGUMENTS: ' + JSON.stringify(res));
		return res;
    }

	getApexParameters(button){
        return {
			recordId: this.recordId,
			approvalProcessName: button.approvalProcessName,
			recallWorkItemIds: button.recallWorkItemIds,
			approveRejectWorkItemId: button.approveRejectWorkItemId,
			action: button.actionName,
			hasManualApprover: button.hasManualApprover,
			approverContactId: button.approverContactId,
			taskType: button.taskType,
			taskOwnerId: button.taskOwnerId
		}
    }
 
    handleFlowStatusChange(event){
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
			this.refresh();
			// this.dispatchEvent(new RefreshEvent());
			// return refreshApex(this.settings);
        }
    }
    closeModal(){
		this.refresh();
        // this.showModal = false;
        // this.showFlowName = null;
    }
}