public without sharing class ApplicationFormController {
    class NumApplication {
        @AuraEnabled
        public Decimal numApplications;
        @AuraEnabled
        public Decimal numAllowed;
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getApplicationRecordTypeId(Id positionId){
        Id positionRecordTypeId = [SELECT RecordTypeId FROM Position__c WHERE Id = :positionId LIMIT 1].RecordTypeId;

        String recordTypeName = SchemaUtils.getRecordTypeName('Position__c', positionRecordTypeId);
        Id applicationRecordTypeId = SchemaUtils.getRecordTypeId('Application__c', recordTypeName);

        return applicationRecordTypeId;
    }

    @AuraEnabled(cacheable=true)
    public static NumApplication getNumApplications(Id recordId) {
        Id vendor = [
            SELECT AccountId FROM Contact WHERE Id IN (
            SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
            LIMIT 1].AccountId;

            System.debug('PositionID ' + recordId);
            System.debug('Vendor' + vendor);

        List<Vendor_position_application__c> conns = [
            SELECT Number_of_active_applications__c 
            FROM Vendor_position_application__c 
            WHERE Position__c = :recordId
            AND Vendor__c = :vendor
            LIMIT 1
        ];
        
        System.debug('Conn ' + conns);
        Position__c pos = [
            SELECT Max_number_of_applicants_number__c
            FROM Position__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        System.debug(pos);

        if (conns == null || conns.size() == 0) {
            return null;
        }
        
        NumApplication nApps = new NumApplication();
        nApps.numApplications = conns[0].Number_of_active_applications__c;
        nApps.numAllowed = pos.Max_number_of_applicants_number__c;

        System.debug(nApps);
        return nApps;
    }

    @AuraEnabled
    public static void submitForApproval(Id recordId) {
        ApprovalController.submitApprovalRequest(recordId);
    }
}