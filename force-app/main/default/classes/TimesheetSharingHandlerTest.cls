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
private class TimesheetSharingHandlerTest {

    @isTest
    static void shareWithApprover() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Inhuur', a);

        insert c;

        User HiringManager = TestDataFactory.getPortalUser(a, c);

        insert HiringManager;

        Timesheet__c t = new Timesheet__c();

        t.Approver__c = c.Id;

        insert t;

        TimesheetSharingHandler.shareRecordWithApprover(t.Id);

        List<Timesheet__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Timesheet__Share WHERE ParentId = :t.Id AND UserOrGroupId=:HiringManager.Id];

        System.assertEquals(1, shares.size());

        System.assertEquals(shares[0].AccessLevel, 'Edit');
        System.assertEquals(shares[0].RowCause, Schema.Timesheet__Share.RowCause.Approver__c);
    }
}