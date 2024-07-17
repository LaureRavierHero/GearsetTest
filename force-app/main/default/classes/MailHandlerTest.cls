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
private class MailHandlerTest {

    @isTest
    static void testMailSingleRecipient() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c pos = TestDataFactory.getPosition(false);
        Account v = TestDataFactory.getVendor();

        insert v;
        Default_vendor_contact__c cont = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id];
        pos.Hourly_rate__c = 60;
        Mailtemplate__c mt = TestDataFactory.getMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.');
        
        List<SchemaUtils.PicklistItem> options = SchemaUtils.getPicklistOptions('Mailtemplate_account__c', 'Type_of_mail__c');
        String option = options[0].itemName;
        System.runAs(u) {
            insert pos;
            insert mt;

            Mailtemplate_account__c connector = TestDataFactory.connectMailTemplateAccount(u.AccountId__c, mt.Id, option);

            insert connector;

            MailWrapper mw = new MailWrapper(pos.Id, cont.Contact__c, option, false);

            MailHandler.sendEmail(mw);
        }
    }

    @isTest
    static void testMailMultipleRecipients() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c pos = TestDataFactory.getPosition(false);
        pos.Hourly_rate__c = 60;
        
        Account v1 = TestDataFactory.getVendor('T1');
        Account v2 = TestDataFactory.getVendor('T2');

        insert new List<Account>{v1, v2};

        Default_vendor_contact__c c1 = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v1.Id];
        Default_vendor_contact__c c2 = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v2.Id];

        Mailtemplate__c mt = TestDataFactory.getMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.');
        
        System.runAs(u) {
            insert pos;
            insert mt;

            Mailtemplate_account__c connector = TestDataFactory.connectMailTemplateAccount(u.AccountId__c, mt.Id, 'Distribution_email');

            insert connector;

            MailWrapper mw = new MailWrapper(pos.Id, new List<Id>{c1.Contact__c, c2.Contact__c}, 'Distribution_email', false);

            MailHandler.sendEmail(mw);
        }
    }

    @isTest
    static void testMailSingleRecipientNoEmailAddress() {
        User u = TestDataFactory.getUser();

        insert u;

        Position__c pos = TestDataFactory.getPosition(false);
        pos.Hourly_rate__c = 60;
        Account v = TestDataFactory.getVendor();

        insert v;
        Default_vendor_contact__c cont = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id];
        Contact c = [SELECT Id, Email FROM Contact WHERE Id = :cont.Contact__c LIMIT 1];

        c.Email = '';
        update c;

        Mailtemplate__c mt = TestDataFactory.getMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.');
        
        System.runAs(u) {
            try {
                insert pos;
                insert mt;

                Mailtemplate_account__c connector = TestDataFactory.connectMailTemplateAccount(u.AccountId__c, mt.Id, 'Distribution_email');

                insert connector;

                MailWrapper mw = new MailWrapper(pos.Id, c.Id, 'Distribution_email', false);

                MailHandler.sendEmail(mw);
                System.Assert.fail();
            }
            catch (Exception e) {}
        }
    }

    @isTest
    static void testMailOneTemplateMultipleRecordsOneRecipient() {
        User u = TestDataFactory.getUser();
        insert u;
        
        Position__c pos1 = TestDataFactory.getPosition(false);
        pos1.Hourly_rate__c = 60;
        Position__c pos2 = TestDataFactory.getPosition(false);
        pos2.Hourly_rate__c = 120;
        
        Account v = TestDataFactory.getVendor();

        insert v;
        Default_vendor_contact__c cont = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id];
        Contact c = [SELECT Id, Email FROM Contact WHERE Id = :cont.Contact__c LIMIT 1];

        System.runAs(u) {
            List<SchemaUtils.PicklistItem> options = SchemaUtils.getPicklistOptions('Mailtemplate_account__c', 'Type_of_mail__c');
            String type = options[0].itemName;

            Id accId = u.AccountId__c;
            Account acc = [SELECT Name, Id FROM Account WHERE Id = :accId];

            insert pos1;
            insert pos2;

            Mailtemplate__c mt = TestDataFactory.getConnectedMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.', type, acc);

            List<MailWrapper> mailWrappers = new List<MailWrapper>();
            mailWrappers.add(new MailWrapper(pos1.Id, c.Id, type));
            mailWrappers.add(new MailWrapper(pos2.Id, c.Id, type));

            Messaging.SendEmailResult[] res = MailHandler.sendEmails(mailWrappers);
            System.assertEquals(2, res.size());
            for (Messaging.SendEmailResult r: res) {
                System.assert(r.isSuccess());
            }
        }
    }

    @isTest
    static void testMailMultipleTemplatesMultipleRecordsMultipleRecipients() {
        User u = TestDataFactory.getUser();
        insert u;
        
        Position__c pos1 = TestDataFactory.getPosition(false);
        pos1.Hourly_rate__c = 60;
        Position__c pos2 = TestDataFactory.getPosition(false);
        pos2.Hourly_rate__c = 120;
        Account v1 = TestDataFactory.getVendor('T1');
        Account v2 = TestDataFactory.getVendor('T2');

        insert new List<Account>{v1, v2};

        Default_vendor_contact__c c1 = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v1.Id];
        Default_vendor_contact__c c2 = [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v2.Id];

        System.runAs(u) {
            List<SchemaUtils.PicklistItem> options = SchemaUtils.getPicklistOptions('Mailtemplate_account__c', 'Type_of_mail__c');
            String type1 = options[0].itemName;
            String type2 = options[1].itemName;

            System.debug('Types: ' + type1 + type2);
            Id accId = u.AccountId__c;
            Account acc = [SELECT Name, Id FROM Account WHERE Id = :accId];

            insert pos1;
            insert pos2;

            Mailtemplate__c mt1 = TestDataFactory.getConnectedMailTemplate('New position: {{Name}}', 'Please find us some peeps for {{Hourly_rate__c}}.', type1, acc);
            Mailtemplate__c mt2 = TestDataFactory.getConnectedMailTemplate('Some other mail: {{Name}}', 'This is too much!! {{Hourly_rate__c}}.', type2, acc);
            List<MailWrapper> mailWrappers = new List<MailWrapper>();
            List<Id> recipients = new List<Id>{c1.Contact__c, c2.Contact__c};
            mailWrappers.add(new MailWrapper(pos1.Id, c1.Contact__c, type1));
            mailWrappers.add(new MailWrapper(pos1.Id, recipients, type2));
            mailWrappers.add(new MailWrapper(pos2.Id, recipients, type1));
            mailWrappers.add(new MailWrapper(pos2.Id, recipients, type2));

            Test.startTest();
            Messaging.SendEmailResult[] res = MailHandler.sendEmails(mailWrappers);
            Test.stopTest();
            
            System.assertEquals(4, res.size());
            for (Messaging.SendEmailResult r: res) {
                System.assert(r.isSuccess());
            }
        }
    }
}