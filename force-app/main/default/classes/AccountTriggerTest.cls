@isTest
private class AccountTriggerTest {
	@isTest
	static void createDefaultHiringDeskContactTest() {
		Account a = TestDataFactory.getAccount();
		a.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Customer');
		a.Hiring_Desk_Email__c = 'test@hero.eu';

		Test.startTest();
		insert a;
		Test.stopTest();

		Default_hiring_desk_contact__c dc = [SELECT Id FROM Default_hiring_desk_contact__c WHERE Account__c = :a.Id];

		System.assert(dc != null);
	}

	@isTest
	static void createDefaultVendorContactTest() {
		Account a = TestDataFactory.getAccount();
		a.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Vendor');
		a.Email__c = 'test@hero.eu';

		Test.startTest();
		insert a;
		Test.stopTest();

		Default_vendor_contact__c dc = [SELECT Id FROM Default_vendor_contact__c WHERE Vendor__c = :a.Id];

		System.assert(dc != null);
	}

	@isTest
	static void updateDefaultHiringDeskContactTest() {
		Account a = TestDataFactory.getAccount();
		a.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Customer');
		a.Hiring_Desk_Email__c = 'test1@hero.eu';

		insert a;

		a.Hiring_Desk_Email__c = 'test@hero.eu';
		
		Test.startTest();
		update a;
		Test.stopTest();

		Default_hiring_desk_contact__c dc = [SELECT Id, Contact__c FROM Default_hiring_desk_contact__c WHERE Account__c = :a.Id];
		Contact c = [SELECT Email FROM Contact WHERE Id=:dc.Contact__c LIMIT 1];
		System.assert(c.Email == 'test@hero.eu');
	}

	@isTest
	static void updateDefaultVendorContactTest() {
		Account a = TestDataFactory.getAccount();
		a.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Vendor');
		a.Email__c = 'test1@hero.eu';

		insert a;

		a.Email__c = 'test@hero.eu';
		
		Test.startTest();
		update a;
		Test.stopTest();

		Default_vendor_contact__c dc = [SELECT Id, Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :a.Id];
		Contact c = [SELECT Email FROM Contact WHERE Id=:dc.Contact__c LIMIT 1];
		System.assert(c.Email == 'test@hero.eu');
	}
}