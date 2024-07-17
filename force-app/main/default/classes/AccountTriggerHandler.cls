public with sharing class AccountTriggerHandler {
    private System.TriggerOperation triggerOperation;
	private List<Account> newList;
	private List<Account> oldList;
	private Map<Id, Account> newMap;
	private Map<Id, Account> oldMap;

    public AccountTriggerHandler(System.TriggerOperation triggerOperation, List<Account> newList, List<Account> oldList, Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
    }

    public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
			}
			when AFTER_INSERT {
				createDefaultContacts(newList);
			}
			when BEFORE_UPDATE{
			}
			when AFTER_UPDATE {
				updateDefaultContacts(newMap, oldMap);
			}
			when BEFORE_DELETE {
				deleteDefaultContacts(oldMap);
			}
			when AFTER_DELETE {
			}
		}
    }

	public static void deleteDefaultContacts(Map<Id, Account> oldMap) {
		Set<Id> toDelete = new Set<Id>();
		
		List<Default_hiring_desk_contact__c> hdc = [SELECT Id, Account__c, Contact__c FROM Default_hiring_desk_contact__c WHERE Account__c IN :oldMap.keySet()];
		List<Default_vendor_contact__c> vc = [SELECT Id, Vendor__c, Contact__c FROM Default_vendor_contact__c WHERE Vendor__c IN :oldMap.keySet()];

		for (Default_hiring_desk_contact__c hd: hdc) {
			toDelete.add(hd.Contact__c);
			toDelete.add(hd.Id);
		}

		for (Default_vendor_contact__c c: vc) {
			toDelete.add(c.Contact__c);
			toDelete.add(c.Id);
		}
	}

	public static void updateDefaultContacts(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
		Set<Id> hiringDeskAccountsToUpdate = new Set<Id>();
		Set<Id> vendorAccountsToUpdate = new Set<Id>();

		for (Id recordId: newMap.keySet()) {
			Account newAccount = newMap.get(recordId);
			Account oldAccount = oldMap.get(recordId);
			String recordType = '';

			if (String.isNotBlank(newAccount.RecordTypeId)) {
				recordType = SchemaUtils.getRecordTypeName('Account', newAccount.RecordTypeId);
			}

			switch on recordType {
				when 'Customer' {
					if (newAccount.Hiring_Desk_Email__c != oldAccount.Hiring_Desk_Email__c) {
						hiringDeskAccountsToUpdate.add(recordId);
					}
				}
				when 'Vendor' {
					if (newAccount.Email__c != oldAccount.Email__c) {
						vendorAccountsToUpdate.add(recordId);
					}
				}
			}
		}

		List<Default_hiring_desk_contact__c> hdc = [SELECT Id, Account__c, Contact__c FROM Default_hiring_desk_contact__c WHERE Account__c IN :hiringDeskAccountsToUpdate];
		List<Default_vendor_contact__c> vc = [SELECT Id, Vendor__c, Contact__c FROM Default_vendor_contact__c WHERE Vendor__c IN :vendorAccountsToUpdate];

		List<SObject> defaultContactsToUpdate = new List<SObject>();

		for (Default_hiring_desk_contact__c c: hdc) {
			defaultContactsToUpdate.add(new Contact(
				Id = c.Contact__c,
				Email = newMap.get(c.Account__c).Hiring_Desk_Email__c
			));
		}
		for (Default_vendor_contact__c c: vc) {
			defaultContactsToUpdate.add(new Contact(
				Id = c.Contact__c,
				Email = newMap.get(c.Vendor__c).Email__c
			));
		}

		update defaultContactsToUpdate;
	}

	public static void createDefaultContacts(List<Account> newList) {
		List<SObject> defaultContacts = new List<SObject>();
		List<Contact> contacts = new List<Contact>();

		System.debug('Accounts: ' + newList);
		for (Account acc: newList) {
			String recordType = '';

			try {
				recordType = SchemaUtils.getRecordTypeName('Account', acc.RecordTypeId);
			}
			catch (Exception e) {
				System.debug(LoggingLevel.WARN, e.getMessage());
			}

			switch on recordType {
				when 'Customer' {
					if (String.isBlank(acc.Hiring_Desk_Email__c)) {
						// acc.addError('Cannot create customer without hiring desk email address!'); # This makes it so that LightningSelfRegisterControllerTest fails
						System.debug(LoggingLevel.WARN, 'Creating customer without hiring desk email address!');
					}
					else {
						contacts.add(new Contact(
							RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Default hiring desk contact'),
							FirstName = acc.Name,
							LastName = 'hiring desk',
							AccountId = acc.Id,
							Email = acc.Hiring_Desk_Email__c
						));
					}
				}
				when 'Vendor' {
					if (String.isBlank(acc.Email__c)) {
						// acc.addError('Cannot create vendor without email address!');
						System.debug(LoggingLevel.WARN, 'Creating vendor without email address!');
					}
					else {
						contacts.add(new Contact(
							RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Default vendor contact'),
							FirstName = acc.Name,
							LastName = 'contact information',
							AccountId = acc.Id,
							Email = acc.Email__c
						));
					}
				}
			}
		}

		System.debug('CONTACTS ' + contacts);
		insert contacts;
		

		for (Contact c: contacts) {
			String recordType = '';
			try {
				recordType = SchemaUtils.getRecordTypeName('Contact', c.RecordTypeId);
			}
			catch (Exception e) {
				System.debug(LoggingLevel.WARN, e.getMessage());
			}

			switch on recordType {
				when 'Default hiring desk contact' {
					defaultContacts.add(new Default_hiring_desk_contact__c(
						Account__c = c.AccountId,
						Contact__c = c.Id
					));
				}
				when 'Default vendor contact' {
					defaultContacts.add(new Default_vendor_contact__c(
						Vendor__c = c.AccountId,
						Contact__c = c.Id
					));
				}
			}
		}

		System.debug('DEFAULT CONTACTS ' + defaultContacts);
		insert defaultContacts;
	}

	/*
		Check each added account to see if the type is customer and the hiring desk email is filled
		If so, create a new default hiring desk contact where emails can go to

		// TODO: (FUTURE) also do this for updated accounts. Update the related default hiring desk contact (AND vise versa)
	*/
	public static void processHiringDeskContacts(Map<Id, Account> newMap, Map<Id, Account> oldMap){
		List<Contact> contactsToInsert = new List<Contact>();
		List<Default_hiring_desk_contact__c> newDefaultList = new List<Default_hiring_desk_contact__c>();

		for(Id recordId : newMap.keySet()){
			Account newAccount = newMap.get(recordId);
			Account oldAccount = oldMap != null ? oldMap.get(recordId) : new Account();

			if(newAccount.Type == 'Customer'
			&& String.isBlank(oldAccount.Hiring_Desk_Email__c)
			&& !String.isBlank(newAccount.Hiring_Desk_Email__c)){
				Contact contact = new Contact(
					RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Default hiring desk contact'),
					LastName = 'Hiring Desk',
					AccountId = newAccount.Id,
					Email = newAccount.Hiring_Desk_Email__c
				);

				contactsToInsert.add(contact);
			}
		}

		if(!contactsToInsert.isEmpty()){
			insert contactsToInsert;

			for(Contact c : contactsToInsert){
				Default_hiring_desk_contact__c newDefault = new Default_hiring_desk_contact__c(
					Contact__c = c.Id,
					Account__c = c.AccountId
				);
				
				newDefaultList.add(newDefault);
			}

			insert newDefaultList;
		}
	}

	// Old method before optimizing
	// public static void processHiringDeskContacts(Map<Id, Account> newMap, Map<Id, Account> oldMap){
	// 	Map<Id, Account> hiringDeskContactsToCreate = new Map<Id, Account>();

	// 	for(Id recordId : newMap.keySet()){
	// 		if(newMap.get(recordId).Type == 'Customer'
	// 		&& String.isBlank(oldMap.get(recordId).Hiring_Desk_Email__c)
	// 		&& !String.isBlank(newMap.get(recordId).Hiring_Desk_Email__c)){
	// 			Account a = new Account(
	// 				Id = newMap.get(recordId).Id,
	// 				Hiring_Desk_Email__c = newMap.get(recordId).Hiring_Desk_Email__c
	// 			);

	// 			hiringDeskContactsToCreate.put(a.Id, a);
	// 		}
	// 	}

	// 	if(!hiringDeskContactsToCreate.isEmpty()){
	// 		List<Contact> contacts = new List<Contact>();

	// 		for(Account a : hiringDeskContactsToCreate.values()){
	// 			Contact c = new Contact(
	// 				Type__c = 'Hero contact',
	// 				LastName = 'Hiring Desk',
	// 				AccountId = a.Id,
	// 				Email = a.Hiring_Desk_Email__c
	// 			);

	// 			contacts.add(c);
	// 		}

	// 		insert contacts;

	// 		Map<Id, Id> contactIdByAccountId = DeveloperUtils.mapIdToIdField(contacts, 'Id', 'AccountId');

	// 		List<Default_hiring_desk_contact__c> newDefaultList = new List<Default_hiring_desk_contact__c>();

	// 		for(Contact c : contacts){
	// 			Default_hiring_desk_contact__c newDefault = new Default_hiring_desk_contact__c();
	// 			newDefault.Contact__c = c.Id;
	// 			newDefault.Account__c = contactIdByAccountId.get(c.Id);
	// 			newDefaultList.add(newDefault);
	// 		}

	// 		insert newDefaultList;
	// 	}
	// }
}