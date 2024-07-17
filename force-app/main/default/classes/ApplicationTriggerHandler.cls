public without sharing class ApplicationTriggerHandler {
    private System.TriggerOperation triggerOperation;
	private List<Application__c> newList;
	private List<Application__c> oldList;
	private Map<Id, Application__c> newMap;
	private Map<Id, Application__c> oldMap;

    public ApplicationTriggerHandler(System.TriggerOperation triggerOperation, List<Application__c> newList, List<Application__c> oldList, Map<Id, Application__c> newMap, Map<Id, Application__c> oldMap) {
        this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
    }

    public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
				emptyRejectionReasonForStatus(newList);
				setAccount(newList);
				setVendor(newList);
				setDefaults(this.newList);
			}
			when AFTER_INSERT {
				shareApplicationWithHiringDesk(newList);
				increaseNumberApplicationsSent(newList);
				submitForApproval(newList);
				updatePosition(newList);
			}
			when BEFORE_UPDATE{
				emptyRejectionReasonForStatus(newList);
			}
			when AFTER_UPDATE {
				// removeApplicationSentIfCandidateWithdrawn(newMap, oldMap);
			}
			when AFTER_DELETE {
			}
		}
	}

	public static void updatePosition(List<Application__c> newList) {
		Set<Id> positionsToUpdate = new Set<Id>();
		for (Application__c app: newList) {
			if (app.Is_preferred_candidate__c == true) {
				positionsToUpdate.add(app.Position__c);
			}
		}

		List<Position__c> positions = new List<Position__c>();
		for (Id posId: positionsToUpdate) {
			Position__c p = new Position__c();
			p.Id = posId;
			p.Has_preferred_candidates__c = true;

			positions.add(p);
		}

		update positions;
	}

	public static void submitForApproval(List<Application__c> newList) {
		for (Application__c app: newList) {
			if (app.Is_preferred_candidate__c == false) {
				ApprovalController.submitApprovalRequest(app.Id);
			}
		}
	}

	public static void setAccount(List<Application__c> newList) {
		Set<Id> positionIds = new Set<Id>();
		for (Application__c app : newList) {
			positionIds.add(app.Position__c);
		}

		Map<Id, Position__c> accByPosition = new Map<Id, Position__c>([SELECT Id, Account__c FROM Position__c WHERE Id IN :positionIds]);

		for (Application__c app : newList) {
			if (String.isBlank(app.Position__c)) {
				app.addError('No position set on application!');
			}
			else {
				app.Account__c = accByPosition.get(app.Position__c).Account__c;
			}
		}
	}

	public static void setVendor(List<Application__c> newList) {
		if (UserInfo.getUserType() != 'Standard') {
			Id vendor = [
				SELECT AccountId FROM Contact WHERE Id IN (
				SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
				LIMIT 1].AccountId;

				System.debug('VENDOR: ' + vendor);
				
			for (Application__c app: newList) {
				if (String.isBlank(app.Vendor__c)) {
					app.Vendor__c = vendor;
				}
			}
		}
	}

	// public void setHiringManagerUser(List<Application__c> newList) {
	// 	Set<Id> positionIds = new Set<Id>();
	// 	for (Application__c app : newList) {
	// 		positionIds.add(app.Position__c);
	// 	}

	// 	Map<Id,Position__c> relatedPositions = new Map<Id, Position__c>([SELECT Id, Hiring_Manager__c, Hiring_Manager__r.User__c FROM Position__c WHERE Id IN :positionIds]);
		
	// 	for (Application__c app : newList) {
	// 		app.Hiring_manager_associated_position__c = app.Hiring_manager_associated_position__c == null ? relatedPositions.get(app.Position__c).Hiring_Manager__r.User__c : app.Hiring_manager_associated_position__c;
	// 	}
	// }

	public void shareApplicationWithHiringDesk(List<Application__c> newList) {
		for (Application__c app: newList) {
			ApplicationSharingHandler.shareRecordWithHiringDesk(app.Id);
		}
	}

	public void setDefaults(List<Application__c> newList) {
		Set<Id>	candidateIds = new Set<Id>();
		for (Application__c app: newList) {
			candidateIds.add(app.Candidate__c);
			app.Status__c = 'New';
		}

		Map<Id, Candidate__c> candidates = new Map<Id, Candidate__c>([SELECT Name FROM Candidate__c WHERE Id IN :candidateIds]);
		for (Application__c app: newList) {
			if (String.isBlank(app.Candidate__c)) {
				app.addError('No candidate set!');
			}
			else {
				app.Name = candidates.get(app.Candidate__c).Name;
			}
		}
	}

	public void emptyRejectionReasonForStatus(List<Application__c> newList) {
		for (Application__c app: newList) {
			if (app.Send_to_hiring_manager__c != 'No') {
				app.Reason_rejection_hiring_desk__c = '';
			}
		}
	}

	public void increaseNumberApplicationsSent(List<Application__c> newList) {
		Map<Id, Set<Id>> positionIdsByVendor = new Map<Id, Set<Id>>();

		for (Application__c app: newList) {
			Id vendorId = app.Vendor__c;
			if (positionIdsByVendor.get(vendorId) == null) {
				positionIdsByVendor.put(vendorId, new Set<Id>());
			}
			positionIdsByVendor.get(vendorId).add(app.Position__c);
		}
		
		System.debug('positionIdsByVendor' + positionIdsByVendor);

		Set<Id> posIds = new Set<Id>();

		for (Set<Id> ids: positionIdsByVendor.values()) {
			posIds.addAll(ids);
		}

		List<Vendor_position_application__c> vendor_position_applications = [
			SELECT Vendor__c, Position__c, Number_of_active_applications__c
			FROM Vendor_position_application__c 
			WHERE (
				Vendor__c IN :positionIdsByVendor.keySet()
				AND 
				Position__c IN :posIds
			)
		];

		System.debug('vendor_position_applications' + vendor_position_applications);

		List<Vendor_position_application__c> connsToUpdate = new List<Vendor_position_application__c>();
		for (Vendor_position_application__c conn: vendor_position_applications) {
			Set<Id> tmpPosIds = positionIdsByVendor.get(conn.Vendor__c);
			if (tmpPosIds != null && tmpPosIds.contains(conn.Position__c)) {
				conn.Number_of_active_applications__c++;
				System.debug((conn.Number_of_active_applications__c));
				connsToUpdate.add(conn);
			}
		}

		System.debug(connsToUpdate);
		update connsToUpdate;
	}

	// public void removeApplicationSentIfCandidateWithdrawn(Map<Id, Application__c> newMap, Map<Id, Application__c> oldMap) {
	// 	List<Vendor_position_application__c> recordsToRemoveOneCounter = new List<Vendor_position_application__c>();
	// 	Set<Id> recordIds = new Set<Id>();

	// 	for(Id recordId : newMap.keySet()) {
	// 		if(newMap.get(recordId).Status__c != oldMap.get(recordId).Status__c
	// 		&& newMap.get(recordId).Status__c == 'Candidate withdrawn') {
	// 			recordIds.add(recordId);
	// 		}
	// 	}

	// 	if(!recordIds.isEmpty()) {
	// 		List<Vendor_position_application__c> updatedApplis = new List<Vendor_position_application__c>();

	// 		List<Vendor_position_application__c> vendorPositionApplications = [
	// 			SELECT Number_of_active_applications__c
	// 			FROM Vendor_position_application__c 
	// 			WHERE Id IN :recordIds
	// 		];
			
	// 		for(Vendor_position_application__c appli : vendorPositionApplications) {
	// 			Vendor_position_application__c updatedAppli = new Vendor_position_application__c(
	// 				Id = appli.Id,
	// 				Number_of_active_applications__c = appli.Number_of_active_applications__c - 1
	// 			);

	// 			updatedApplis.add(updatedAppli);
	// 		}

	// 		if(!updatedApplis.isEmpty()) {
	// 			update updatedApplis;
	// 		}
	// 	}
	// }
}