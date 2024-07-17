/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ApplicationTriggerHandlerTest {
    // @isTest
    // static void testCreateTask() {
    //     Account a = TestDataFactory.getAccount();
    //     a.Hiring_desk_queue_id__c = SchemaUtils.getQueueIdFromName('Aspen hiring desk');
    //     a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');

    //     insert a;

    //     Contact c = TestDataFactory.getContact('Bob', 'Inhuur', a);

    //     insert c;

    //     Position__c p = TestDataFactory.getPosition(false);
    //     p.Account__c = a.Id;

    //     insert p;

    //     Candidate__c cand = new Candidate__c();
	// 	cand.First_name__c = 'Bob';
	// 	cand.Last_name__c = 'Bob';

	// 	insert cand;

    //     Application__c app = new Application__c();

	// 	app.Account__c = a.Id;
	// 	app.Position__c = p.Id;
	// 	app.Candidate__c = cand.Id;
    //     app.Status__c = 'Placement requested';

    //     insert app;

    //     // System.debug('POSITION TEST: ' + [SELECT Account__r.Hiring_desk_group_id__c FROM Position__c WHERE Id = :p.Id]);

    //     // Account v = TestDataFactory.getVendor();

    //     // Application__c app = new//TestDataFactory.getApplication(p.Id, a.Id);

    //     // app.Status__c = 'Placement requested';

    //     // insert app;

    //     List<Task> createdTask = [SELECT Id, Subject, OwnerId FROM Task ORDER BY CreatedDate DESC];

    //     Set<Id> ownerIds = DeveloperUtils.getIdFieldSet(createdTask, 'ownerId');
    //     System.assert(ownerIds.contains(a.Hiring_desk_queue_id__c));
    // }

    @isTest
    static void testNameFormat() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        Application__c app = TestDataFactory.getApplication('Bee', 'Worker', p, v);

        System.assert(TestUtils.nameAdded(app, 'Application__c', 'Bee Worker'));
    }

    @isTest
    static void checkEmptyRejectionReason() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', a);

        insert c;

        User Owner = TestDataFactory.getPortalUser(a, c);

        insert Owner;

        User hiringDesk = TestDataFactory.getUserNoAccount();

        insert hiringDesk;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        Application__c app = TestDataFactory.getApplication('Fn_', 'Ln_', p, v);

        app.Send_to_hiring_manager__c = 'No';
        app.Reason_rejection_hiring_desk__c = 'Distance';

        insert app;

        Test.startTest();

        app.Send_to_hiring_manager__c = 'Yes';

        update app;

        Test.stopTest();

        Application__c res = [SELECT Reason_rejection_hiring_desk__c FROM Application__c WHERE Id = :app.Id LIMIT 1];
        System.assertEquals(null, res.Reason_rejection_hiring_desk__c);
    }

    @isTest
    static void testIncreaseNumberApplicationsOffered() {Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', a);

        insert c;

        User Owner = TestDataFactory.getPortalUser(a, c);

        insert Owner;

        User hiringDesk = TestDataFactory.getUserNoAccount();

        insert hiringDesk;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;
        p.Max_number_of_applicants_per_supplier__c = '3';

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        Vendor_position_application__c conn = TestDataFactory.getPositionLinkedToVendor(v, p);

        insert conn;

        Application__c app = TestDataFactory.getApplication('Fn_', 'Ln_', p, v);

        app.Send_to_hiring_manager__c = 'No';
        app.Reason_rejection_hiring_desk__c = 'Distance';

        test.startTest();
        insert app;
        test.stopTest();
        
        conn = [SELECT Number_of_active_applications__c FROM Vendor_position_application__c WHERE Id = :conn.Id LIMIT 1];

        System.assertEquals(1, Integer.valueOf(conn.Number_of_active_applications__c));
    }
}