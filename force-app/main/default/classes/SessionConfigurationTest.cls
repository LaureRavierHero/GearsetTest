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
private class SessionConfigurationTest {

    @isTest
    static void testAccountName() {
        User u = TestDataFactory.getUser();
        insert u;
        System.runAs(u) {
            String accName = [ SELECT Account_name__c FROM User WHERE Id = :UserInfo.getUserId() ][0].Account_name__c;

            System.assert(SessionConfiguration.accountName == accName);
        }
    }
    @isTest
    static void testAccountId() {
        User u = TestDataFactory.getUser();
        insert u;
        System.runAs(u) {
            Id accId = [SELECT AccountId__c FROM User WHERE Id = :UserInfo.getUserId()][0].AccountId__c;

            System.assert(SessionConfiguration.accountId == accId);
        }
    }

    @isTest
    static void testDatatableConfig() {
        User u = TestDataFactory.getUser();
        insert u;

        System.runAs(u) {
            List<Account_datatable_settings__mdt> conf = SessionConfiguration.workComponentConfig;
            System.assert(conf != null && conf.size() > 0);
        }
    }

    @isTest
    static void testDatatableSettings() {
        User u = TestDataFactory.getUser();
        insert u;

        System.runAs(u) {
            Account_datatable_general_settings__mdt conf = SessionConfiguration.workComponentSettings;
            System.assert(conf != null && !(String.isBlank(conf.Id_column__r.Api_field_name__c) && String.isBlank(conf.Id_column_api_field_name__c)));
        }
    }

    @isTest
    static void testOrgUrl() {
        User u = TestDataFactory.getUser();
        insert u;

        System.runAs(u) {
            System.assertEquals(URL.getOrgDomainUrl().toExternalForm(), SessionConfiguration.orgUrl);
        }
    }
}