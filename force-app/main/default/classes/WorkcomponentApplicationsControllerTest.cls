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
private class WorkcomponentApplicationsControllerTest {
    private static List<WorkComponentApplicationsController.ApplicationWrapper> getWrappersFromApplications(List<Application__c> apps) {
        List<WorkComponentApplicationsController.ApplicationWrapper> aws = new List<WorkComponentApplicationsController.ApplicationWrapper>();
 
        for (Application__c app: apps) {
            WorkComponentApplicationsController.ApplicationWrapper aw = new WorkComponentApplicationsController.ApplicationWrapper();
 
            aw.applicationName = app.Name;
            aw.Id = app.Id;
            aw.status = app.Status__c;
            aw.vendorId = app.Vendor__c;
            aw.vendorName = app.Vendor__r?.Name;
            aw.rate = app.Desired_rate__c;
            aw.sendToHiringManager = app.Send_to_hiring_manager__c;
            aw.rejectionReasonHiringDesk = app.Reason_rejection_hiring_desk__c;
 
            aws.add(aw);
        }
 
        return aws;
    }

    @isTest
    static void testGetData() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;
        System.runAs(u) {
            List<Application__c> appList = new List<Application__c>();
            Position__c p = TestDataFactory.getPosition(false);
            p.Account__c = a.Id;

            insert p;

            Account v = TestDataFactory.getVendor();
            insert v;

            for (Integer i = 0; i < 8; ++i) {
                appList.add(TestDataFactory.getApplicationWithCv('Fn_' + i, 'Ln_' + i, p, v));
                Application__c app = appList[i];
            }

            Set<Id> appIds = new Set<Id>();
            for (Application__c app: appList) {
                appIds.add(app.Id);
            }
            String componentName = 'Standard hiring desk workcomponent';

            WorkcomponentSettingsController.ComponentConfiguration conf = WorkcomponentApplicationsController.getSettings(componentName);
            List<WorkcomponentApplicationsController.ApplicationWrapper> cppWrappers = WorkcomponentApplicationsController.getData(JSON.serialize(conf), 'applicationName', 'asc', p.Id);

            for (WorkcomponentApplicationsController.ApplicationWrapper w: cppWrappers) {
                System.assert(w.cvId != null);
                System.assert(appIds.contains(w.Id));
            }
        }
    }

    @isTest
    static void testGetDataNoApplications() {
        User u = TestDataFactory.getUserNoAccount();

        insert u;
        System.runAs(u) {
            Position__c p = TestDataFactory.getPosition(false);
            insert p;

            String componentName = 'Standard hiring desk workcomponent';

            Test.startTest();
            WorkcomponentSettingsController.ComponentConfiguration conf = WorkcomponentApplicationsController.getSettings(componentName);
            List<WorkcomponentApplicationsController.ApplicationWrapper> cppWrappers = WorkcomponentApplicationsController.getData(JSON.serialize(conf), 'applicationName', 'asc', p.Id);
            Test.stopTest();

            System.assert(cppWrappers.size() == 0);
        }
    }

    @isTest
    static void testGetDataNotRejectedNotAtHiringManager() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;
        
        System.runAs(u) {
            List<Application__c> appList = new List<Application__c>();
            Position__c p = TestDataFactory.getPosition(false);
            p.Account__c = a.Id;
            insert p;

            Account v = TestDataFactory.getVendor();
            insert v;

            for (Integer i = 0; i < 8; ++i) {
                appList.add(TestDataFactory.getApplicationWithCv('Fn_' + i, 'Ln_' + i, p, v));
                Application__c app = appList[i];
                app.Send_to_hiring_manager__c = 'Yes';
            }

            for (Integer i = 0; i < 2; ++i) {
                Application__c app = appList[i];
                app.Status__c = 'Rejected';
            }

            for (Integer i = 4; i < 6; ++i) {
                Application__c app = appList[i];
                app.Status__c = 'Sent to hiring manager';
            }

            Set<String> statuses = new Set<String>{'Rejected', 'Sent to hiring manager'};
            update appList;

            Set<Id> appIds = new Set<Id>();
            for (Application__c app: appList) {
                if (!statuses.contains(app.Status__c))
                    appIds.add(app.Id);
            }
            String componentName = 'Hiring desk review component';

            Test.startTest();
            WorkcomponentSettingsController.ComponentConfiguration conf = WorkcomponentApplicationsController.getSettings(componentName);
            List<WorkcomponentApplicationsController.ApplicationWrapper> cppWrappers = WorkcomponentApplicationsController.getApplicationsProcessable(JSON.serialize(conf), 'applicationName', 'asc', p.Id);
            Test.stopTest();

            System.debug('WRAPPERS ' + cppWrappers.size());
            System.assert(cppWrappers.size() == 4);
            for (WorkcomponentApplicationsController.ApplicationWrapper w: cppWrappers) {
                if (statuses.contains(w.status)) {
                    System.assert(!appIds.contains(w.Id));
                }
                else {
                    System.assert(appIds.contains(w.Id));
                }
            }
        }
    }

    // Has to be see all data in order to access custom metadata
    @isTest(SeeAllData=true)
    static void getApplicationFromJsonTest() {
        String appString  = '[{"Id":"a0R5t000002drThEAI","rejectionReasonHiringDesk":"Other"}]';

        List<Application__c> apps = WorkcomponentApplicationsController.getApplicationsFromJson(appString);

        System.assertEquals(apps[0].Reason_rejection_hiring_desk__c, 'Other');
        System.assertEquals(apps[0].Id, 'a0R5t000002drThEAI');
    }

    @isTest
    static void handleRejectApproveTest() {
        Account acc = TestDataFactory.getAccount();
        acc.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert acc;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', acc);

        insert c;

        User u = TestDataFactory.getPortalUser(acc, c);

        insert u;

        System.runAs(u) {
            Mailtemplate__c mt1 = TestDataFactory.getConnectedMailTemplate('Application accepted: {{Name}}', 'Next stage baby', 'Application to manager mail', acc);
            Mailtemplate__c mt2 = TestDataFactory.getConnectedMailTemplate('Application rejected: {{Name}}', 'No thank you', 'Application rejection email to vendor', acc);

            List<String> rejectedApproved = new List<String>{'Sent to hiring manager', 'Rejected'};
            List<Application__c> appList = new List<Application__c>();
            Position__c p = TestDataFactory.getPosition(false);
            p.Status__c = 'Open';
            p.Account__c = acc.Id;
            p.Hiring_manager__c = c.Id;
            insert p;

            Account vend = TestDataFactory.getVendor();

            insert vend;
            Boolean prev = true;
            for (Integer i = 0; i < 8; ++i) {
                appList.add(TestDataFactory.getApplication('Fn_' + i, 'Ln_' + i, p, vend));
                Application__c app = appList[i];
                app.Send_to_hiring_manager__c = prev? 'Yes' : 'No';
                prev = !prev;
            }

            insert appList;

            Set<Id> appIds = new Set<Id>();
            for (Application__c app: appList) {
                appIds.add(app.Id);
            }

            System.debug('START TEST');
            Test.startTest();
            List<WorkcomponentApplicationsController.ApplicationWrapper> wraps = 
            getWrappersFromApplications(appList);
            WorkcomponentApplicationsController.handleRejectApproveApplicationsHiringDesk(JSON.serialize(wraps), 
            p.Id);
            Test.stopTest();

            List<Application__c> apps = [SELECT Status__c FROM Application__c];
            Position__c pos = [SELECT Id, Processing_status__c FROM Position__c WHERE Id = :p.Id LIMIT 1];

            System.assert(pos.Processing_status__c == 'Candidates offered and in review of manager');

            for (Application__c app: apps) {
                System.assert(rejectedApproved.contains(app.Status__c));
            }
        }
    }
}