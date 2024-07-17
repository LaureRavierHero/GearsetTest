public with sharing class UserTriggerHandler {
	private System.TriggerOperation triggerOperation;
	private List<User> newList;
	private List<User> oldList;
	private Map<Id, User> newMap;
	private Map<Id, User> oldMap;
 
	public UserTriggerHandler(System.TriggerOperation triggerOperation, List<User> newList, List<User> oldList, Map<Id, User> newMap, Map<Id, User> oldMap) {
		this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
	}
 
	public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
				setAccountId(this.newList);
			}
			when AFTER_INSERT {
				// setUserIdOnContact(this.newList);
			}
			when BEFORE_UPDATE{
				setAccountId(this.newList);
			}
			when AFTER_UPDATE {
			}
			when AFTER_DELETE {
			}
		}
	}
 
	public void setUserIdOnContact(List<User> newList){
		Set<Id> contactIds = new Set<Id>();
		for(User u : newList){
			contactIds.add(u.ContactId);
		}
 
		Map<Id,Contact> contactsById = new Map<Id, Contact>([SELECT Id, User__c FROM Contact WHERE Id IN :contactIds]);
 
		List<Contact> contactsToUpdate = new List<Contact>();
		for(User u : newList){
			if(contactsById.containsKey(u.contactId)){
				Contact c = contactsById.get(u.ContactId);
				c.User__c = u.Id;
				contactsToUpdate.add(c);
			}
		}
 
		update contactsToUpdate;
	}
 
	public void setAccountId(List<User> newList) {
		Set<String> accountNames = DeveloperUtils.getStringFieldSet(newList, 'Account_name__c');
		Map<String, Id> accIdByName = DeveloperUtils.mapIdToName([SELECT Id, Name FROM Account WHERE Name IN :accountNames]);
 
		for (User usr: newList) {
			usr.AccountId__c = accIdByName.get(usr.Account_name__c);
		}
	}
 
	// public void	 updateAccountNameTextField(List<User> newList) {
	//	 /* User has a picklist for account selection, but in order to set the chosen account as the default picklist
	//	 value on (for ex) position, we have to have it as text (Formula field does not accept picklist field) */
	//	 for (User u: newList) {
	//		 u.Account_name_text__c = u.Account_name__c;
	//	 }
	// }
}