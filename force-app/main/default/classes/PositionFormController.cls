public with sharing class PositionFormController {
    @AuraEnabled
    public static Position__c getTemplate(Id templateId) {
        QueryBuilder.StringFilterClause fc = new QueryBuilder.StringFilterClause('Id', new Set<String>{templateId});
        QueryBuilder qb = new QueryBuilder(SchemaUtils.wildcardSelector('Position__c'), 'Position__c', fc);
        qb.setLimit(1);

        return Database.query(qb.toString());
    }

    @AuraEnabled
    public static void submitForApproval(Id positionId, String comment) {
        ApprovalController.submitApprovalRequest(positionId, 'Approve_new_position', comment);
    }

    @AuraEnabled(cacheable=true)
    public static Position__c getRecord(Id recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }
        
        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', recordId);
        QueryBuilder qb = new QueryBuilder(SchemaUtils.wildcardSelector('Position__c'), 'Position__c', fc);
        qb.setLimit(1);

        return Database.query(qb.toString());
    }

    @AuraEnabled
    public static Id getTemplateRecordTypeId(String typeId) {
        String recordTypeName = SchemaUtils.getRecordTypeName('Position__c', typeId);
        return SchemaUtils.getRecordTypeId('Position__c', recordTypeName + ' template');
    }

    @AuraEnabled
    public static Id getRecordTypeId(String typeName) {
        return SchemaUtils.getRecordTypeId('Position__c', typeName);
    }
}