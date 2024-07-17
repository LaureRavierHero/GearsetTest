public with sharing class ClosePositionController {
    @AuraEnabled
    public static Boolean checkCloseable(Id positionId) {
        List<Application__c> apps = [
            SELECT Id
            FROM Application__c
            WHERE Position__c = :positionId
            AND Status__c != 'Placement'
            AND Status__c != 'Rejected'
        ];

        return (apps == null || apps.size() == 0);
    }
}