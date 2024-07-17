public without sharing class PortalButtonsController {
    public class PortalButtonLogicHandlerException extends Exception {}
    public enum Audience {
        VENDOR,
        PROFESSIONAL,
        HIRING_MANAGER
    }

    public static map<Audience, String> fieldNameByAudience = new map<Audience, String>{
        Audience.VENDOR => 'Visible_in_vendor_portal__c',
        Audience.PROFESSIONAL => 'Visible_in_professional_portal__c',
        Audience.HIRING_MANAGER => 'Visible_in_hiring_manager_portal__c'
    };

    private static Map<Id, Portal_button_configuration__mdt> getConfigurations(String objectName, Audience aud, String accountName) {
        List<QueryBuilder.FilterClause> subFilters = new List<QueryBuilder.FilterClause>();

        subFilters.add(new QueryBuilder.StringFilterClause('Account_name__c', accountName));
        subFilters.add(new QueryBuilder.StringFilterClause('Object_api_name__c', objectName));
        QueryBuilder subQuery = new QueryBuilder(new Set<String>{'Button_configuration__c'}, 'Portal_button__mdt', subFilters);
        
        List<QueryBuilder.FilterClause> queryFilters = new List<QueryBuilder.FilterClause>();
        queryFilters.add(new QueryBuilder.BooleanFilterClause('Visibility__r.' + fieldNameByAudience.get(aud), QueryBuilder.Condition.EQUAL, true));
        queryFilters.add(new QueryBuilder.QueryFilterClause('Id', QueryBuilder.Condition.IS_IN, subQuery));
        QueryBuilder configQuery = new QueryBuilder(SchemaUtils.getAllFieldNames('Portal_button_configuration__mdt'), 'Portal_button_configuration__mdt',
        queryFilters);

        System.debug('Config query' + configQuery.toString());
        Map<Id, Portal_button_configuration__mdt> configurations = new Map<Id, Portal_button_configuration__mdt>((List<Portal_button_configuration__mdt>)Database.query(configQuery.toString()));
        System.debug('CONFIGURATIONS');
        System.debug('Num buttons: ' + configurations.keySet().size());
        for (Portal_button_configuration__mdt pbc: configurations.values()) {
            System.debug('CONFIGURATION: ');
            System.debug(pbc.DeveloperName + ' ' +  pbc.Visibility__c);
        }
        return configurations;
    }

    private static Map<Id, List<Portal_button_filter__mdt>> getFieldFiltersByVisibilitySetting(Set<Id> visibilityIds) {
        List<Portal_button_filter__mdt> fieldFilters = [
            SELECT Criterium__r.Condition__c, Criterium__r.Field__c, Criterium__r.Value__c, Criterium__r.Type__c, Number__c, Visibility__c
            FROM Portal_button_filter__mdt
            WHERE Visibility__c IN :visibilityIds
        ];

        Map<Id, List<Portal_button_filter__mdt>> fieldFiltersByVisibilityId = new Map<Id, List<Portal_button_filter__mdt>>();

        for (Portal_button_filter__mdt filter: fieldFilters) {
            if (fieldFiltersByVisibilityId.get(filter.Visibility__c) == null) {
                fieldFiltersByVisibilityId.put(filter.Visibility__c, new List<Portal_button_filter__mdt>());
            }
            fieldFiltersByVisibilityId.get(filter.Visibility__c).add(filter);
        }

        return fieldFiltersByVisibilityId;
    }

    /* Function gathers all fields that need to be queried, then queries record. Fields come from 
    criteria where they are specified as well as fields needed to determine for other criteria */
    private static SObject getRecord(Id recordId, String objectName, 
        list<Portal_button_configuration__mdt> configurations,
        Map<Id, List<Portal_button_filter__mdt>> fieldFiltersByVisibilityId, 
        Map<Id, List<Portal_button_approval_submitter__mdt>> approvalSubmitterByVisibilityId) {
        Set<String> fieldNames = new Set<String>();

        for (Portal_button_configuration__mdt config: configurations) {

            // Get fields to evaluate (for Approval process entry and filtering based on field values in general)
            List<Portal_button_filter__mdt> filters = fieldFiltersByVisibilityId.get(config.Visibility__c);
            if (filters != null) {
                for (Portal_button_filter__mdt filter: filters) {
                    System.debug('Criterium');
                    System.debug(filter.Criterium__c);
                    String type = filter.Criterium__r.Type__c;
    
                    switch on type {
                        when 'Field value' {
                            fieldNames.add(filter.Criterium__r.Field__c);
                        }
                        when 'Record type' {
                            fieldNames.add('RecordTypeId');
                        }
                    }
                }
            }

            // Query approver contact field if manually selected approver is set
            if (config.Manually_selected_approver__c) {
                if (config.Approver_default_vendor__c) {
                    fieldNames.add('Vendor__c');
                }
                else {
                    fieldNames.add(config.Approver_contact_field__c);
                }
            }

            if (!String.isBlank(config.Task_owner_field__c)) {
                fieldNames.add(config.Task_owner_field__c);
            }
            
            // Get fields we need to determine whether user is valid submisser
            List<Portal_button_approval_submitter__mdt> submitters = approvalSubmitterByVisibilityId.get(config.Visibility__c);

            if (submitters != null) {
                for (Portal_button_approval_submitter__mdt submitter: submitters) {
                    String type = submitter.Type__c;
    
                    switch on type {
                        when 'Record owner' {
                            fieldNames.add('OwnerId');
                        }
                        when 'Record creator' {
                            fieldNames.add('CreatedById');
                        }
                    }
                }
            }
        }

        if (fieldNames.size() == 0) {
            return null;
        }

        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', recordId);
        QueryBuilder qb = new QueryBuilder(fieldNames, objectName, fc);
        qb.setLimit(1);

        System.debug('GET RECORD QUERY ' + qb.toString());
        return Database.query(qb.toString());
    }

    private static Audience getAudience(User u) {
        String profileName = u.Profile.Name.toLowerCase();

        System.debug('Profile name: ' + profileName);
        Audience aud;
        if (profileName.contains('vendor')) {
            aud = Audience.VENDOR;
        }
        else if (profileName.contains('hiring manager')) {
            aud = Audience.HIRING_MANAGER;
        }
        else if (profileName.contains('professional')) {
            aud = Audience.PROFESSIONAL;
        }
        else {
            throw new PortalButtonLogicHandlerException('Could not identify audience from profile: ' + profileName);
        }
        return aud;
    }

    private static String getAccountName(User u, Audience aud, String objectName, String accountNameField, Id recordId) {
        String accountField = String.isBlank(accountNameField)? 'Account__r.Name': accountNameField; 
        if (aud == Audience.HIRING_MANAGER) {
            return u.Account_name__c;
        }
        else { 
            QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', recordId);
            QueryBuilder qb = new QueryBuilder(new Set<String>{accountField}, objectName, new List<QueryBuilder.FilterClause>{fc}); // This assumes the object has a lookup field named Account__c which is filled
            qb.setLimit(1);

            System.debug('Get account name ' + qb.toString());
            SObject obj = Database.query(qb.toString());
            System.debug('OBJ ' + obj);
            return DeveloperUtils.getFieldValueAsString(obj, accountField);
        }
    }

    class ApprovalProcessInfo {
        // The may be multiple approvers hence multiple recallable items
        Map<String, Set<Id>> recallableWorkItemsByProcessName = new Map<String, Set<Id>>();

        // There should only be one work item approvable by user
        Map<String, Id> approvableWorkItemByProcessName = new Map<String, Id>();

        // Helps determine whether a record can be submitted for approval
        Set<String> activeProcessesForRecord = new Set<String>();

        // Rules on who can submit a record for approval
        Map<Id, List<Portal_button_approval_submitter__mdt>> approvalSubmitterByVisibilityId;

        List<Group> userGroups;
        Set<Id> validActorIds; // Groups, roles that user can act on behalf of

        /* Handles getting any restrictions on who can submit a record for approval (same as in approval process)*/
        private Map<Id, List<Portal_button_approval_submitter__mdt>> getApprovalSubmitterFiltersByVisibilityId(Set<Id> visibilityIds) {
            // Get any criteria defined for users who can or cannot submit records for approval process
            List<PB_approval_submitter_for_visibility__mdt> approvalSubmitters = [
                SELECT Portal_button_approval_submitter__r.Type__c, Portal_button_approval_submitter__r.Role_name__c, Portal_button_approval_submitter__r.Group_name__c, Visibility__c
                FROM PB_approval_submitter_for_visibility__mdt
                WHERE Visibility__c IN :visibilityIds
            ];

            Map<Id, List<Portal_button_approval_submitter__mdt>> submitterFiltersByVisibilityId = new Map<Id, List<Portal_button_approval_submitter__mdt>>();
            for (PB_approval_submitter_for_visibility__mdt filter: approvalSubmitters) {
                if (submitterFiltersByVisibilityId.get(filter.Visibility__c) == null) {
                    submitterFiltersByVisibilityId.put(filter.Visibility__c, new List<Portal_button_approval_submitter__mdt>());
                }
                submitterFiltersByVisibilityId.get(filter.Visibility__c).add(filter.Portal_button_approval_submitter__r);
            }

            return submitterFiltersByVisibilityId;
        }

        private List<Group> getUserGroups(Id userId) {
            Set<Id> groupIds = SchemaUtils.getGroupsUserIsPartOf(userId);
            if (groupIds != null && groupIds.size() != null) {
                return [SELECT Name, Id FROM Group WHERE Id IN :groupIds];
            }
            return null;
        }

        ApprovalProcessInfo(Id recordId, Id userId, String objectName, Set<Id> visibilityIds) {
            // Get active approval processes
            List<ProcessInstanceWorkitem> pendingApprovalsForRecord = ApprovalController.getPendingApprovalRequestsWithTargetId(recordId);
            userGroups = getUserGroups(userId);
            validActorIds = DeveloperUtils.getIdFieldSet(userGroups, 'Id');
            validActorIds.add(userId);

            System.debug('Actor Ids: ' + validActorIds);
            System.debug('Pending approvals: ' + pendingApprovalsForRecord);

            for (ProcessInstanceWorkItem appr: pendingApprovalsForRecord) {
                System.debug('Pending approval actor Id: ' + appr);
                String approvalProcessName = appr.ProcessInstance.ProcessDefinition.DeveloperName;
    
                activeProcessesForRecord.add(approvalProcessName);
                System.debug('User id: ' + userId);
                System.debug('Original actor id ' + appr?.ProcessInstance?.SubmittedById);
                // User submitted request, so can recall it
                if (appr.ProcessInstance.SubmittedById == userId) {
                    System.debug('SAME');
                    if (recallableWorkItemsByProcessName.get(approvalProcessName) == null)  {
                        recallableWorkItemsByProcessName.put(approvalProcessName, new Set<Id>());
                    }
                    recallableWorkItemsByProcessName.get(approvalProcessName).add(appr.Id);
                }
                // User can approve or reject approval
                if (validActorIds.contains(appr.ActorId)) {
                    if (approvableWorkItemByProcessName.get(approvalProcessName) != null) {
                        throw new PortalButtonLogicHandlerException('Duplicate approval request found for ' + objectName + ' with id ' 
                        + recordId + ' approvable by user with Id ' + userId);
                    }
                    approvableWorkItemByProcessName.put(approvalProcessName, appr.Id);
                }
            }

            approvalSubmitterByVisibilityId = getApprovalSubmitterFiltersByVisibilityId(visibilityIds);
        }
    }
    
    public class Button {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String variant;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String approvalProcessName;
        @AuraEnabled
        public String actionName;
        @AuraEnabled
        public String actionType;
        @AuraEnabled
        public List<Id> recallWorkItemIds;
        @AuraEnabled
        public Id approveRejectWorkItemId;
        @AuraEnabled 
        public String flowName;
        @AuraEnabled 
        public String approvalFlowName;
        @AuraEnabled
        public Boolean visible;
        @AuraEnabled
        public Boolean hasManualApprover;
        @AuraEnabled
        public Boolean approverIsVendor;
        @AuraEnabled
        public Id approverContactId;
        @AuraEnabled 
        public Id taskOwnerId;
        @AuraEnabled
        public String taskType;

        private void getLabel(Portal_button_configuration__mdt config) {
            try {
                label = System.Label.get('', config.Styling__r.Label__c, UserInfo.getLanguage());
            }
            catch (Exception e) {
                label = config.Styling__r.Label__c;
            }
        }

        private Id getVendorContact(Id vendorId) {
            return [SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :vendorId LIMIT 1].Contact__c;
        }

        public Button(Portal_button_configuration__mdt config, SObject record, Boolean v) {
            getLabel(config);
            variant = config.Styling__r.Variant__c;
            type = config.Type__c;
            approvalProcessName = config.Approval_process_name__c;
            actionName = config.Action__r.Action__c;
            actionType = config.Action__r.Action_type__c;
            flowName = config.Action__r.Flow_name__c;
            approvalFlowName = config.Action__r.Approval_flow_name__c;
            visible = v;
            hasManualApprover = config.Manually_selected_approver__c;
            approverIsVendor = config.Approver_default_vendor__c;
            if (hasManualApprover) {
                if (approverIsVendor) {
                    approverContactId = getVendorContact((Id)record.get('Vendor__c'));
                }
                else {
                    approverContactId = (Id)DeveloperUtils.getFieldValueAsString(record, config.Approver_contact_field__c);
                }
            }
            if (String.isNotBlank(config.Task_owner_field__c)) {
                taskOwnerId = (Id)DeveloperUtils.getFieldValueAsString(record, config.Task_owner_field__c);
                taskType = config.Task_type__c;
            }
        }

        public Button(Portal_button_configuration__mdt config, SObject record, Boolean v, Id workItemId) {
            this(config, record, v);
            approveRejectWorkItemId = workItemId;
        }

        public Button(Portal_button_configuration__mdt config, SObject record, Boolean v, Set<Id> workItemIds) {
            this(config, record, v);
            recallWorkItemIds = new List<Id>(workItemIds);
        }
    }

    public class ButtonInfo {
        @AuraEnabled 
        public String audience { get; set; }
        @AuraEnabled 
        public String objectName { get; set; }
        @AuraEnabled
        public List<Button> buttons { get; set; }
    }

    private static String getAccountFieldName(String objectName) {
        List<Portal_button_account_field_name__mdt> buttonAccountNames = [SELECT Account_field_api_name__c FROM Portal_button_account_field_name__mdt WHERE Object_api_name__c = :objectName LIMIT 1];
        
        return (buttonAccountNames == null || buttonAccountNames.size() == 0)? 'Account__r.Name': buttonAccountNames[0].Account_field_api_name__c;

    }

    @AuraEnabled(cacheable=true)
    public static ButtonInfo getButtons(Id recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }
        Id userId = UserInfo.getUserId();
        String objectName = SchemaUtils.getObjectNameByRecordId(recordId);
        User u = [SELECT Account_name__c, Profile.Name FROM User WHERE Id =:userId LIMIT 1];

        Audience aud = getAudience(u);
        String accountFieldName = getAccountFieldName(objectName);
        String accountName = getAccountName(u, aud, objectName, accountFieldName, recordId);
        Map<Id, Portal_button_configuration__mdt> configurations = getConfigurations(objectName, aud, accountName);
        Set<Id> visibilityIds = DeveloperUtils.getIdFieldSet(configurations.values(), 'Visibility__c');
        
        // Filters on fields that determine visibility (aka Status == 'New') or entry criteria for approvals
        Map<Id, List<Portal_button_filter__mdt>> fieldFiltersByVisibilityId = getFieldFiltersByVisibilitySetting(visibilityIds);

        // Information on all things approvals related
        ApprovalProcessInfo apprInfo = new ApprovalProcessInfo(recordId, userId, objectName, visibilityIds);

        // Get all fields from record we need to evaluate for filters etc

        System.debug('OBJECTNAAM: ' + objectName);
        SObject record = getRecord(recordId, objectName, configurations.values(), fieldFiltersByVisibilityId, apprInfo.approvalSubmitterByVisibilityId);

        List<Button> buttons = new List<Button>();
        for (Portal_button_configuration__mdt config: configurations.values()) {
            System.debug('CONFIG: ' + config);
            System.debug('VISIBILITY ID: ' + config.Visibility__c);
            Id visibilityId = config.Visibility__c;
            String configType = config.Type__c;
            String approvalProcessName = config.Approval_process_name__c;
            Boolean filterTruth = true;

            // If we are just checking whether a record can be recalled or approved/rejected, we don't need to query te record at all
            if (record != null && fieldFiltersByVisibilityId.get(visibilityId) != null) {
                filterTruth = PortalButtonVisibilityEvaluator.evaluateFilters(userId, objectName, config.Visibility__r.Filter_logic__c, 
                fieldFiltersByVisibilityId.get(visibilityId), record);
                System.debug('FILTER TRUTH: ' + filterTruth);

                if (!filterTruth) {
                    continue;
                }
            }


            System.debug('CONFIG TYPE: ' + configType);
            switch on configType {
                when 'Default' {
                    Button b = new Button(config, record, filterTruth);
                    buttons.add(b);
                }
                when 'Approval start' { // Visible if not already an active approval process for this record AND user is allowed to submit
                    Boolean recordCanBeSubmitted = !apprInfo.activeProcessesForRecord.contains(approvalProcessName);
                    Boolean isValidSubmitter = PortalButtonVisibilityEvaluator.evaluateApprovalSubmitter(
                        apprInfo.approvalSubmitterByVisibilityId.get(visibilityId), userId, record, apprInfo.userGroups);

                    Button b = new Button(config, record, (recordCanBeSubmitted && isValidSubmitter && filterTruth));
                    buttons.add(b);
                }
                when 'Approval approve reject' { // We need to check whether user can approve/reject this record -> active approval process + valid user
                    Boolean activeProcessProcessableByUser = (apprInfo.approvableWorkItemByProcessName.get(approvalProcessName) != null);

                    Button b = new Button(config, record, activeProcessProcessableByUser, apprInfo.approvableWorkItemByProcessName.get(approvalProcessName));
                    buttons.add(b);
                }
                when 'Approval recall' { // Only possible if active approval process and user was original submitter
                    Boolean recallableApprovalProcess = (apprInfo.recallableWorkItemsByProcessName.get(approvalProcessName) != null);

                    Button b = new Button(config, record, recallableApprovalProcess, apprInfo.recallableWorkItemsByProcessName.get(approvalProcessName));
                    buttons.add(b);
                }
                when else {
                    throw new PortalButtonLogicHandlerException('Specified Portal button configuration type ' + configType + ' not found for config with Id ' + record);
                }
            }
        }

        System.debug('BUTTONS');
        DeveloperUtils.printList(buttons);
        ButtonInfo buttonInfo = new ButtonInfo();
        buttonInfo.objectName = objectName;
        buttonInfo.audience = String.valueOf(aud);
        buttonInfo.buttons = buttons;
        return buttonInfo;
    }

    // public class ActionWrapper {
    //     @AuraEnabled
    //     public static Id recordId;
    //     @AuraEnabled
    //     public static String approvalProcessName;
    //     @AuraEnabled
    //     public static Set<Id> recallWorkItemIds;
    //     @AuraEnabled
    //     public static Id approveRejectWorkItemId;
    //     @AuraEnabled
    //     public static Id recallWorkItemIds;

    //     public ActionWrapper(String jsonObj) {
    //         this = JSON.deserialize(jsonObj, ActionWrapper.class);
    //     }
    // }

    @AuraEnabled
    public static void callAction(String actionName, Map<String, Object> arguments) {
        System.debug('callAction');

        try {
            switch on actionName {
                when 'Submit approval' {
                    Id approverContactId = (Id)arguments.get('approverContactId');

                    if (String.isBlank(approverContactId)) {
                        ApprovalController.submitApprovalRequest((Id)arguments.get('recordId'), 
                        (String)arguments.get('approvalProcessName'), '');
                    }
                    else {
                        ApprovalController.submitApprovalRequestToUser((Id)arguments.get('recordId'), 
                        (String)arguments.get('approvalProcessName'), SchemaUtils.getUserFromContactId(approverContactId));
                    }
                }
                when 'Recall approval' {
                    List<ApprovalController.ApprovalHandlerWrapper> handlers = new List<ApprovalController.ApprovalHandlerWrapper>();
                    Set<Id> piwis = new Set<Id>();
                    
                    List<Object> ids = (List<Object>)arguments.get('recallWorkItemIds');
                    for (Object o: ids) {
                        piwis.add((Id)o);
                    }

                    for (Id pId: piwis) {
                        handlers.add(new ApprovalController.ApprovalHandlerWrapper(pId, 'Removed', ''));
                    }
                    ApprovalController.processApprovalRequests(handlers);
                }
                when 'Approve approval' {
                    if ((Boolean)arguments.get('hasManualApprover')) {
                        ApprovalController.processApprovalRequest(
                            new ApprovalController.ApprovalHandlerWrapper((Id)arguments.get('approveRejectWorkItemId'), 'Approve', '', (Id)arguments.get('approverContactId')));
                    }
                    else {
                        ApprovalController.processApprovalRequest(new ApprovalController.ApprovalHandlerWrapper((Id)arguments.get('approveRejectWorkItemId'), 'Approve', ''));
                    }
                }
                when 'Reject approval' {
                    ApprovalController.processApprovalRequest(new ApprovalController.ApprovalHandlerWrapper((Id)arguments.get('approveRejectWorkItemId'), 'Reject', ''));
                }
                when 'Placement request' {
                    System.debug('Placement request');
                    ApprovalController.processApprovalRequest(
                            new ApprovalController.ApprovalHandlerWrapper((Id)arguments.get('approveRejectWorkItemId'), 'Approve', '', (Id)arguments.get('approverContactId')));
                    TaskHandler.createTask(new TaskHandler.TaskWrapper(
                        (String)arguments.get('taskType'),
                        (Id)arguments.get('recordId'),
                        (Id)arguments.get('taskOwnerId'),
                        Date.today() + 3
                    ));
                }
                when else {
                    throw new PortalButtonLogicHandlerException('Could not identify action: ' + actionName);
                }
            }
        }
        catch(Exception e) {
            throw new AuraHandledException('Something went wrong: ' + e.getMessage());
        }
    }
}