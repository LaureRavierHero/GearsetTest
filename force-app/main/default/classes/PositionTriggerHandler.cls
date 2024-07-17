public with sharing class PositionTriggerHandler {
    private System.TriggerOperation triggerOperation;
	private List<Position__c> newList;
	private List<Position__c> oldList;
	private Map<Id, Position__c> newMap;
	private Map<Id, Position__c> oldMap;

    public PositionTriggerHandler(System.TriggerOperation triggerOperation, List<Position__c> newList, List<Position__c> oldList, Map<Id, Position__c> newMap, Map<Id, Position__c> oldMap) {
        this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
    }

    public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
                TriggerUtils.addUserAccountToObjects(this.newList);
				setInitialStatus(this.newList);
				setHiringManager(this.newList);
			}
			when AFTER_INSERT {
				checkCreateTask(newMap, null);
				allowPreferentialCandidates(newList);
			}
			when BEFORE_UPDATE{
				checkCreateTask(newMap, oldMap);
			}
			when AFTER_UPDATE {
				// lockCategories(oldMap, newMap);
			}
			when AFTER_DELETE {
			}
		}
    }

	/* In order for a hiring manager to create preferential applications, we need to connect Customer as Vendor for this position */
	public static void allowPreferentialCandidates(List<Position__c> newList) {
		List<Vendor_position_application__c> vendorPositionConnections = new List<Vendor_position_application__c>();
		for (Position__c pos: newList) {
			Vendor_position_application__c vpa = new Vendor_position_application__c();
			vpa.Vendor__c = pos.Account__c;
			vpa.Position__c = pos.Id;

			vendorPositionConnections.add(vpa);
		}

		insert vendorPositionConnections;
	}

	public static void checkCreateTask(Map<Id, Position__c> newMap, Map<Id, Position__c> oldMap) {
		List<TaskHandler.TaskWrapper> taskWrappers = new List<TaskHandler.TaskWrapper>();

		User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
		List<Contact> relatedContact = [SELECT Id, AccountId, Account.Hiring_desk_queue_id__c FROM Contact WHERE Id = :u.ContactId LIMIT 1];
		
		String assignTo;
		if(relatedContact.size() > 0){
			assignTo = relatedContact[0].Account.Hiring_desk_queue_id__c;
		}else{
			assignTo = UserInfo.getUserId();
		}

		for(Id key : newMap.keySet()) {
			Position__c pos = newMap.get(key);
			String recordTypeName =  Schema.getGlobalDescribe().get('Position__c').getDescribe().getRecordTypeInfosById().get(pos.RecordTypeId).getName();
			if(!recordTypeName.contains('template')){
				if(oldMap != null){
					if(pos.Status__c != oldMap.get(key).Status__c && oldMap.get(key).Status__c == 'Concept') {
						TaskHandler.TaskWrapper wrapperNewPosition = new TaskHandler.TaskWrapper('new_position', pos.id, assignTo, system.today());
						taskWrappers.add(wrapperNewPosition);
					}
					if(pos.Deadline_candidate_submission__c != null && oldMap.get(key).Deadline_candidate_submission__c == null){
						TaskHandler.TaskWrapper wrapperSubmitCandidate = new TaskHandler.TaskWrapper('submit_candidates', pos.id, assignTo, pos.Deadline_candidate_submission__c);
						taskWrappers.add(wrapperSubmitCandidate);
					}
				}else{
					if(pos.Status__c != 'Concept'){
						TaskHandler.TaskWrapper wrapperNewPosition = new TaskHandler.TaskWrapper('new_position', pos.id, assignTo, system.today());
						taskWrappers.add(wrapperNewPosition);
						if(pos.Deadline_candidate_submission__c != null){
							TaskHandler.TaskWrapper wrapperSubmitCandidate = new TaskHandler.TaskWrapper('submit_candidates', pos.id, assignTo, pos.Deadline_candidate_submission__c);
							taskWrappers.add(wrapperSubmitCandidate);
						}
					}
				}
			}
		}

		if (taskWrappers.size() > 0){
			TaskHandler.createTasks(taskWrappers);
		}

	}

	public static void setInitialStatus(List<Position__c> newList) {
		for (Position__c pos: newList) {
			// Can't set Status to 'New' because of 'Concept'
			pos.Processing_status__c = 'New';
		}
	}

	/* This makes sure categories cannot be altered anymore once a Position is locked */
	// public static void	lockCategories(Map<Id, Position__c> oldMap, Map<Id, Position__c> newMap) {
	// 	Set<Id> relevantIds = new Set<Id>();

	// 	for (Id posId: newMap.keySet()) {
	// 		Position__c newPos = newMap.get(posId);
	// 		Position__c oldPos = oldMap.get(posId);
			
	// 		if (newPos.Processing_status__c == 'Distributed' && newPos.Processing_status__c != oldPos.Processing_status__c) {
	// 			relevantIds.add(posId);
	// 		}
	// 	}

	// 	List<Position_category__c> relatedCategories = [SELECT Id, Category__c FROM Position_category__c WHERE Position__c IN :relevantIds];
		
	// 	Approval.LockResult [] results = Approval.lock(relatedCategories);
	// 	for (Approval.LockResult res: results) {
	// 		if (!res.isSuccess()) {
	// 			for(Database.Error err : res.getErrors()) {
	// 				System.debug(LoggingLevel.ERROR, 'Error:');
	// 				System.debug(LoggingLevel.ERROR, err.getStatusCode() + ': ' + err.getMessage());
	// 				System.debug(LoggingLevel.ERROR, 'Fields that affected this error: ' + err.getFields());
	// 			}
	// 		}
	// 	}
	// }
	
	public static void setHiringManager(List<Position__c> newList) {
		if (UserInfo.getUserType() != 'Standard') {
			Id hiringManagerContactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
			for (Position__c pos: newList) {
				pos.Hiring_manager__c = hiringManagerContactId;
			}
		}
	}

	public class PositionTriggerHandlerException extends Exception {}
}