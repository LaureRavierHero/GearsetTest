public without sharing class ApprovalController {
    public class ApprovalException extends Exception {}
    public class recallWrapper {

        @InvocableVariable(required=true)
        public Id recordId;

        @InvocableVariable(required=true)
        public String recallReason;

        @InvocableVariable
        public Boolean IsPiwiEmpty;
    }

    public class ApprovalWrapperFlow{
        @InvocableVariable(required=true) public String action;
        @InvocableVariable(required=true) public Id recordId;
        @InvocableVariable(required=true) public String approvalProcessName;
        @InvocableVariable public Id processWorkItemId;
        @InvocableVariable public List<Id> recallWorkItemIds;
        @InvocableVariable public Id nextApproverId;
        @InvocableVariable public String comment;
    }
   
        
    public class ApprovalHandlerWrapper {
        public Id processInstanceWorkItemId;
        public String action; // has to be either 'Reject', 'Approve' or 'Removed'
        public String comment;
        public Id nextApproverId;

        public ApprovalHandlerWrapper(Id pId, String a, String c) {
            processInstanceWorkItemId = pId;
            action = a;
            comment = c;
        }

        public ApprovalHandlerWrapper(Id pId, String a, String c, Id u) {
            this(pId, a, c);
            if (SchemaUtils.getObjectNameByRecordId(u) == 'Contact') {
                nextApproverId = SchemaUtils.getUserFromContactId(u);
            }
            else {
                nextApproverId = u;
            }
        }

        public ApprovalHandlerWrapper(){}
    }

    private static Id getWorkItemIdApproveReject(ApprovalWrapperFlow args) {
        Id workItemId;
        Set<Id> actorIdGroups = new Set<Id>();
        
        List<ProcessInstanceWorkitem> piwiList = getPendingApprovalRequests(args.recordId, args.approvalProcessName);
        for(ProcessInstanceWorkitem piwi : piwiList){
            if(piwi.ActorId == UserInfo.getUserId()){
                workItemId = piwi.Id;
            }else if(piwi.ActorId.getSObjectType().getDescribe().getName() == 'Group'){
                actorIdGroups.add(piwi.ActorId);
            }
        }
        
        if(actorIdGroups.size() >  0){
            // Set<Id> userGroups = SchemaUtils.isUserPartOfGroups(UserInfo.getUserId(),checkIfUserIsInGroups);
            Set<Id> userGroups = SchemaUtils.filterGroupsByUserMemberShip(UserInfo.getUserId(), actorIdGroups);
            for(ProcessInstanceWorkitem piwi : piwiList){
                if(userGroups.contains(piwi.ActorId)){
                    workItemId = piwi.Id;
                }
            }
        }

        return workItemId;
    }

    /* Get workitems where user was original submittes for recordId apr approval process name */
    private static Set<Id> getWorkItemIdsRecall(ApprovalWrapperFlow args) {
        Set<Id> workItemIds;
        
        List<ProcessInstanceWorkitem> piwiList = getPendingApprovalRequests(args.recordId, args.approvalProcessName);
        for(ProcessInstanceWorkitem piwi : piwiList){
            if(piwi.ProcessInstance.SubmittedById == UserInfo.getUserId()){
                workItemIds.add(piwi.Id);
            }
        }
        return workItemIds;
    }

    /* This is suitable for Approval and Rejection actions, not recall since recall actions 
    may have impact on multiple ProcessInstanceWorkItems! */
    @InvocableMethod(label = 'Approval action' description='Not for lists!' category='Custom Approvals')
    public static void startApprovalActionFromFlow(List<ApprovalWrapperFlow> wrapperFlow){
        System.debug(wrapperFlow[0]);
        ApprovalWrapperFlow args = wrapperFlow[0];

        if (args.action == 'Approve' || args.action == 'Reject') {
            ApprovalHandlerWrapper wrapper = new ApprovalHandlerWrapper();

            wrapper.action = args.action;
            wrapper.comment = args.comment;
            if (String.isNotBlank(args.nextApproverId)) {
                wrapper.nextApproverId = args.nextApproverId;
            }
            if (String.isBlank(args.processWorkItemId)) {
                wrapper.processInstanceWorkItemId = getWorkItemIdApproveReject(args);
            }
            else {
                wrapper.processInstanceWorkItemId = args.processWorkItemId;
            }
            
            if(wrapper.processInstanceWorkItemId != null){
                processApprovalRequests(new List<ApprovalHandlerWrapper>{wrapper});
            }
        }
        else { // Recall
            List<ApprovalHandlerWrapper> wrappers = new List<ApprovalHandlerWrapper>();
            Set<Id> recallItems;
            if (args.recallWorkItemIds == null || args.recallWorkItemIds.size() == 0) {
                // Get recall workitems
                recallItems = getWorkItemIdsRecall(args);
            }
            else {
                recallItems = new Set<Id>();
                recallItems.addAll(args.recallWorkItemIds);
            }

            for (Id workItemId: recallItems) {
                ApprovalHandlerWrapper wrapper = new ApprovalHandlerWrapper();
                wrapper.action = args.action;
                wrapper.comment = args.comment;
                wrapper.processInstanceWorkItemId = workItemId;
                wrappers.add(wrapper);
            }

            processApprovalRequests(wrappers);
        } 
    }

    public static void rejectApprovalRequest(Id processInstanceWorkItemId, String comment) {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(processInstanceWorkItemId);
        req.setAction('Reject');
        req.setComments(comment);

        Approval.ProcessResult result = Approval.process(req);

        if (!result.isSuccess()) {
            String error = 'Could not reject ProcessInstanceWorkItem ' + processInstanceWorkItemId;
            for (Database.Error err: result.getErrors()) {
                error += err + '\n';
            }
            throw new ApprovalException(error);
        }
    }

    private static void submitApprovalRequestInner(Id recordId, String approvalProcessName, String comment, String userId) {
        Approval.ProcessSubmitRequest approvalReq = 
            new Approval.ProcessSubmitRequest();
        approvalReq.setComments(comment);
        approvalReq.setObjectId(recordId);
        approvalReq.setSubmitterId(UserInfo.getUserId());

        if (String.isNotBlank(userId)) {
            approvalReq.setNextApproverIds(new Id[] {(Id)userId});
        }
        
        if (String.isNotBlank(approvalProcessName)) {
            approvalReq.setProcessDefinitionNameOrId(approvalProcessName);
        }

        Approval.ProcessResult result = Approval.process(approvalReq);

        if (!result.isSuccess()) {
            String error = 'Could not submit ' + SchemaUtils.getObjectNameByRecordId(recordId) + ' record with Id ' + recordId + ' for approval on behalf of User with Id ' + UserInfo.getUserId();
            for (Database.Error err: result.getErrors()) {
                error += err + '\n';
            }
            throw new ApprovalException(error);
        }
    }

    
    private static void submitApprovalRequestInner(Id recordId, String approvalProcessName, String comment) {
        submitApprovalRequestInner(recordId, approvalProcessName, comment, '');
    }

    public static void submitApprovalRequestToUser(Id recordId, String approvalProcessName, String comment, Id userId) {
        submitApprovalRequestInner(recordId, approvalProcessName, comment, userId);
    }

    public static void submitApprovalRequestToUser(Id recordId, String approvalProcessName, Id userId) {
        submitApprovalRequestInner(recordId, approvalProcessName, '', userId);
    }

    public static void submitApprovalRequest(Id recordId, String approvalProcessName, String comment) {
        submitApprovalRequestInner(recordId, approvalProcessName, comment);
    }

    public static void submitApprovalRequest(Id recordId, String comment) {
        submitApprovalRequest(recordId, '', comment);
    }

    public static void submitApprovalRequest(Id recordId) {
        submitApprovalRequest(recordId, '', '');
    }

    public static Map<Id, List<ProcessInstanceWorkitem>> getPendingApprovalRequestsByTargetObject(List<Id> recordIds, String approvalProcessName) {
        List<ProcessInstanceWorkitem> approvalRequests = 
            [   SELECT Id, ActorId, ProcessInstance.TargetObjectId, ProcessInstance.ProcessDefinitionId, ProcessInstance.Status, ProcessInstanceId, 
                ProcessInstance.SubmittedById
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId IN :recordIds AND ProcessInstance.ProcessDefinition.DeveloperName = :approvalProcessName
            ];

        Map<Id, List<ProcessInstanceWorkitem>> pendingApprovalByTargetObject = new Map<Id, List<ProcessInstanceWorkitem>>();

        for (ProcessInstanceWorkitem req: approvalRequests) {
            Id targetObjectId = req.ProcessInstance.TargetObjectId;
            if (pendingApprovalByTargetObject.get(targetObjectId) == null) {
                pendingApprovalByTargetObject.put(targetObjectId, new List<ProcessInstanceWorkitem>());
            }
            pendingApprovalByTargetObject.get(targetObjectId).add(req);
        }
        
        return pendingApprovalByTargetObject;
    }

    public static List<ProcessInstanceWorkitem> getPendingApprovalRequestsWithTargetId(Id recordId) {
        return  [   
            SELECT Id, ActorId, OriginalActorId, ProcessInstance.TargetObjectId, ProcessInstance.ProcessDefinitionId, ProcessInstance.Status, ProcessInstanceId, ProcessInstance.ProcessDefinition.Name, 
            ProcessInstance.ProcessDefinition.DeveloperName, ProcessInstance.SubmittedById
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId
        ];
    }

    public static List<ProcessInstanceWorkitem> getPendingApprovalRequests(Id recordIds, String approvalProcessName) {
        return  [   
            SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.ProcessDefinitionId, ProcessInstance.Status, ProcessInstanceId, ActorId, 
            ProcessInstance.SubmittedById
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordIds AND ProcessInstance.ProcessDefinition.DeveloperName = :approvalProcessName
        ];
    }

    public static List<ProcessInstanceWorkitem> getPendingApprovalRequests(Id recordIds, String approvalProcessName, Set<Id> actorId) {
        return  [   
            SELECT Id, ProcessInstance.TargetObjectId, ProcessInstance.ProcessDefinitionId, ProcessInstance.Status, ProcessInstanceId, ActorId, 
            ProcessInstance.SubmittedById
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordIds 
            AND ProcessInstance.ProcessDefinition.DeveloperName = :approvalProcessName
            AND ActorId IN :actorId
        ];
    }

    public static void processApprovalRequests(List<ApprovalHandlerWrapper> wrappers) {
        Boolean errorsEncountered = false;
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        for (ApprovalHandlerWrapper wr: wrappers) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
 
            req.setWorkitemId(wr.processInstanceWorkItemId);
            req.setAction(wr.action);
            req.setComments(wr.comment);
            if (String.isNotBlank(wr.nextApproverId)) {
                req.setNextApproverIds(new Id []{wr.nextApproverId});
            }
            requests.add(req);
        }

        Approval.ProcessResult[] results = Approval.process(requests);

        for (Approval.ProcessResult res: results) {
            if (!res.isSuccess()) {
                errorsEncountered = true;
                String error = 'Could not process approval';
                System.debug(LoggingLevel.ERROR, error);
                for (Database.Error err: res.getErrors()) {
                    System.debug(LoggingLevel.ERROR, err);
                }
            }
        }

        if (errorsEncountered) {
            throw new ApprovalException('Could not process approvals, contact your System administrator!');
        }
    }

    public static void processApprovalRequest(ApprovalHandlerWrapper wrapper) {
        processApprovalRequests(new List<ApprovalHandlerWrapper>{wrapper});
    }

    public static void approveApprovalRequest(Id processInstanceWorkItemId, String comment) {
        processApprovalRequest(new ApprovalHandlerWrapper(
            processInstanceWorkItemId,
            'Approve',
            comment
        ));
    }

    public static void approveApprovalRequest(Id processInstanceWorkItemId, Id nextApprover, String comment) {
        processApprovalRequest(new ApprovalHandlerWrapper(
            processInstanceWorkItemId,
            'Approve',
            comment,
            nextApprover
        ));
    }

    public static void approveApprovalRequest(Id processInstanceWorkItemId) {
        approveApprovalRequest(processInstanceWorkItemId, '');
    }

    public static void rejectApprovalRequest(Id processInstanceWorkItemId) {
        rejectApprovalRequest(processInstanceWorkItemId, '');
    }
}