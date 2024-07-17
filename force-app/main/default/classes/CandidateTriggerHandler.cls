public with sharing class CandidateTriggerHandler {
	private System.TriggerOperation triggerOperation;
	private List<Candidate__c> newList;
	private List<Candidate__c> oldList;
	private Map<Id, Candidate__c> newMap;
	private Map<Id, Candidate__c> oldMap;

	public CandidateTriggerHandler(System.TriggerOperation triggerOperation, List<Candidate__c> newList, List<Candidate__c> oldList, Map<Id, Candidate__c> newMap, Map<Id, Candidate__c> oldMap) {
		this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
	}

	public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
				TriggerUtils.setFullNames(this.newList);
				setUniqueId(this.newList);
				setAccount(newList);
			}
			when AFTER_INSERT {
			}
			when BEFORE_UPDATE{
				TriggerUtils.setFullNames(this.newList);
				setUniqueId(this.newList);
			}
			when AFTER_UPDATE {
			}
			when AFTER_DELETE {
			}
		}
	}

	public void setAccount(List<Candidate__c> newList) {
		if (UserInfo.getUserType() != 'Standard') {
			Id vendor = [
				SELECT AccountId FROM Contact WHERE Id IN (
				SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
				LIMIT 1].AccountId;

			for (Candidate__c cand: newList) {
				cand.Account__c = vendor;
			}
		}
	}

	public void	setUniqueId(List<Candidate__c> newList) {
		/* UniqueId is AccountId_VendorId_FullName */
		for (Candidate__c c: newList) {
			// c.UniqueId__c = c.Account__c + '_' + c.Vendor__c + '_' + c.Name.replace(' ', '_');
		}
	}
}