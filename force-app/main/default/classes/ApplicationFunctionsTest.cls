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
private class ApplicationFunctionsTest {

    @isTest
    static void createProfessional() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Position__c p = TestDataFactory.getPosition(false);

        p.Account__c = a.Id;

        insert p;

        Account v = TestDataFactory.getVendor();

        insert v;

        Application__c app = TestDataFactory.getApplication('Bee', 'Worker', p, v);

        insert app;

        String mail = '01234@test.nl';
        String phone = '0123456789';

        Test.startTest();
        Id contactId = ApplicationFunctions.createProfessional(app.Id, mail, phone);
        Test.stopTest();

        List<Application__c> apps = [SELECT Id FROM Application__c WHERE Professional__c = :contactId];

        System.assertEquals(1, apps.size(), 'Wrong number of applications found associated with professional');
        List<Contact> ctcs = [SELECT Id, Phone, Email, Name FROM Contact WHERE Id = :contactId];

        System.assertEquals(1, ctcs.size(), 'Wrong number of contacts found');

        System.assertEquals('01234@test.nl', ctcs[0].Email);
        System.assertEquals('0123456789', ctcs[0].Phone);
        System.assertEquals('Bee Worker', ctcs[0].Name);
    }
}