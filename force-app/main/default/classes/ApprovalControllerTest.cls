@isTest
private class ApprovalControllerTest {
    @isTest
    public static void submitApprovalRequest() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        Application__c app = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        insert app;

        // ApprovalController.submitApprovalRequest(app.Id, 'Test comment');

        List<ProcessInstanceWorkitem> n = ApprovalController.getPendingApprovalRequests(app.Id, 'Application_to_placement_Aspen');
        
        System.assert(n.size() == 1);
    }

    @isTest
    public static void submitApprovalRequestToUserNext() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        //  Is submitted for approval in trigger
        Application__c app = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        insert app;

        // ApprovalController.submitApprovalRequest(app.Id, 'Test comment');

        List<ProcessInstanceWorkitem> n = ApprovalController.getPendingApprovalRequests(app.Id, 'Application_to_placement_Aspen');

        ApprovalController.processApprovalRequest(new ApprovalController.ApprovalHandlerWrapper(
            n[0].Id,
            'Approve',
            '',
            u.Id
        ));

        List<ProcessInstanceWorkitem> n2 = ApprovalController.getPendingApprovalRequests(app.Id, 'Application_to_placement_Aspen');
        
        System.assert(n2[0].ActorId == u.Id);
    }

    @isTest
    public static void approveApprovalRequest() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', a);

        insert c;

        User u = TestDataFactory.getPortalUser(a, c);

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        Application__c app = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        app.Hiring_manager_associated_position__c = u.Id;

        //  Is submitted for approval in trigger
        insert app;

        // ApprovalController.submitApprovalRequest(app.Id);

        List<ProcessInstanceWorkitem> n = ApprovalController.getPendingApprovalRequests(app.Id, 'Application_to_placement_Aspen');
        ProcessInstanceWorkitem piwi = n[0];

        ApprovalController.approveApprovalRequest(piwi.Id, u.Id, '');
        ProcessInstanceNode processInstanceNode = [SELECT Id, NodeStatus, ProcessInstanceId, ProcessNodeName FROM ProcessInstanceNode WHERE ProcessInstanceId = :piwi.ProcessInstanceId AND ProcessNodeName='Hiring desk application' LIMIT 1];

        System.assertEquals('Approved', processInstanceNode.NodeStatus);
    }
    @isTest
    public static void rejectApprovalRequest() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        Contact c = TestDataFactory.getContact('Bob', 'Vendor', a);

        insert c;

        User u = TestDataFactory.getPortalUser(a, c);

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        Application__c app = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        app.Hiring_manager_associated_position__c = u.Id;
        insert app;

        // ApprovalController.submitApprovalRequest(app.Id);

        List<ProcessInstanceWorkitem> n = ApprovalController.getPendingApprovalRequests(app.Id, 'Application_to_placement_Aspen');

        ProcessInstanceWorkitem piwi = n[0];

        ApprovalController.rejectApprovalRequest(piwi.Id);

        ProcessInstanceNode processInstanceNode = [SELECT Id, NodeStatus, ProcessInstanceId, ProcessNodeName FROM ProcessInstanceNode WHERE ProcessInstanceId = :piwi.ProcessInstanceId AND ProcessNodeName='Hiring desk application' LIMIT 1];
        System.assertEquals('Rejected', processInstanceNode.NodeStatus);
    }

    @isTest
    public static void processApprovalRequest() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        Application__c app1 = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        app1.Hiring_manager_associated_position__c = u.Id;
        insert app1;
        
        Application__c app2 = TestDataFactory.getApplication('Bobina', 'Test', p, vend);
        app2.Hiring_manager_associated_position__c = u.Id;
        insert app2;

        // ApprovalController.submitApprovalRequest(app1.Id);
        // ApprovalController.submitApprovalRequest(app2.Id);

        Map<Id, List<ProcessInstanceWorkItem>> pendingApprReq = ApprovalController.getPendingApprovalRequestsByTargetObject(new List<Id>{app1.Id, app2.Id}, 'Application_to_placement_Aspen');

        List<ApprovalController.ApprovalHandlerWrapper> wrappers = new List<ApprovalController.ApprovalHandlerWrapper>();

        wrappers.add(new ApprovalController.ApprovalHandlerWrapper(
            pendingApprReq.get(app1.Id)[0].Id,
            'Approve',
            '',
            u.Id
        ));

        wrappers.add(new ApprovalController.ApprovalHandlerWrapper(
            pendingApprReq.get(app2.Id)[0].Id,
            'Reject',
            ''
        ));

        ApprovalController.processApprovalRequests(wrappers);

        ProcessInstanceNode processInstanceNode1 = [SELECT Id, NodeStatus, ProcessInstanceId, ProcessNodeName FROM ProcessInstanceNode WHERE ProcessInstanceId = :pendingApprReq.get(app1.Id)[0].ProcessInstanceId AND ProcessNodeName='Hiring desk application' LIMIT 1];
        ProcessInstanceNode processInstanceNode2 = [SELECT Id, NodeStatus, ProcessInstanceId, ProcessNodeName FROM ProcessInstanceNode WHERE ProcessInstanceId = :pendingApprReq.get(app2.Id)[0].ProcessInstanceId AND ProcessNodeName='Hiring desk application' LIMIT 1];

        System.assertEquals('Approved', processInstanceNode1.NodeStatus);
        System.assertEquals('Rejected', processInstanceNode2.NodeStatus);
    }

    @isTest
    public static void processApprovalRequestFlow() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;
        
        Application__c app1 = TestDataFactory.getApplication('Bob', 'Test', p, vend);
        app1.Hiring_manager_associated_position__c = u.Id;
        insert app1;

        Test.startTest();

        //  Is submitted for approval in trigger
        // ApprovalController.submitApprovalRequest(app1.Id);

        Map<Id, List<ProcessInstanceWorkItem>> pendingApprReq = ApprovalController.getPendingApprovalRequestsByTargetObject(new List<Id>{app1.Id}, 'Application_to_placement_Aspen');

        List<ApprovalController.ApprovalWrapperFlow> wrappers = new List<ApprovalController.ApprovalWrapperFlow>();

        ApprovalController.ApprovalWrapperFlow w1 = new ApprovalController.ApprovalWrapperFlow();
        w1.action = 'Approve';
        w1.recordId = app1.Id;
        w1.approvalProcessName = 'Application_to_placement_Aspen';
        w1.nextApproverId = u.Id;

        wrappers.add(w1);

        ApprovalController.startApprovalActionFromFlow(wrappers);

        Test.stopTest();
        ProcessInstanceNode processInstanceNode1 = [SELECT Id, NodeStatus, ProcessInstanceId, ProcessNodeName FROM ProcessInstanceNode WHERE ProcessInstanceId = :pendingApprReq.get(app1.Id)[0].ProcessInstanceId AND ProcessNodeName='Hiring desk application' LIMIT 1];

        System.assertEquals('Approved', processInstanceNode1.NodeStatus);
    }
}