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
private class VendorPositionApplicationHandlerTest {

    @isTest
    static void testShareWithVendor() {
        Account v = TestDataFactory.getVendor();
        insert v;

        Contact c = [SELECT Id FROM Contact WHERE Id IN (SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id) LIMIT 1];

        User u = TestDataFactory.getPortalUser(v, c);
        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        insert p;

        Vendor_position_application__c vpa = new Vendor_position_application__c();
        vpa.Vendor__c = v.Id;
        vpa.Position__c = p.Id;
        insert vpa;

        List<Position__Share> shares = [SELECT Id, UserOrGroupId, AccessLevel, 
        RowCause FROM Position__Share WHERE ParentId = :p.Id AND UserOrGroupId= :u.Id];

        System.assertEquals(1, shares.size());

        System.assertEquals(shares[0].AccessLevel, 'Read');
        System.assertEquals(shares[0].RowCause, Schema.Position__Share.RowCause.Hiring_desk_to_vendor__c);
    }
}