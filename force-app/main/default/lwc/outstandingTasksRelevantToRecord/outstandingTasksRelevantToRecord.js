import { LightningElement, api, wire, track } from 'lwc';
import getTasks from '@salesforce/apex/OutstandingTasksController.getTasks';
import updateTask from '@salesforce/apex/OutstandingTasksController.updateTask';
import { NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';

import outstandingTasks from '@salesforce/label/c.lbl_Outstanding_tasks';
import noOutstandingTasks from '@salesforce/label/c.lbl_No_outstanding_tasks';
import newLabel from '@salesforce/label/c.lbl_New';

export default class OutstandingTasksRelevantToRecord extends NavigationMixin(LightningElement) {
	@api recordId;
	@track tasks;
	@track visible;
	count;

	error;

	labels = {
		outstandingTasks : outstandingTasks,
		noOutstandingTasks : noOutstandingTasks,
		newLabel : newLabel
	};
	
    @wire(getTasks, {userId: userId, recordId: '$recordId'}) wiredOutstandingTasks({data, error}){
		console.log(this.recordId);
		
		if(data && data.length >= 1){
			this.error = undefined;
			this.tasks = JSON.parse(JSON.stringify(data));
			this.count = data.length;
			console.log('TASKS ' + JSON.stringify(this.tasks));
			this.visible = true;

			this.tasks.forEach(task => {
				this[NavigationMixin.GenerateUrl]({
					type: 'standard__recordPage',
					attributes: {
						recordId: task.Url,
						actionName: 'view',
					},
				}).then((url) => {
					task.Url = url;
				});

				task.Color = 'date-icon clock-' + task.Color; 
			});
		}else if (error) {
			this.error = error;
			this.visible = false;
			console.log(this.error);
		}
	}

	handleChange(event) {
		updateTask({recordId: event.target.dataset.recordid, status: event.target.checked})
		.then((result) => {
			console.log(result);
		})
		.catch((error) => {
			console.log(error.body.message);
		});
	}
}