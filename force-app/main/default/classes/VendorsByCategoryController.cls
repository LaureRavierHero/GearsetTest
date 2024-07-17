public without sharing class VendorsByCategoryController {
	class VendorsByCategoryControllerException extends Exception {}
	@AuraEnabled
	public static Boolean areRequiredFieldsFilled(Id positionId) {
		Position__c position = [SELECT Number_of_hires__c, Deadline_candidate_submission__c FROM Position__c WHERE Id = :positionId];

		if(String.isBlank(position?.Number_of_hires__c) || position?.Deadline_candidate_submission__c == null) {
			return false;
		} else {
			return true;
		}
	}
	
	@AuraEnabled
	public static Integer doesPositionCategoryExist(Id positionId) {
		return [SELECT COUNT() FROM Position_category__c WHERE Position__c = :positionId];
	}

	@AuraEnabled
	public static VendorList getVendors(Id positionId) {
		VendorList vendorList = new VendorList();
		vendorList.matchingVendors = new List<Vendor>();
		vendorList.remainingVendors = new List<Vendor>();

		// Query all Position_category__c records related to the given positionId
		Set<Id> categoryIds = new Set<Id>();
		for (Position_category__c positionCategory : [SELECT Category__c FROM Position_category__c WHERE Position__c = :positionId]) {
			categoryIds.add(positionCategory.Category__c);
		}
		
		// Query Vendor_contact_categories__c records related to the categoryIds
		List<Vendor_contact_categories__c> vendorContactCategories = [SELECT Vendor__c, Vendor__r.Name, Category__r.Name FROM Vendor_contact_categories__c WHERE Category__c IN :categoryIds];

		// Loop through vendorContactCategories and map categories per vendor
		Map<Id, Set<String>> categoryMap = new Map<Id, Set<String>>();
		Map<Id, String> vendorNamePerVendorIdMap = new Map<Id, String>();

		for (Vendor_contact_categories__c vcc : vendorContactCategories) {
			if(!categoryMap.containsKey(vcc.Vendor__c)){
				categoryMap.put(vcc.Vendor__c, new Set<String>());
			}

			categoryMap.get(vcc.Vendor__c).add(vcc.Category__r.Name);
			vendorNamePerVendorIdMap.put(vcc.Vendor__c, vcc.Vendor__r.Name);
		}

		Set<Id> vendorsAlreadyDistributed = getVendorsAlreadyDistributed(positionId);

		List<Vendor> vendors = new List<Vendor>();
		List<Vendor> vendorsNotDistributed = new List<Vendor>();
		List<Vendor> vendorsDistributed = new List<Vendor>();

		for(Id recordId : vendorNamePerVendorIdMap.keySet()){
			if(recordId != null){
				List<String> categories = new List<String>(categoryMap.get(recordId));
				categories.sort();

				Vendor vendor = new Vendor();
				vendor.Id = recordId;
				vendor.Name = vendorNamePerVendorIdMap.get(recordId);
				vendor.Categories = String.join(categories, ', ');
				vendor.Distributed = vendorsAlreadyDistributed.contains(recordId) ?? false;

				if(vendor.Distributed == true){
					vendor.Checked = false;
					vendorsDistributed.add(vendor);
				}else{
					vendor.Checked = true;
					vendorsNotDistributed.add(vendor);
				}

				System.debug('vendor');
				System.debug(vendor);
			}
		}
		
		vendors.addAll(vendorsNotDistributed);
		vendors.addAll(vendorsDistributed);
		vendorList.matchingVendors.addAll(vendors);

		List<Account> remainingVendors = [SELECT Id, Name FROM Account WHERE (NOT Id IN :categoryMap.keySet()) AND RecordTypeId = :SchemaUtils.getRecordTypeId('Account', 'Vendor') ORDER BY Name ASC];

		if(!remainingVendors.isEmpty()){
		 	vendors = new List<Vendor>();
			vendorsNotDistributed = new List<Vendor>();
			vendorsDistributed = new List<Vendor>();

			for(Account v : remainingVendors){
				Vendor vendor = new Vendor();
				vendor.Id = v.Id;
				vendor.Name = v.Name;
				vendor.Categories = '';
				vendor.Checked = false;
				vendor.Distributed = vendorsAlreadyDistributed.contains(v.Id) ?? false;

				if(vendor.Distributed == true){
					vendorsDistributed.add(vendor);
				}else{
					vendorsNotDistributed.add(vendor);
				}
			}

			vendors.addAll(vendorsNotDistributed);
			vendors.addAll(vendorsDistributed);
			vendorList.remainingVendors.addAll(vendors);
		}

		return vendorList;
	}

	@TestVisible
	public class VendorList {
		@AuraEnabled public List<Vendor> matchingVendors;
		@AuraEnabled public List<Vendor> remainingVendors;
	}

	@TestVisible
	public class Vendor {
		@AuraEnabled public Id Id;
		@AuraEnabled public String Name;
		@AuraEnabled public String Categories;
		@AuraEnabled public Boolean Checked;
		@AuraEnabled public Boolean Distributed;
	}

	// TODO in the future add the customer ID as a parameter and get all vendors relevant to the customer
	public static Set<Id> getVendorsAlreadyDistributed(Id positionId){
		Set<Id> vendorsAlreadyDistributed = new Set<Id>();
		
		Map<Id, Account> vendorMap = new Map<Id, Account>([SELECT Id FROM Account WHERE RecordTypeId = :SchemaUtils.getRecordTypeId('Account', 'Vendor')]);
		
		for(Vendor_position_application__c value : [SELECT Vendor__c FROM Vendor_position_application__c WHERE Vendor__c IN :vendorMap.keySet() AND Position__c = :positionId]){
			if(vendorMap.containsKey(value.Vendor__c)){
				vendorsAlreadyDistributed.add(value.Vendor__c);
			}
		}

		return vendorsAlreadyDistributed;
	}

	/*
		Get default contacts, and via default contacts get mail adresses from contact
		Then send mails to that email adresses
	*/
	@AuraEnabled()
	public static void sendToVendors(Id positionId, List<Id> vendorIds){
		Position__c p = [SELECT Id, End_date__c, Hiring_manager__c, Deadline_candidate_submission__c FROM Position__c WHERE Id = :positionId LIMIT 1];

		// Get default contact id's
		List<Default_vendor_contact__c> defaultContacts = [SELECT Id, Contact__c, Vendor__c FROM Default_vendor_contact__c WHERE Vendor__c IN :vendorIds];
		
		List<Id> contactIds = new List<Id>();

		// Add Contact__c to list
		for(Default_vendor_contact__c contact : defaultContacts){
			contactIds.add(contact.Contact__c);
		}
		
		// Send mail to vendors
		sendMail(p, contactIds);

		// Create tasks for vendors
		createNewPositionTaskForVendors(p, vendorIds);

		// Creates connection between position and vendor
		handleCreateVendorPositionApplication(positionId, vendorIds);

		// Updates status and processing status
		Position__c updatePos = new Position__c();
		updatePos.Id = positionId;
		updatePos.Status__c = 'Open';
		updatePos.Processing_status__c = 'Distributed';
		update updatePos;
	}

	public static void sendMail(Position__c p, List<Id> contactIds){
		List<Messaging.SingleEmailMessage> sendList = new List<Messaging.SingleEmailMessage>();
		for(Id contactId : contactIds){
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setTemplateId(Mailtemplate_Mapping__mdt.getInstance('Position_to_Vendor').Mailtemplate_Id__c);
			mail.setWhatId(p.id);
			mail.setTargetObjectId(contactId);
			mail.setToAddresses(new List<String>{contactId});
			sendList.add(mail);
		}

		try {
			List<Messaging.SendEmailResult> mrs =  Messaging.sendEmail(sendList, false);
			System.debug(mrs);
			for(Messaging.SendEmailResult mr : mrs){
				if(mr.isSuccess() != true){
					throw new VendorsByCategoryControllerException('Mail not sent. Error: ' + mr.errors);
				}
			 }
		}catch (Exception e) {
		 	throw new AuraHandledException(e.getMessage());
		}
	}

	public static void createNewPositionTaskForVendors(Position__c p, List<Id> vendorIds){
		List<TaskHandler.TaskWrapper> taskWrappers = new List<TaskHandler.TaskWrapper>();
		
		Map<Id, User> users = new Map<Id, User>([SELECT Id FROM User WHERE ContactId IN (SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c IN :vendorIds)]);

		for(Id userId : users.keySet()){
			TaskHandler.TaskWrapper wrapperNewPosition = new TaskHandler.TaskWrapper('new_position_for_vendor', p.Id, userId, p.Deadline_candidate_submission__c);
			taskWrappers.add(wrapperNewPosition);
		}

		if(taskWrappers.size() > 0){
			TaskHandler.createTasks(taskWrappers);
		}
	}

	@TestVisible
	private static Database.SaveResult [] handleCreateVendorPositionApplication(Id recordId, List<Id> vendorIds) {
		Position__c pos = [SELECT Id FROM Position__c WHERE Id =: recordId LIMIT 1];

		List<Vendor_position_application__c> vendorPositionConnections = new List<Vendor_position_application__c>();

		for (Id vendorId: vendorIds) {
			Vendor_position_application__c conn = new Vendor_position_application__c();

			conn.Position__c = recordId;
			conn.Vendor__c = vendorId;

			vendorPositionConnections.add(conn);
		}

		Database.SaveResult[] res = Database.insert(vendorPositionConnections);

		return res;
	}
}