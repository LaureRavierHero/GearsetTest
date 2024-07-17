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
private class ApplicationSharingHandlerTest {

    @isTest
    static void testShareWithHiringManager() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Inhuur', a);

        insert c;

        User HiringManager = TestDataFactory.getPortalUser(a, c);

        insert HiringManager;

        User Owner = TestDataFactory.getUserNoAccount();

        insert Owner;

        Position__c p = TestDataFactory.getPosition(false);

        p.Hiring_manager__c = c.Id;
        p.Account__c = a.Id;

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        List<Application__c> appList = new List<Application__c>();

        for (Integer i = 0; i < 8; ++i) {
            Application__c app = TestDataFactory.getApplication('Fn_' + i, 'Ln_' + i, p, v);
            app.OwnerId = Owner.Id;
            appList.add(app);
        }

        insert appList;

        List<Id> appIds = new List<Id>();
        for (Application__c app: appList) {
            appIds.add(app.Id);
        }

        ApplicationSharingHandler.shareRecordsWithHiringManager(p.Id, appIds, HiringManager.Id);

        List<Application__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Application__Share WHERE ParentId IN :appIds AND UserOrGroupId= :HiringManager.Id];

        System.assertEquals(8, shares.size());

        for (Application__Share s: shares) {
            System.assertEquals(s.AccessLevel, 'Edit');
            System.assertEquals(s.RowCause, Schema.Application__Share.RowCause.Hiring_manager__c);
        }
    }

    @isTest
    static void testShareWithHiringDesk() {
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

        insert app;

        ApplicationSharingHandler.shareRecordWithHiringDesk(app.Id);

        List<Application__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Application__Share WHERE ParentId = :app.Id AND UserOrGroupId= :SchemaUtils.getGroupByName('Hero hiring desk')];

        System.assertEquals(1, shares.size());

        System.assertEquals(shares[0].AccessLevel, 'Edit');
        System.assertEquals(shares[0].RowCause, Schema.Application__Share.RowCause.Hiring_desk__c);
    }
}