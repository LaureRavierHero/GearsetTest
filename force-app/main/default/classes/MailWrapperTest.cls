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
private class MailWrapperTest {

    @isTest
    static void testCreateWrapperFindTemplate() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c pos = TestDataFactory.getPosition(false);
        pos.Hourly_rate__c = 60;
        Account v = TestDataFactory.getVendor();

        insert v;
        Default_vendor_contact__c cont = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id];
        Mailtemplate__c mt = TestDataFactory.getMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.');
        
        System.runAs(u) {
            insert pos;
            insert mt;

            Mailtemplate_account__c connector = TestDataFactory.connectMailTemplateAccount(u.AccountId__c, mt.Id, 'Distribution_email');

            insert connector;

            MailWrapper mw = new MailWrapper(pos.Id, cont.Contact__c, 'Distribution_email', false);
        }
    }

    @isTest
    static void testCreateDontFindTemplate() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c pos = TestDataFactory.getPosition(false);
        pos.Hourly_rate__c = 60;

        Account v = TestDataFactory.getVendor();

        insert v;
        Default_vendor_contact__c cont = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id];

        Mailtemplate__c mt = TestDataFactory.getMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.');
        
        System.runAs(u) {
            try {
                insert pos;
                insert mt;

                Test.startTest();
                MailWrapper mw = new MailWrapper(pos.Id, cont.Contact__c, 'Distribution_email', false);
                Test.stopTest();

                System.Assert.fail();
            }
            catch (Exception e) {
                System.assertEquals('MailWrapper.MailWrapperException', e.getTypeName());
            }
        }
    }
}