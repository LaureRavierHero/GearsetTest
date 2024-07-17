@istest
public class HeroSalesforceConnectorTest {
	@istest
	public static void executeCreateTest(){
		Account a = TestDataFactory.getAccount();
        a.Hiring_desk_queue_id__c = SchemaUtils.getQueueIdFromName('Aspen hiring desk');
		a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Inhuur', a);

        insert c;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
		p.Hiring_manager__c = c.Id;

        insert p;

        Account v = TestDataFactory.getVendor();
		insert v;

		Candidate__c cand = new Candidate__c();
		cand.First_name__c = 'Bob';
		cand.Last_name__c = 'Bob';

		insert cand;

        Application__c app = new Application__c();
		app.RecordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
		app.Account__c = a.Id;
		app.Vendor__c = v.Id;
		app.Position__c = p.Id;
		app.Candidate__c = cand.Id;

        insert app;

		Contact professional = new Contact();
		professional.FirstName = 'prof';
		professional.LastName = 'Essional';
		insert professional;

		Placement__c pl = new Placement__c(
			Account__c = a.Id,
			Vendor__c = v.Id,
			Application__c = app.Id,
			Professional__c = professional.Id
		);

		insert pl;

        Test.setMock(HttpCalloutMock.class, new HeroSalesforceConnectionMock());

		Test.startTest();
		HeroSalesforceConnector.executeCreate(pl.Id);
		Test.stopTest();
	}

    // @istest
    // public static void executeUpdateTest(){
	// 	Placement__c p = new Placement__c();
	// 	insert p;

    //     Test.setMock(HttpCalloutMock.class, new HeroSalesforceConnectionMock());

	// 	Test.startTest();
	// 	HeroSalesforceConnector.executeUpdate(p.Id);
	// 	Test.stopTest();

	// 	// TODO assert
	// }

	// @istest
	// public static void getAuthProviderValuesTest(){

	// }

	// TODO get authprovidervalues & getplacement testen
}