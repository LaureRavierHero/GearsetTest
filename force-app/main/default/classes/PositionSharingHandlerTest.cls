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
private class PositionSharingHandlerTest {

    @isTest
    static void testShareWithHiringDesk() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', a);

        insert c;

        User hiringManager = TestDataFactory.getPortalUser(a, c);

        insert hiringManager;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;

        insert p;

        PositionSharingHandler.shareRecordWithHiringDesk(p.Id);

        List<Position__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Position__Share WHERE ParentId = :p.Id AND UserOrGroupId= :SchemaUtils.getGroupByName('Hero hiring desk')];

        System.assertEquals(1, shares.size());
        System.assertEquals(shares[0].AccessLevel, 'Edit');
        System.assertEquals(shares[0].RowCause, Schema.Position__Share.RowCause.Hiring_manager_to_hiring_desk__c);
    }
    
    @isTest
    static void testShareWithVendor() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);

        insert p;

        PositionSharingHandler.shareRecordWithVendors(p.Id, new List<Id>{u.Id});

        List<Position__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Position__Share WHERE ParentId = :p.Id AND UserOrGroupId= :u.Id];

        System.assertEquals(1, shares.size());
        System.assertEquals(shares[0].AccessLevel, 'Read');
        System.assertEquals(shares[0].RowCause, Schema.Position__Share.RowCause.Hiring_desk_to_vendor__c);
    }
}