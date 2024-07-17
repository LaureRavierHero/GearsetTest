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
private class PortalButtonsControllerTest {

    @isTest
    static void testHiringManagerSubmitApprovalVisible() {
        // TO DO: implement unit test
        // Get a hiring manager that is a portal user
        Account a = TestDataFactory.getAccount('Aspen');
        insert a;
        
        Contact c = TestDataFactory.getContact('Hiring', 'Manageeeeeeeeeer', a);
        insert c;
        
        User u = TestDataFactory.getPortalUser(a, c);
        u.Account_name__c = 'Aspen';
        insert u;

        Id recordTypeId = SchemaUtils.getRecordTypeId('Position__c', 'Aspen');
        
        Position__c p = TestDataFactory.getPosition(false);
        p.OwnerId = u.Id;
        p.Status__c = 'New';
        p.Is_template_position__c = 'Actual_position';
        p.RecordTypeId = recordTypeId;
        p.Hiring_manager__c = c.Id;

        insert p;

        System.runAs(u) {
            List<PortalButtonsController.Button> buttons = PortalButtonsController.getButtons(p.Id).buttons;
            for (PortalButtonsController.Button btn: buttons) {
                if (btn.ActionName == 'Submit approval') {
                    System.assert(btn.visible == true);
                }
            }
        }
    }

    @isTest
    static void testHiringManagerSubmitApprovalNotVisibleStatus() {
        // TO DO: implement unit test
        // Get a hiring manager that is a portal user
        Account a = TestDataFactory.getAccount('Aspen');
        insert a;

        Contact c = TestDataFactory.getContact('Hiring', 'Manageeeeeeeeeer', a);
        insert c;
        
        User u = TestDataFactory.getPortalUser(a, c);
        u.Account_name__c = 'Aspen';
        insert u;

        Id recordTypeId = SchemaUtils.getRecordTypeId('Position__c', 'Aspen');
        
        Position__c p = TestDataFactory.getPosition(false);
        p.OwnerId = u.Id;
        p.Status__c = 'Concept';
        p.Is_template_position__c = 'Actual_position';
        p.RecordTypeId = recordTypeId;
        p.Hiring_manager__c = c.Id;

        insert p;

        System.runAs(u) {
            List<PortalButtonsController.Button> buttons = PortalButtonsController.getButtons(p.Id).buttons;
            for (PortalButtonsController.Button btn: buttons) {
                if (btn.ActionName == 'Submit approval') {
                    System.assert(btn.visible == true);
                }
            }
        }
    }

    // @isTest
    // static void testVendorSubmittedApplicationButtons() {
    //     Account a = TestDataFactory.getAccount('Aspen');
    //     a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
    //     insert a;
        
    //     Contact c = TestDataFactory.getContact('Ven', 'Dor', a);
    //     insert c;
        
    //     User u = TestDataFactory.getPortalUserVendor(a, c);
    //     u.Account_name__c = 'Aspen';
    //     insert u;

    //     User adm = TestDataFactory.getUserNoAccount();
    //     insert adm;

    //     System.runAs(adm) {
    //         TestDataFactory.addPermissionSetToUser(u, 'Basic_application_process_permissions');
    //     }

    //     Id recordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
        
    //     Candidate__c cand = TestDataFactory.getCandidate('Can', 'Didate');
    //     cand.Account__c = a.Id;
    //     insert cand;

    //     Position__c pos = TestDataFactory.getPosition(false);
    //     pos.Account__c = a.Id;
    //     insert pos;

    //     Application__c app = TestDataFactory.getApplication(cand);
    //     app.Position__c = pos.Id;
    //     insert app;
    //     System.runAs(u) {
    //         List<PortalButtonsController.Button> buttons = PortalButtonsController.getButtons(app.Id);

    //         for (PortalButtonsController.Button btn: buttons) {
    //             if (btn.actionName == 'Recall approval') {
    //                 System.assert(btn.visible == false);
    //             }
    //         }
    //     }
    // }

    @isTest
    static void testHiringManagerApproveTimeSheet() {
        // TO DO: implement unit test
        // Get a hiring manager that is a portal user
        Account a = TestDataFactory.getAccount('Aspen');
        insert a;

        Contact c = TestDataFactory.getContact('Hiring', 'Manageeeeeeeeeer', a);
        insert c;
        
        User u = TestDataFactory.getPortalUser(a, c);
        u.Account_name__c = 'Aspen';
        insert u;

        Timesheet__c t = TestDataFactory.getTimesheet();
        t.Timesheet_approver__c = u.Id;
        t.OwnerId = u.Id;

        insert t;

        System.runAs(u) {
            List<PortalButtonsController.Button> buttons = PortalButtonsController.getButtons(t.Id).buttons;
            for (PortalButtonsController.Button btn: buttons) {
                if (btn.ActionName == 'Approve approval') {
                    System.assert(btn.visible == false);
                }
                if (btn.ActionName == 'Reject approval') {
                    System.assert(btn.visible == false);
                }
            }

            ApprovalController.submitApprovalRequestToUser(t.Id, 'Approve_timesheet', u.Id);

            buttons = PortalButtonsController.getButtons(t.Id).buttons;
            for (PortalButtonsController.Button btn: buttons) {
                if (btn.ActionName == 'Approve approval') {
                    System.assert(btn.visible == true);
                }
                if (btn.ActionName == 'Reject approval') {
                    System.assert(btn.visible == true);
                }
            }
        }
    }

    
    @isTest
    static void testHiringManagerApproveApplication() {
        Account a = TestDataFactory.getAccount('Aspen');
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        insert a;

        Contact c = TestDataFactory.getContact('Hiring', 'Manageeeeeeeeeer', a);
        insert c;
        
        User u = TestDataFactory.getPortalUser(a, c);
        u.Account_name__c = 'Aspen';
        insert u;

        Id recordTypeId = SchemaUtils.getRecordTypeId('Application__c', 'Aspen');
        
        Candidate__c cand = TestDataFactory.getCandidate('Can', 'Didate');
        cand.Account__c = a.Id;
        insert cand;

        Position__c pos = TestDataFactory.getPosition(false);
        pos.Account__c = a.Id;
        insert pos;

        Application__c app = TestDataFactory.getApplication(cand);
        app.Position__c = pos.Id;
        app.Hiring_manager_associated_position__c = u.Id;
        app.Account__c = a.Id;
        app.OwnerId = u.Id;
        insert app;
        
        app.Account__c = a.Id;
        update app;

        // ApprovalController.submitApprovalRequest(app.Id);
        List<ProcessInstanceWorkItem> piwis = ApprovalController.getPendingApprovalRequestsWithTargetId(app.Id);
        ApprovalController.processApprovalRequest(new ApprovalController.ApprovalHandlerWrapper(
            piwis[0].Id,
            'Approve', 
            '',
            u.Id
        ));
        System.runAs(u) {
            List<PortalButtonsController.Button>buttons = PortalButtonsController.getButtons(app.Id).buttons;
            for (PortalButtonsController.Button btn: buttons) {
                if (btn.ActionName == 'Plan intake') {
                    System.assert(btn.visible == true);
                }
                if (btn.ActionName == 'Reject approval') {
                    System.assert(btn.visible == true);
                }
            }
        }
    }
}