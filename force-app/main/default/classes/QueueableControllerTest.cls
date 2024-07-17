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
private class QueueableControllerTest {
    @TestSetup 
    static void calculatePermissionSetGroup() {
       Id psgId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Professional_permissions' LIMIT 1].Id;

       Test.calculatePermissionSetGroup(psgId);
    }

    @isTest
    static void testProfessionalFromContact() {
        user u = TestDataFactory.getUserNoAccount();
        u.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Administrator' LIMIT 1].Id;
        
        insert u;

        System.runAs(u) {
            Account a = TestDataFactory.getAccount('Hero Interim Professionals');
            insert a;
    
            Contact c = TestDataFactory.getContact();
            c.accountId = a.Id;
            insert c;
    
            Map<String, Object> args = new Map<String, Object>{
                'contact' => c
            };
    
            Test.startTest();        
            QueueableController q = new QueueableController('createUser', args);
            q.enqueue();
            Test.stopTest();
        }

        List<LogMessage__c> logMessages = [SELECT Message__c, Request__c, DateTime__c, Source__c FROM LogMessage__c];
        DeveloperUtils.printList(logMessages);

        List<User> users = [SELECT Id FROM User];
    
        System.assertNotEquals(1, users.size(), 'No users created!');
    }

    @isTest
    static void testProfessionalFromContactDuplicate() {
        user u = TestDataFactory.getUserNoAccount();
        u.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Administrator' LIMIT 1].Id;
        
        insert u;

        System.runAs(u) {
            Account a = TestDataFactory.getAccount('Hero Interim Professionals');
            insert a;
    
            Contact c = TestDataFactory.getContact();
            c.accountId = a.Id;
            insert c;
    
            Map<String, Object> args = new Map<String, Object>{
                'contact' => c
            };
    
            try {
                Test.startTest();        
                QueueableController q = new QueueableController('createUser', args);
                q.enqueue();
                q.enqueue();
                Test.stopTest();
                System.Assert.fail();
            }
            catch (Exception e) {
                System.assertEquals('QueueableController.QueueableException', e.getTypeName());
            }
        }

    }
}