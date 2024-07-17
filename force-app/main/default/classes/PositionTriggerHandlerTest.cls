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
private class PositionTriggerHandlerTest {

    @istest
    static void  testAccountAdded() {
        Position__c p = TestDataFactory.getPosition(false);
        System.assert(TestUtils.accountWasAdded(p, 'Position__c'));
    }

    @istest
    static void testCreateTask(){
        Position__c pos = TestDataFactory.getPosition(false);
        pos.Deadline_candidate_submission__c = date.today();
        pos.Status__c = 'Open';


        Test.startTest();
        insert pos;
        Test.stopTest();

        List<Task> createdTask = [SELECT Id FROM Task];
        Assert.areEqual(2, createdTask.size());
    }

    // @isTest
    // static void testLockCategory() {

    //     Position__c pos = TestDataFactory.getPosition(false);
    //     pos.Status__c = 'Open';
    //     insert pos;

    //     Category__c cat = TestDataFactory.getCategory('IT');

    //     insert cat;

    //     Position_category__c pc = TestDataFactory.getPositionCategory(pos.Id, cat.Id);

    //     insert pc;

    //     Position__c updatePos = new Position__c();
    //     updatePos.Id = pos.Id;

    //     Test.startTest();
    //     updatePos.Processing_status__c = 'Distributed';
    //     update updatePos;

    //     pc = [SELECT Id FROM Position_category__c WHERE Position__c = :pos.Id LIMIT 1];
    //     Test.stopTest();
        
    //     System.assert(Approval.isLocked(pc.Id));
    // }

    @isTest
    static void testSetInitialStatus() {
        Position__c pos = TestDataFactory.getPosition(false);

        insert pos;

        Test.startTest();
        Position__c res = [SELECT Status__c, Processing_status__c FROM Position__c WHERE Id=:pos.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('New', res.Processing_status__c, 'Status not New after insert');
    }
}