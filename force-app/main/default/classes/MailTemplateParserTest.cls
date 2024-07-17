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
private class MailTemplateParserTest {
    @isTest
    static void testMultipleTemplatesMultipleRecords() {
        Account vendor = TestDataFactory.getVendor();

        insert vendor;
        
        String subject1 = 'New candidate: {{First_name__c}} {{Last_name__c}}';
        String subject2 = 'New candidate! {{First_name__c}} {{Last_name__c}}!';
        String subject3 = 'New: {{First_name__c}} {{Last_name__c}}';

        String template1 = 'Dear {{First_name__c}} {{Last_name__c}}, we are pleased or something {{First_name__c}}{boe}';
        String template2 = 'Hello there {{First_name__c}}!';
        String template3 = 'Hello {{Last_name__c}}';

        Mailtemplate__c m1 = TestDataFactory.getMailTemplate(subject1, template1);
        Mailtemplate__c m2 = TestDataFactory.getMailTemplate(subject2, template2);
        Mailtemplate__c m3 = TestDataFactory.getMailTemplate(subject3, template3);

        insert new List<Mailtemplate__c>{m1, m2, m3};

        Candidate__c cand1 = TestDataFactory.getCandidate('Laure1', 'Test1', vendor);
        Candidate__c cand2 = TestDataFactory.getCandidate('Laure2', 'Test2', vendor);

        insert new List<Candidate__c>{cand1, cand2};

        Map<Id, Mailtemplate__c> templateByTemplateId = new Map<Id, Mailtemplate__c>{
            m1.Id => m1,
            m2.Id => m2,
            m3.Id => m3
        };

        Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>{
            m1.Id => new Set<Id>{cand1.Id, cand2.Id},
            m2.Id => new Set<Id>{cand2.Id},
            m3.Id => new Set<Id>{cand2.Id}
        };


        Test.startTest();
        Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> res = MailTemplateParser.parseEmailTemplates('Candidate__c', recordIdsByTemplateId, templateByTemplateId);
        Test.stopTest();
        
        System.assertEquals(res.get(m1.Id).get(cand1.Id).message, 'Dear Laure1 Test1, we are pleased or something Laure1{boe}');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).message, 'Dear Laure2 Test2, we are pleased or something Laure2{boe}');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).message, 'Hello there Laure2!');
        System.assertEquals(res.get(m3.Id).get(cand2.Id).message, 'Hello Test2');

        System.assertEquals(res.get(m1.Id).get(cand1.Id).subject, 'New candidate: Laure1 Test1');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).subject, 'New candidate: Laure2 Test2');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).subject, 'New candidate! Laure2 Test2!');
        System.assertEquals(res.get(m3.Id).get(cand2.Id).subject, 'New: Laure2 Test2');
    }

    @isTest
    static void testMultipleTemplatesMultipleRecordsNoSubstitution() {
        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        String subject1 = 'New candidate: Ik ben de eerste versie';
        String subject2 = 'New candidate! Ik ben de tweede versie!';
        String subject3 = 'New';

        String template1 = 'Dear pannekoek, we are pleased or something doeg';
        String template2 = 'Hello there!';
        String template3 = 'Hello';

        Mailtemplate__c m1 = TestDataFactory.getMailTemplate(subject1, template1);
        Mailtemplate__c m2 = TestDataFactory.getMailTemplate(subject2, template2);
        Mailtemplate__c m3 = TestDataFactory.getMailTemplate(subject3, template3);

        insert new List<Mailtemplate__c>{m1, m2, m3};

        Candidate__c cand1 = TestDataFactory.getCandidate('Laure1', 'Test1', vendor);
        Candidate__c cand2 = TestDataFactory.getCandidate('Laure2', 'Test2', vendor);

        insert new List<Candidate__c>{cand1, cand2};

        Map<Id, Mailtemplate__c> templateByTemplateId = new Map<Id, Mailtemplate__c>{
            m1.Id => m1,
            m2.Id => m2,
            m3.Id => m3
        };

        Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>{
            m1.Id => new Set<Id>{cand1.Id, cand2.Id},
            m2.Id => new Set<Id>{cand2.Id},
            m3.Id => new Set<Id>{cand2.Id}
        };

        Test.startTest();
        Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> res = MailTemplateParser.parseEmailTemplates('Candidate__c', recordIdsByTemplateId, templateByTemplateId);
        Test.stopTest();
        
        System.assertEquals(res.get(m1.Id).get(cand1.Id).message, 'Dear pannekoek, we are pleased or something doeg');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).message, 'Dear pannekoek, we are pleased or something doeg');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).message, 'Hello there!');
        System.assertEquals(res.get(m3.Id).get(cand2.Id).message, 'Hello');

        System.assertEquals(res.get(m1.Id).get(cand1.Id).subject, 'New candidate: Ik ben de eerste versie');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).subject, 'New candidate: Ik ben de eerste versie');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).subject, 'New candidate! Ik ben de tweede versie!');
        System.assertEquals(res.get(m3.Id).get(cand2.Id).subject, 'New');
    }

    @isTest
    static void testMultipleTemplatesMultipleRecordsSomeSubstitution() {
        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        String subject1 = 'New candidate: {{First_name__c}} {{Last_name__c}}';
        String subject2 = 'New candidate! Ik ben de tweede versie!';

        String template1 = 'Dear pannekoek, we are pleased or something doeg';
        String template2 = 'Hello there!';

        Mailtemplate__c m1 = TestDataFactory.getMailTemplate(subject1, template1);
        Mailtemplate__c m2 = TestDataFactory.getMailTemplate(subject2, template2);

        insert new List<Mailtemplate__c>{m1, m2};

        Candidate__c cand1 = TestDataFactory.getCandidate('Laure1', 'Test1', vendor);
        Candidate__c cand2 = TestDataFactory.getCandidate('Laure2', 'Test2', vendor);

        insert new List<Candidate__c>{cand1, cand2};

        Map<Id, Mailtemplate__c> templateByTemplateId = new Map<Id, Mailtemplate__c>{
            m1.Id => m1,
            m2.Id => m2
        };

        Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>{
            m1.Id => new Set<Id>{cand1.Id, cand2.Id},
            m2.Id => new Set<Id>{cand2.Id}
        };

        Test.startTest();
        Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> res = MailTemplateParser.parseEmailTemplates('Candidate__c', recordIdsByTemplateId, templateByTemplateId);
        Test.stopTest();
        
        System.assertEquals(res.get(m1.Id).get(cand1.Id).message, 'Dear pannekoek, we are pleased or something doeg');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).message, 'Dear pannekoek, we are pleased or something doeg');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).message, 'Hello there!');

        System.assertEquals(res.get(m1.Id).get(cand1.Id).subject, 'New candidate: Laure1 Test1');
        System.assertEquals(res.get(m1.Id).get(cand2.Id).subject, 'New candidate: Laure2 Test2');
        System.assertEquals(res.get(m2.Id).get(cand2.Id).subject, 'New candidate! Ik ben de tweede versie!');
    }

    @isTest
    static void testMultipleTemplatesOneRecord() {
        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        String subject1 = 'New candidate: {{First_name__c}} {{Last_name__c}}';
        String subject2 = 'New candidate! {{First_name__c}} {{Last_name__c}}!';
        String subject3 = 'New: {{First_name__c}} {{Last_name__c}}';

        String template1 = 'Dear {{First_name__c}} {{Last_name__c}}, we are pleased or something {{First_name__c}}{boe}';
        String template2 = 'Hello there {{First_name__c}}!';
        String template3 = 'Hello {{Last_name__c}}';

        Mailtemplate__c m1 = TestDataFactory.getMailTemplate(subject1, template1);
        Mailtemplate__c m2 = TestDataFactory.getMailTemplate(subject2, template2);
        Mailtemplate__c m3 = TestDataFactory.getMailTemplate(subject3, template3);

        insert new List<Mailtemplate__c>{m1, m2, m3};

        Candidate__c cand = TestDataFactory.getCandidate('Laure', 'Test', vendor);

        insert cand;

        Map<Id, Mailtemplate__c> templateByTemplateId = new Map<Id, Mailtemplate__c>{
            m1.Id => m1,
            m2.Id => m2,
            m3.Id => m3
        };

        Test.startTest();
        Map<Id, MailTemplateParser.MailTemplateParseResult> res = MailTemplateParser.parseEmailTemplates('Candidate__c', cand.Id, templateByTemplateId);
        Test.stopTest();
        
        System.assertEquals(res.get(m1.Id).message, 'Dear Laure Test, we are pleased or something Laure{boe}');
        System.assertEquals(res.get(m1.Id).subject, 'New candidate: Laure Test');

        System.assertEquals(res.get(m2.Id).message, 'Hello there Laure!');
        System.assertEquals(res.get(m2.Id).subject, 'New candidate! Laure Test!');

        System.assertEquals(res.get(m3.Id).message, 'Hello Test');
        System.assertEquals(res.get(m3.Id).subject, 'New: Laure Test');
    }

    @isTest
    static void testSingleTemplateMultipleRecords() {
        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        String subject = 'New candidate: {{First_name__c}} {{Last_name__c}}';
        String template = 'Dear {{First_name__c}} {{Last_name__c}}, we are pleased or something {{First_name__c}}{boe}';

        Mailtemplate__c m = TestDataFactory.getMailTemplate(subject, template);

        insert m;

        Candidate__c cand1 = TestDataFactory.getCandidate('Laure1', 'Test1', vendor);
        Candidate__c cand2 = TestDataFactory.getCandidate('Laure2', 'Test2', vendor);

        insert new List<Candidate__c>{cand1, cand2};

        Test.startTest();
        Map<Id, MailTemplateParser.MailTemplateParseResult> res = MailTemplateParser.parseEmailTemplate('Candidate__c', new Set<Id>{cand1.Id, cand2.Id}, m);
        Test.stopTest();
        
        System.assertEquals(res.get(cand1.Id).subject, 'New candidate: Laure1 Test1');
        System.assertEquals(res.get(cand1.Id).message, 'Dear Laure1 Test1, we are pleased or something Laure1{boe}');

        System.assertEquals(res.get(cand2.Id).subject, 'New candidate: Laure2 Test2');
        System.assertEquals(res.get(cand2.Id).message, 'Dear Laure2 Test2, we are pleased or something Laure2{boe}');
    }

    @isTest
    static void testSingleTemplateMultipleRecordsNoSubstitution() {
        String subject = 'Subject';
        String template = 'Body';

        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        Mailtemplate__c m = TestDataFactory.getMailTemplate(subject, template);

        insert m;

        Candidate__c cand1 = TestDataFactory.getCandidate('Laure1', 'Test1', vendor);
        Candidate__c cand2 = TestDataFactory.getCandidate('Laure2', 'Test2', vendor);

        insert new List<Candidate__c>{cand1, cand2};

        Test.startTest();
        Map<Id, MailTemplateParser.MailTemplateParseResult> res = MailTemplateParser.parseEmailTemplate('Candidate__c', new Set<Id>{cand1.Id, cand2.Id}, m);
        Test.stopTest();
        
        System.assertEquals(res.get(cand1.Id).subject, 'Subject');
        System.assertEquals(res.get(cand1.Id).message, 'Body');

        System.assertEquals(res.get(cand2.Id).subject, 'Subject');
        System.assertEquals(res.get(cand2.Id).message, 'Body');
    }

    @isTest
    static void testSingleTemplatesOneRecordNosubstitution() {
        String subject = 'Subject';
        String template = 'Body';

        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        Mailtemplate__c m = TestDataFactory.getMailTemplate(subject, template);

        insert m;

        Candidate__c cand = TestDataFactory.getCandidate('Laure', 'Test', vendor);

        insert cand;

        Test.startTest();
        MailTemplateParser.MailTemplateParseResult res = MailTemplateParser.parseEmailTemplate('Candidate__c', cand.Id, m);
        Test.stopTest();
        
        System.assertEquals(res.subject, 'Subject');
        System.assertEquals(res.message, 'Body');
    }

    @isTest
    static void testSingleTemplatesOneRecord() {
        String subject = 'New candidate: {{First_name__c}} {{Last_name__c}}';
        String template = 'Dear {{First_name__c}} {{Last_name__c}}, we are pleased or something {{First_name__c}}{boe}';

        Account vendor = TestDataFactory.getVendor();

        insert vendor;

        Mailtemplate__c m = TestDataFactory.getMailTemplate(subject, template);

        insert m;

        Candidate__c cand = TestDataFactory.getCandidate('Laure', 'Test', vendor);

        insert cand;

        Test.startTest();
        MailTemplateParser.MailTemplateParseResult res = MailTemplateParser.parseEmailTemplate('Candidate__c', cand.Id, m);
        Test.stopTest();
        
        System.assertEquals(res.subject, 'New candidate: Laure Test');
        System.assertEquals(res.message, 'Dear Laure Test, we are pleased or something Laure{boe}');
    }
}