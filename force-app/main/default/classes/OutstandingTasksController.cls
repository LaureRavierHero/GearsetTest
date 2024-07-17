public with sharing class OutstandingTasksController {
	@AuraEnabled(cacheable=true)
	public static List<TaskC> getTasks(String userId, String recordId) {
		DateTime now = System.now();
		DateTime timeLimit = now.addminutes(-10);

		Set<Id> actorIds = SchemaUtils.getGroupsUserIsPartOf(userId);
		actorIds.add(userId);

		String queryString = 'SELECT'
			+ ' Id, Subject, Description, WhatId, ActivityDate, CreatedDate, Status, Type'
			+ ' FROM Task'
			+ ' WHERE OwnerId IN :actorIds'
			+ ' AND ('
				+ 'isClosed = false'
				+ ' OR ('
					+ 'CompletedDateTime <= :now'
					+ ' AND CompletedDateTime >= :timeLimit'
				+ ')'
			+ ')';

		if(recordId != null){
			queryString += ' AND WhatId = :recordId';
		}

		queryString += ' ORDER BY ActivityDate ASC';

		List<Task> tasks = new List<Task>();

		try {
			tasks = Database.query(queryString);
		} catch (Exception e) {
			// Handle the exception
			System.debug('An error occurred: ' + e.getMessage());
		}
		
		System.debug('tasks');
		System.debug(tasks);

		List<TaskC> tasksC = new List<TaskC>();
		List<TaskC> tasksCNew = new List<TaskC>();
		List<TaskC> tasksCOld = new List<TaskC>();

		Long currentTime = now.getTime();

		Integer hour = 3600000;
		Integer day = hour * 24;
		Integer week = day * 7;

		Set<Id> applicationsToQuery = new Set<Id>();
		for(Task t : tasks) {
			System.debug(t.Type);
			if(t.WhatId?.getSObjectType() == Schema.Application__c.getSObjectType() 
			&& t.Type != 'vendor_provide_professional_information' 
			&& t.Type != 'placement_request'
			&& t.Type != 'plan_intake') {
				applicationsToQuery.add(t.WhatId);
			}
		}

		Map<Id, Application__c> relatedApplications = new Map<Id, Application__c>();
		if(applicationsToQuery.size() > 0) {
			relatedApplications = new Map<Id, Application__c>([SELECT Id, Position__c FROM Application__c WHERE Id IN :applicationsToQuery]);
		}

		for(Task t : tasks) {
			Long createdTime = t.CreatedDate.getTime();

			Datetime deadlineDateTime = t.ActivityDate;
			Long deadline = deadlineDateTime?.getTime();

			TaskC taskC = new TaskC();
			taskC.recordId = t.Id;
			taskC.Subject = t.Subject;
			taskC.Description = t.Description;
			taskC.WhatId = t.WhatId;
			taskC.Url = relatedApplications.containsKey(t.WhatId) && t.Type != 'vendor_provide_professional_information' && t.Type != 'placement_request' ? relatedApplications.get(t.WhatId).Position__c : t.WhatId;
			taskC.ActivityDate = t.ActivityDate;
			taskC.NewLabel = currentTime - createdTime <= hour ? true : false;
			taskC.Checked = t.Status == 'Completed' ? true : false;

			// Colors in APEX are fine
			if(deadline == null || currentTime > deadline) {
				taskC.Color = 'red';
			}else if(deadline - currentTime <= week) {
				taskC.Color = 'yellow';

				if(deadline - currentTime <= day) {
					taskC.Color = 'orange';
				}
			}else {
				taskC.Color = 'green';
			}

			if(taskC.NewLabel == true) {
				tasksCNew.add(taskC);
			} else {
				// This line can never be reached in a test, that makes me sad :(
				tasksCOld.add(taskC);
			}
		}

		tasksC.addAll(tasksCNew);
		tasksC.addAll(tasksCOld);

		return tasksC;
	}

	@AuraEnabled
	public static Boolean updateTask(String recordId, Boolean status) {
		Task taskToUpdate = new Task(
			Id = recordId,
			Status = status == true ? 'Completed' : 'Open'
		);

		Database.SaveResult updatedRecord = Database.update(taskToUpdate, false);

		if (updatedRecord.isSuccess()) {
			return true;
		} else {
			return false;
		}
	}
	
	// Custom task
	public class TaskC {
		@AuraEnabled public Id recordId;
		@AuraEnabled public String Subject;
		@AuraEnabled public String Description;
		@AuraEnabled public String WhatId;
		@AuraEnabled public String Url;
		@AuraEnabled public Date ActivityDate;
		@AuraEnabled public Boolean NewLabel;
		@AuraEnabled public String Color;
		@AuraEnabled public Boolean Checked;
	}
}