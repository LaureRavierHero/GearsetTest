public with sharing class WorkcomponentApplicationsController {
    // public class DocumentInfo {
    //     @AuraEnabled public Id cvId;
    //     @AuraEnabled public Id versionId;
    // }
    private static String mappingName = 'Application_to_wrapper';

    public class ApplicationWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String applicationName;
        @AuraEnabled public Boolean isPreferredCandidate;
        @AuraEnabled public Date availableFrom;
        @AuraEnabled public Decimal rate;
        @AuraEnabled public Decimal hoursAvailable;
        @AuraEnabled public Decimal rating;
        @AuraEnabled public String status;
        @AuraEnabled public String comment;
        @AuraEnabled public String rejectionReasonHiringDesk;
        @AuraEnabled public String sendToHiringManager;
        @AuraEnabled public Boolean reasonRejectionEditable;
        @AuraEnabled public String clarification;
        @AuraEnabled public Boolean STD_editable_col;//WorkcomponentSettingsController.STANDARD_EDITABLE_COL_NAME;
 
        /* Position fields */
        // TODO: something about money
        @AuraEnabled public Id positionId;
        @AuraEnabled public String positionName;
        @AuraEnabled public Datetime deadline;
        @AuraEnabled public Id hiringManagerId;
        @AuraEnabled public String hiringManagerName;
 
        /* Candidate fields */
        @AuraEnabled public Id candidateId;
        @AuraEnabled public String candidateName;
 
        /* Contact fields */
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
 
        /* Vendor fields */
        @AuraEnabled public Id vendorId;
        @AuraEnabled public String vendorName;
 
        /* Other fields */
        @AuraEnabled public Id cvId; // Contains DocumentId AND ContentVersionId
        @AuraEnabled public Id versionId;
        // @AuraEnabled public Id cvVersion;
       
        /* Fuctionality fields */
        @AuraEnabled public Boolean editable;
    }

    public static Map<String, String> fieldNamesByColumnNames {
        get {
            if (fieldNamesByColumnNames == null) {
                fieldNamesByColumnNames = new Map<String, String>();
                Dataweave_mapping__mdt mapper = [SELECT Id, DeveloperName FROM Dataweave_mapping__mdt WHERE DeveloperName = :mappingName LIMIT 1];

                List<Dataweave_Key_Mapping__mdt> mappings = [
                    SELECT incoming_key__c, outgoing_key__c
                    FROM Dataweave_Key_Mapping__mdt
                    WHERE Dataweave_Mapping__r.id = :mapper.id
                ];

                for (Dataweave_key_mapping__mdt mapping : mappings) {
                    fieldNamesByColumnNames.put(mapping.outgoing_key__c, mapping.incoming_key__c);
                }
            }
            return fieldNamesByColumnNames;
        }
        private set;
    }

    public static Map<String, String> columnNamesByFieldNames {
        get {
            if (columnNamesByFieldNames == null) {
                columnNamesByFieldNames = DeveloperUtils.reverseMap(fieldNamesByColumnNames);
            }
            return columnNamesByFieldNames;
        }
        private set;
    }
 
    @AuraEnabled(cacheable=true)
    public static WorkcomponentSettingsController.ComponentConfiguration   getSettings(String componentName) {
        return WorkcomponentSettingsController.getSettings(componentName, columnNamesByFieldNames);
    }
 
    public static WorkcomponentSettingsController.ComponentConfiguration getConfigurationFromJson(String componentJson) {
        if (String.isBlank(componentJson))
            return null;
       
        return (WorkcomponentSettingsController.ComponentConfiguration)JSON.deserialize(componentJson,
            WorkcomponentSettingsController.ComponentConfiguration.class);
    }
 
    private static List<ApplicationWrapper> getApplicationsInner(
        WorkcomponentSettingsController.ComponentConfiguration componentConfiguration,
        WorkComponentDataController controller) {
 
        List<Map<String, Object>> dataMap = controller.getData(componentConfiguration, mappingName);
        List<ApplicationWrapper> data = new List<ApplicationWrapper>();
 
        if (dataMap != null) {
            for (Map<String, Object> objMap: dataMap) {
                data.add((ApplicationWrapper)JSON.deserialize(JSON.serialize(objMap), ApplicationWrapper.class));
            }
        }
 
        return data;
    }
 
    @AuraEnabled(cacheable=true)
    public static List<ApplicationWrapper> getApplicationsProcessable(String componentConfigurationJson,
    String sortCol, String sortOrder, Id recordId) {
        WorkcomponentSettingsController.ComponentConfiguration componentConfiguration = getConfigurationFromJson(componentConfigurationJson);
       
        if (componentConfiguration == null) {
            return null;
        }
        String sortColApiName = fieldNamesByColumnNames.get(sortCol);
       
        // TODO: GET RIGHT FILTERS!! (Email sent, with hiring manager etc)
        List<QueryBuilder.FilterClause> filters = new List<QueryBuilder.FilterClause>();
        filters.add(new QueryBuilder.StringFilterClause('Status__c', 'New'));
        filters.add(new QueryBuilder.StringFilterClause('Position__c', recordId));
        filters.add(new QueryBuilder.StringFilterClause('Send_to_hiring_manager__c', 'Open', true));
 
        System.debug('filters: ' + filters);
        System.debug('sortColApiName: ' + sortColApiName);
        System.debug('sortOrder: ' + sortOrder);
 
        QueryBuilder.OrderClause order = new QueryBuilder.OrderClause(sortColApiName, sortOrder);
 
        WorkComponentDataController controller = new WorkComponentDataController(filters, order);
        return getApplicationsInner(componentConfiguration, controller);
    }
 
    @AuraEnabled(cacheable=true)
    public static List<ApplicationWrapper>    getData(String componentConfigurationJson,
    String sortCol, String sortOrder, Id recordId) {
        WorkcomponentSettingsController.ComponentConfiguration componentConfiguration = getConfigurationFromJson(componentConfigurationJson);
       
        if (componentConfiguration == null) {
            return null;
        }
        String sortColApiName = fieldNamesByColumnNames.get(sortCol);
 
        List<QueryBuilder.FilterClause> filters = new List<QueryBuilder.FilterClause>();
        filters.add(new QueryBuilder.StringFilterClause('Position__c', recordId));
 
        WorkComponentDataController controller;
        if (String.isNotBlank(sortCol) && String.isNotBlank(sortOrder)) {
            QueryBuilder.OrderClause order = new QueryBuilder.OrderClause(sortColApiName, sortOrder);
            controller = new WorkComponentDataController(filters, order);
        }
        else {
            controller = new WorkComponentDataController(filters);
        }
       
        return getApplicationsInner(componentConfiguration, controller);
    }
 
    @TestVisible
    private static List<Application__c> getApplicationsFromJson(String recordsJson) {
        System.debug(recordsJson);
        Dataweave_mapping__mdt mapping = [SELECT Id, DeveloperName FROM Dataweave_mapping__mdt WHERE DeveloperName = 'Application_to_wrapper' LIMIT 1];
        System.debug('mapping ' + mapping);

        String keyMap = TranslateJsonToObjects.fetchMappingFromCustomMetadata(mapping, true);
        System.debug('keyMap ' + keyMap);
        TranslateJsonToObjects translator = new TranslateJsonToObjects(recordsJson, keyMap);
        
        List<Application__c> applications = (List<Application__c>)translator.translateToSObjects('Application__c');
        System.debug('APPLICATIONS');
        DeveloperUtils.printList(applications);
 
        return applications;
    }
 
    @AuraEnabled
    public static void  updateRecords(String recordsJson) {
        List<Application__c> applications = getApplicationsFromJson(recordsJson);
        update applications;
    }
 
    /* Send email to Vendors about status change application and create relation between vendor and position */
    private static void     handleNotifyVendorApplicationStatusChange(List<Application__c> applications) {
        QueryBuilder qb = new QueryBuilder(new Set<String>{ 'Contact__c', 'Vendor__c' }, 'Default_vendor_contact__c');
        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Vendor__c', DeveloperUtils.getStringFieldSet(applications, 'Vendor__c'));
 
        qb.addFilterClause(fc);
 
        System.debug('QUERY' + qb.toString());
 
        List<Default_vendor_contact__c> defaultVendorContacts = Database.query(qb.toString());
        Map<Id, Id> contactByVendorId = DeveloperUtils.mapIdToIdField(defaultVendorContacts, 'Vendor__c', 'Contact__c');
 
        Map<Id, Id> contactByRecordId = new Map<Id, Id>();
 
        for (Application__c app: applications) {
            contactByRecordId.put(app.Id, contactByVendorId.get(app.Vendor__c));
        }
 
        List<MailWrapper> mails = new List<MailWrapper>();
        for (Application__c app: applications) {
            String mailType = (app.Status__c != 'Rejected')? 'Application to manager mail' : 'Application rejection email to vendor';
            mails.add(new MailWrapper(app.Id, contactByRecordId.get(app.Id), mailType));
        }
 
        MailHandler.sendEmails(mails);
    }
 
    // private static void     updateApplications(List<Application__c> applications) {
    //     List<Application__c> applicationsToUpdate = new List<Application__c>();

    //     System.debug('Update applications')
    //     for (Application__c app: applications) {
    //         Application__c a = new Application__c();
    //         a.Id = app.Id;
           
    //         if (app.Send_to_hiring_manager__c == 'Yes') {
    //             a.Status__c = 'Sent to hiring manager';
    //         }
    //         else {
    //             a.Status__c = 'Rejected';
    //         }
 
    //         applicationsToUpdate.add(a);
    //     }
 
    //     update applicationsToUpdate;
    // }
 
    private static void     updatePositionStatus(Id positionId) {
        Position__c pos = new Position__c(
            Id = positionId,
            Processing_status__c = 'Candidates offered and in review of manager'
        );
 
        update pos;
    }
 
    private static void shareApplicationsWithHiringManager(Id positionId, List<Application__c> applications, Id hiringManagerUserId) {
        List<Id> applicationIds = new List<Id>();
 
        for (Application__c app: applications) {
            if (app.Send_to_hiring_manager__c == 'Yes') {
                applicationIds.add(app.Id);
            }
        }
 
        ApplicationSharingHandler.shareRecordsWithHiringManager(positionId, applicationIds, hiringManagerUserId);
        CandidateSharingHandler.shareRecordsWithHiringManager(applicationIds, hiringManagerUserId);
        createTasks(applicationIds, hiringManagerUserId);
    }

    public static void createTasks(List<Id> applicationIds, Id hiringManagerUserId){
        List<TaskHandler.TaskWrapper> taskWrapperList = new List<TaskHandler.TaskWrapper>();
        for(Id applicationId : applicationIds){
            TaskHandler.TaskWrapper tw = new TaskHandler.TaskWrapper(
                'new_application_hiring_manager',
                applicationId,
                hiringManagerUserId,
                Date.today()
            );
            taskWrapperList.add(tw);
        }
        TaskHandler.createTasks(taskWrapperList);
    }
 
    private static void handleApprovalRequests(List<Application__c> applications, Id hiringManagerUserId) {
        System.debug('HANDLE APPROVAL REQUEST');
        List<ApprovalController.ApprovalHandlerWrapper> wrappers = new List<ApprovalController.ApprovalHandlerWrapper>();
        Map<Id, List<ProcessInstanceWorkitem>> pendingApprovalRequestsByApplicationId = ApprovalController.getPendingApprovalRequestsByTargetObject(
            new List<Id>(DeveloperUtils.getIdFieldSet(applications, 'Id')), 'Application_to_placement_Aspen');
 
        for (Application__c app: applications) {
            String action = app.Send_to_hiring_manager__c == 'Yes' ? 'Approve' : 'Reject';
            List<ProcessInstanceWorkItem> workItems = pendingApprovalRequestsByApplicationId.get(app.Id);
 
            if (workItems == null || workItems.size() != 1) {
                String error = 'Could not handle approval request for application with id ' + app.Id + ': ';
                error += (workItems == null || workItems.size() == 0)? 'no open request found.' : 'multiple requests found.';
                System.debug(LoggingLevel.ERROR, error);
            }
            else {
                ApprovalController.ApprovalHandlerWrapper wrap = new ApprovalController.ApprovalHandlerWrapper(
                    workItems[0].Id,
                    action,
                    app.Clarification_hiring_desk__c, // This may break
                    hiringManagerUserId
                );
 
                wrappers.add(wrap);
            }
        }

        System.debug('WRAPPERS ' + wrappers);
        ApprovalController.processApprovalRequests(wrappers);
        System.debug('Approval request done');
    }
 
    private static Id getUserId(Id positionId) {
        return [
            SELECT Id
            FROM User
            WHERE ContactId
            IN (
                SELECT Hiring_manager__c
                FROM Position__c
                WHERE Id = :positionId)
            LIMIT 1
        ].Id;
    }
 
    /* Updates ONLY comments written by hiring desk, since no other information is editable in the
    hiring desk review screen. Only updates if comment was written in that screen */
    @AuraEnabled
    public static void  handleRejectApproveApplicationsHiringDesk(String recordsJson, Id positionId) {
        try {
            Id hiringmanagerUserId = getUserId(positionId);

            List<Application__c> applications = getApplicationsFromJson(recordsJson);
            // updateApplications(applications);

            DeveloperUtils.printList(applications);
 
            QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', DeveloperUtils.getStringFieldSet(applications, 'Id'));
            QueryBuilder qb = new QueryBuilder(new Set<String>{'Vendor__c', 'Id', 'Status__c', 'Send_to_hiring_manager__c', 'Clarification_hiring_desk__c'}, 'Application__c');
            qb.addFilterClause(fc);
 
            List<Application__c> applicationsWithVendors = Database.query(qb.toString());
 
            System.debug('Applications with vendors');

            DeveloperUtils.printList(applicationsWithVendors);

            System.debug('notify vendor app status change');
 
            //handleNotifyVendorApplicationStatusChange(applicationsWithVendors);
            System.debug('update position status');
 
            updatePositionStatus(positionId);
 
            System.debug('handle approval req');
 
            handleApprovalRequests(applications, hiringmanagerUserId);
 
            System.debug('Sharing');
            shareApplicationsWithHiringManager(positionId, applications, hiringmanagerUserId);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.Error, e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean showHiringManagerCockpit(Id positionId){
        if (String.isBlank(positionId)) {
            return false;
        }

        List<String> doNotShowStatuses = new List<String>{'Concept', 'New', 'Rejected', 'Witdrawn'};
        
        Position__c pos = [
            SELECT Status__c, Is_template_position__c, Processing_status__c
            FROM Position__c
            WHERE Id = :positionId
        ];

        return (
            !doNotShowStatuses.contains(pos.Status__c)
            && pos.Processing_status__c != 'New'
            && pos.Is_template_position__c != 'Template_position'
        );
    }
}