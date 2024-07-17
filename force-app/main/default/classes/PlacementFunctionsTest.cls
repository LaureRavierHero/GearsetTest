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
private class PlacementFunctionsTest {

    @isTest
    static void createPlacement() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        a.Hiring_desk_queue_id__c = SchemaUtils.getQueueIdFromName('Aspen hiring desk');
        
        insert a;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        Candidate__c cand = new Candidate__c();
        cand.First_name__c = 'First';
        cand.Last_name__c = 'Name';
        cand.Email__c = '01234@test.nl';
        cand.Phone__c = '0123456789';

        insert cand;

        Application__c app = TestDataFactory.getApplication('Bee', 'Worker', p, v);
        app.Candidate__c = cand.Id;

        insert app;

        Test.startTest();
        PlacementFunctions.createPlacement(app.Id);
        Test.stopTest();

        List<Application__c> apps = [SELECT Id, Professional__c FROM Application__c WHERE Id = :app.Id];

        System.assertEquals(1, apps.size(), 'Wrong number of applications found associated with professional');
        System.assert(String.isNotBlank(apps[0].Professional__c));
        
        List<Placement__c> placements = [SELECT Id, Name FROM Placement__c];

        System.assertEquals(1, placements.size(), 'Wrong number of placements found');

    }
}