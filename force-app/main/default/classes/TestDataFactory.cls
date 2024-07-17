@istest
public class TestDataFactory {
	/* TODO: find another solution for this? This is NOT great for if we ever want to add other languages. */
	public static Profile getProfile() {
		Profile p = [SELECT Id FROM Profile WHERE Id = :System.Label.ApexSystemAdminProfileId][0];
		return p;
	}

	public static User getPortalUser(Account a, Contact c) {
		
		Profile p = [SELECT id FROM profile WHERE Name = 'Aspen hiring manager' limit 1];
		String testemail = 'test@test.com';
		User pu = new User(profileId = p.id, username = testemail, email = testemail,
			emailencodingkey = 'UTF-8', localesidkey = 'en_US',
			languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
			alias='cspu', lastname='lastname', contactId = c.id);
		return pu;
	}

	public static void addPermissionSetToUser(User u, String permissionSetApiName) {
		Id pid = SchemaUtils.getPermissionSetId(permissionSetApiName);
		System.debug('Permission set id: ' + pid);
		PermissionSetAssignment psa = new PermissionSetAssignment
		(PermissionSetId = pid, AssigneeId = u.Id);

		insert psa;
	}

	public static User getPortalUserVendor(Account a, Contact c) {
		
		Profile p = [SELECT id FROM profile WHERE Name = 'Vendor' limit 1];
		String testemail = 'testSuperUniqueBla1245@test.com';
		User pu = new User(profileId = p.id, username = testemail, email = testemail,
			emailencodingkey = 'UTF-8', localesidkey = 'en_US',
			languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
			alias='cspu', lastname='lastname', contactId = c.id);
		return pu;
	}

	public static User getUser() {
		/* Account name has to exist in global picklist of account names */
		Profile p = getProfile();
		Account acc = getAccount(System.Label.ApexStandardAccountName);
		insert acc;
		User u = new User();
		u.Account_name__c = acc.Name;
		u.AccountId__c = acc.Id;
		u.Alias = 'standt'; 
		u.Email='standarduser@testorg.com';
		u.EmailEncodingKey='UTF-8';
		u.LastName='Testing';
		u.LanguageLocaleKey='en_US';
		u.LocaleSidKey='en_US';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey='America/Los_Angeles';
		u.UserName='testuser@customization-7768--test.com';
		
		return u;
	}

	public static User getUserNoAccount() {
		/* Account name has to exist in global picklist of account names */
		Profile p = getProfile();
		User u = new User();
		u.Alias = 'standt'; 
		u.Email='standarduser@testorg.com';
		u.EmailEncodingKey='UTF-8';
		u.LastName='Testing';
		u.LanguageLocaleKey='en_US';
		u.LocaleSidKey='en_US';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey='America/Los_Angeles';
		u.UserName='testuser@customization-7768--test.com';
		
		return u;
	}

	public static User getUser(Account a) {
		Profile p = getProfile();
		User u = new User();
		u.Account_name__c = a.Name;
		u.AccountId__c = a.Id;
		u.Alias = 'standt'; 
		u.Email='standarduser@testorg.com';
		u.EmailEncodingKey='UTF-8';
		u.LastName='Testing';
		u.LanguageLocaleKey='en_US';
		u.LocaleSidKey='en_US';
		u.ProfileId = p.Id;
		u.TimeZoneSidKey='America/Los_Angeles';
		u.UserName='testuser@customization-7768--test.com';
		
		return u;
	}

	public static Mailtemplate__c	getMailTemplate(String subject, String message) {
		Mailtemplate__c mt = new Mailtemplate__c();

		mt.Subject__c = subject;
		mt.Message__c = message;

		return mt;
	}

	public static Mailtemplate_account__c 		connectMailTemplateAccount(Id accountId, Id templateId, string mailType) {
		Mailtemplate_account__c mtc = new Mailtemplate_account__c();

		mtc.Name = accountId + '_' + templateId + '_' + mailType.replaceAll('(\\s)', '_');
		mtc.Mailtemplate__c = templateId;
		mtc.Account__c = accountId;
		mtc.Type_of_mail__c = mailType;

		return mtc;
	}

	public static Mailtemplate__c	getConnectedMailTemplate(String subject, String message, String mailType) {
		Account acc = getAccount('Test account');
		Mailtemplate__c mt = getMailTemplate(subject, message);

		insert acc;
		insert mt;

		Mailtemplate_account__c mtc = connectMailTemplateAccount(acc.Id, mt.Id, mailType);
		insert mtc;

		return mt;
	}

	public static Mailtemplate__c	getConnectedMailTemplate(String subject, String message, String mailType, 
	Account acc) {
		Mailtemplate__c mt = getMailTemplate(subject, message);

		insert mt;

		Mailtemplate_account__c mtc = connectMailTemplateAccount(acc.Id, mt.Id, mailType);
		insert mtc;

		System.debug('Connector ' + mtc);
		return mt;
	}

	public static Account getAccount(String name) {
		Account acc = new Account();
		acc.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Customer');
		acc.Hiring_desk_email__c = 'test@test.nl';
		acc.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
		acc.Hiring_desk_queue_id__c = SchemaUtils.getQueueIdFromName('Hiring desk queue');
		acc.Email__c = 'test@test.nl';
		acc.Name = name;

		return acc;
	}

	public static Account getAccount() {
		return getAccount(System.Label.ApexStandardAccountName);
	}

	public static Account getVendor(String vendorName) {
		Account vend = new Account();
		vend.RecordTypeId = SchemaUtils.getRecordTypeId('Account', 'Vendor');
		vend.Email__c = 'test1@test.nl';
		vend.Name = vendorName;

		return vend;
	}

	public static Account getVendor() {
		return getVendor('Test Vendor');
	}

	public static Contact getVendorContact(String firstName, String preposition, String lastName) {
		Account vend = getVendor();

		insert vend;

		Contact c = new Contact();
		c.RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Default vendor contact');
		c.FirstName = firstName;
		c.LastName = lastName;
		c.AccountId = vend.Id;
		c.Email = 'test@test.nl';
		return c;
	}
	public static Contact getVendorContact(Account acc, String firstName, String preposition, String lastName) {

		Contact c = new Contact();
		c.RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Default vendor contact');
		c.FirstName = firstName;
		c.LastName = lastName;
		c.AccountId = acc.Id;
		c.Email = 'test@test.nl';
		return c;
	}

	public static Contact getVendorContact(String firstName, String lastName) {
		return getVendorContact(firstName, '', lastName);
	}

	public static Position__c getPosition(Boolean addAccount) {
		Position__c pos = new Position__c();
		pos.RecordTypeId = Schema.SObjectType.Position__c.getRecordTypeInfosByName().get('Aspen').getRecordTypeId();
		if (addAccount) {
			Account acc = getAccount();
		
			insert acc;

			pos.Account__c = acc.Id;
		}
		pos.Number_of_hires__c = '1';
		return pos;
	}

	public static Candidate__c getCandidate(String firstName, String preposition, String lastName, 
	Account vend) {
		Candidate__c c = new Candidate__c();
		c.Vendor__c = vend.Id;
		c.First_name__c = firstName;
		c.Preposition__c = preposition;
		c.Last_name__c = lastName;

		return c;
	}

	public static Candidate__c getCandidate(String firstName, String preposition, String lastName) {
		Account vend = getVendor();

		insert vend;

		return getCandidate(firstName, preposition, lastName, vend);
	}

	public static Candidate__c getCandidate(String firstName, String lastName) {
		return getCandidate(firstName, '', lastName);
	}

	public static Candidate__c getCandidate(String firstName, String lastName, Account vend) {
		return getCandidate(firstName, '', lastName, vend);
	}


	public static Candidate__c getCandidate() {
		return getCandidate('Test', 'von der', 'Testerton');
	}

	public static Candidate__c getCandidate(Account vend) {
		return getCandidate('Test', 'von der', 'Testerton', vend);
	}

	public static Contact getProfessional(String firstName, String preposition, String lastName) {
		Contact prof = new Contact();

		prof.RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Professional');
		prof.FirstName = firstName;
		prof.LastName = String.isNotBlank(preposition)?preposition + ' ': '';
		prof.LastName += lastName;
		return prof;
	}

	public static Contact getProfessional(String firstName, String lastName) {
		return getProfessional(firstName, '', lastName);
	}

	public static Application__c getApplication(Candidate__c can) {
		Position__c pos = getPosition(true);

		insert pos;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = can.Vendor__c;

		return app;
	}

	public static Application__c	getApplication(Position__c pos, Account vend) {
		Candidate__c can = getCandidate(vend);
		can.Vendor__c = vend.Id;

		insert can;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = vend.Id;

		return app;
	}

	public static Application__c getApplication(String candidateFirstName, String candidateLastName) {
		Position__c pos = getPosition(false);
		Candidate__c can = getCandidate(candidateFirstName, candidateLastName);

		insert can;
		insert pos;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = can.Vendor__c;

		return app;
	}

	public static Application__c getApplication(String candidateFirstName, String candidateLastName, Account vend) {
		Position__c pos = getPosition(false);
		Candidate__c can = getCandidate(candidateFirstName, candidateLastName, vend);

		insert can;
		insert pos;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = can.Vendor__c;

		return app;
	}

	public static Application__c getApplication(String candidateFirstName, String candidateLastName, Position__c p, Account vend) {
		Candidate__c can = getCandidate(candidateFirstName, candidateLastName, vend);

		insert can;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = p.Id;
		app.Vendor__c = can.Vendor__c;

		return app;
	}

	public static Application__c getApplicationWithCv(String candidateFirstName, String candidateLastName, 
	Position__c pos, Account vendor) {
		Candidate__c can = getCandidate(candidateFirstName, candidateLastName, vendor);

		insert can;

		Application__c app = new Application__c();
		app.Status__c = 'New';
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = vendor.Id;
		insert app;

		Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
			
		ContentVersion contentVersion = new ContentVersion(
			Title='CV_test', 
			PathOnClient ='CV_test.pdf',
			VersionData = bodyBlob, 
			origin = 'H'
		);
		insert contentVersion;

		ContentVersion cv = [SELECT contentdocumentid, Id FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
		ContentDocumentLink contentlink = new ContentDocumentLink();
		contentlink.LinkedEntityId = app.id;
		contentlink.contentdocumentid =cv.contentdocumentid;
		contentlink.ShareType = 'V';
		insert contentlink;

		return app;
	}

	public static Application__c getApplicationWithCv(String candidateFirstName, String candidateLastName) {
		Position__c pos = getPosition(true);
		Candidate__c can = getCandidate(candidateFirstName, candidateLastName);

		insert can;
		insert pos;

		Contact vc = getVendorContact(can.Vendor__c, 'Bobby', 'Singer');
		insert vc;

		Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = can.Account__c;
		app.Candidate__c = can.Id;
		app.Position__c = pos.Id;
		app.Vendor__c = can.Vendor__c;
		insert app;

		Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
			
		ContentVersion contentVersion = new ContentVersion(
			Title='CV_test', 
			PathOnClient ='CV_test.pdf',
			VersionData = bodyBlob, 
			origin = 'H'
		);
		insert contentVersion;

		ContentVersion cv = [SELECT contentdocumentid, Id FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
		ContentDocumentLink contentlink = new ContentDocumentLink();
		contentlink.LinkedEntityId = app.id;
		contentlink.contentdocumentid =cv.contentdocumentid;
		contentlink.ShareType = 'V';
		insert contentlink;

		return app;
	}

	public static Async_Request__c getAsyncWithOneAttempt(Id recordId) {
		return new Async_Request__c(
			Type__c = 'updateCandidate',
			Record_Id__c = recordId,
			Last_Runtime__c = System.now().addMinutes(-10),
			Attempts__c = 3,
			Status__c = 'Error'
		);
	}

	public static Category__c getCategory(String categoryName) {
		Category__c cat = new Category__c();
		cat.Name = categoryName;

		return cat;
	}

	public static Position_category__c getPositionCategory(Id positionId, Id categoryId) {
		Position_category__c cat = new Position_category__c();
		cat.Position__c = positionId;
		cat.Category__c = categoryId;

		return cat;
	}

	public static Vendor_contact_categories__c getVendorCategory(Id vendorId, Id categoryId) {
		Vendor_contact_categories__c cat = new Vendor_contact_categories__c();
		cat.Vendor__c = vendorId;
		cat.Category__c = categoryId;

		return cat;
	}

	public static Contact getContact(){
		Contact c = new Contact();
		c.FirstName = 'test';
		c.LastName = 'test';
		c.Phone = '02341782673';
		c.Email = 'bla@bloe.bleh';
		return c;
	}

	public static Contact getContact(String firstName, String lastName, Account a) {
		Contact c = new Contact();

		c.FirstName = firstName;
		c.LastName = lastName;
		c.AccountId = a.Id;
		return c;
	}

	public static Default_Vendor_Contact__c getDefaultVendorContact(Account v, Contact c) {
		Default_Vendor_Contact__c dvc = new Default_Vendor_Contact__c();
		dvc.Vendor__c = v.Id;
		dvc.Contact__c = c.Id;
		return dvc;
	}

	public static Placement__c getPlacementWithRatePercentage(){
		Account acc = getAccount();
        insert acc;

        Account accVendor = getVendor('testVendor');
		insert accVendor;

        Contact c = getVendorContact(accVendor, 'firstnameUnique12345', '', 'lastnameUniquer356');
		c.email = 'testnogeens1@getplacement.com';
		insert c;

		User u = getPortalUserVendor(accVendor, c);
		insert u;

		Default_Vendor_Contact__c dvc = getDefaultVendorContact(accVendor, c);
		insert dvc; 

        Placement__c pl = new Placement__c();
        pl.Vendor__c = accVendor.Id;
        pl.Name = 'test';
        pl.Account__c = acc.Id;
        insert pl;

        Rate_Percentage__c ratePercentage = getRatePercentage();
		ratePercentage.Is_standard__c = true;
        ratePercentage.Account__c = acc.Id;
		insert ratePercentage;
	
		Placement_rate_percentage__c placementRatePercentage = new Placement_rate_percentage__c();
		placementRatePercentage.Placement__c = pl.Id;
		placementRatePercentage.Rate_Percentage__c = ratePercentage.Id;
		insert placementRatePercentage;

		return pl;
	}

	public static Placement__c getPlacement(){
		Account acc = getVendor('testVendor');
		insert acc;

		Contact c  = getVendorContact(acc, 'firstnameUnique12345', '', 'lastnameUniquer356');
		c.email = 'testnogeens1@getplacement.com';
		insert c;

		User u = getPortalUserVendor(acc, c);
		insert u;

		Default_Vendor_Contact__c dvc = getDefaultVendorContact(acc, c);
		insert dvc; 

		Placement__c placement = new Placement__c();
		placement.Name = 'test';
		placement.Vendor__c = acc.Id;
		return placement;
	}

	public static Timesheet__c getTimesheet(){
		Timesheet__c timesheet = new Timesheet__c();
		timesheet.Name = 'test';
		return timesheet;
	}

	public static Timesheet_entry__c getTimesheetEntry(){
		Timesheet_entry__c timesheetEntry = new Timesheet_entry__c();
		timesheetEntry.Name = 'test';
		return timesheetEntry;
	}

	public static Rate_percentage__c getRatePercentage(){
		Rate_percentage__c ratePercentage = new Rate_percentage__c();
		return ratePercentage;
	}

	public static Timesheet__c getTimesheetComplete(Id contactId){
		Placement__c placement = TestDataFactory.getPlacement();
		placement.Professional__c = contactId;
		insert placement;
		
		Rate_Percentage__c ratePercentage = TestDataFactory.getRatePercentage();
		insert ratePercentage;
	
		Placement_rate_percentage__c placementRatePercentage = new Placement_rate_percentage__c();
		placementRatePercentage.Placement__c = placement.Id;
		placementRatePercentage.Rate_Percentage__c = ratePercentage.Id;
		insert placementRatePercentage;
	
		Timesheet__c timesheet = TestDataFactory.getTimesheet();
		timesheet.Placement__c = placement.Id;
		
		return timesheet;
	}

	public static List<Timesheet_entry__c> getTimesheetEntries(Id timesheetId){
		List<Timesheet_entry__c> returnList = new List<Timesheet_entry__c>();

		Timesheet_entry__c timesheetEntry = getTimesheetEntry();
		timesheetEntry.Timesheet__c = timesheetId;
		timesheetEntry.Date__c = System.today();
		timesheetEntry.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry);

		Timesheet_entry__c timesheetEntry1 = getTimesheetEntry();
		timesheetEntry1.Timesheet__c = timesheetId;
		timesheetEntry1.Date__c = System.today().addDays(1);
		timesheetEntry1.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry1);

		Timesheet_entry__c timesheetEntry2 = getTimesheetEntry();
		timesheetEntry2.Timesheet__c = timesheetId;
		timesheetEntry2.Date__c = System.today().addDays(2);
		timesheetEntry2.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry2);

		Timesheet_entry__c timesheetEntry3 = getTimesheetEntry();
		timesheetEntry3.Timesheet__c = timesheetId;
		timesheetEntry3.Date__c = System.today().addDays(3);
		timesheetEntry3.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry3);

		Timesheet_entry__c timesheetEntry4 = getTimesheetEntry();
		timesheetEntry4.Timesheet__c = timesheetId;
		timesheetEntry4.Date__c = System.today().addDays(4);
		timesheetEntry4.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry4);

		Timesheet_entry__c timesheetEntry5 = getTimesheetEntry();
		timesheetEntry5.Timesheet__c = timesheetId;
		timesheetEntry5.Date__c = System.today().addDays(5);
		timesheetEntry5.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry5);

		Timesheet_entry__c timesheetEntry6 = getTimesheetEntry();
		timesheetEntry6.Timesheet__c = timesheetId;
		timesheetEntry6.Date__c = System.today().addDays(6);
		timesheetEntry6.RecordTypeId = SchemaUtils.getRecordTypeId('Timesheet_entry__c', 'Default');
		returnList.add(timesheetEntry6);

		return returnList;
	}

	public static ProcessInstanceWorkItem getProcessInstanceWorkItem(){
		ProcessInstanceWorkItem PiWi = new ProcessInstanceWorkItem ();
		return PiWi;
	}

	public static ProcessDefinition getProcessDefinition(){
		ProcessDefinition pd = new ProcessDefinition();
		return pd;
	}

	public static Vendor_position_application__c getPositionLinkedToVendor(Account vend, Position__c pos) {
		Vendor_position_application__c vpa = new Vendor_position_application__c();

		vpa.Vendor__c = vend.Id;
		vpa.Position__c = pos.Id;
		return vpa;
	}
}