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
private class WorkcomponentSettingsControllerTest {
    @isTest
    static void testGetComponentSettings() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();
        u.AccountId__c = a.Id;
        insert u;

        Account v = TestDataFactory.getVendor();
        insert v;

        System.runAs(u) {
            List<Application__c> appList = new List<Application__c>();
            Position__c p = TestDataFactory.getPosition(false);
            insert p;

            for (Integer i = 0; i < 8; ++i) {
                appList.add(TestDataFactory.getApplicationWithCv('Fn_' + i, 'Ln_' + i, p, v));
                Application__c app = appList[i];
            }

            String componentName = 'Standard hiring desk workcomponent';

            Test.startTest();
            WorkcomponentSettingsController.ComponentConfiguration cc = WorkcomponentSettingsController.getSettings(componentName, WorkcomponentApplicationsController.columnNamesByFieldNames);
            Test.stopTest();

            System.assert(cc.objectApiName == 'Application__c');
            System.assert(cc.columns.size() != 0);
        }
    }
}