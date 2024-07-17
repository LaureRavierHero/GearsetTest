public without sharing class ApplicationSharingHandler {
    // Without sharing because Customer Community Plus users do not have access to Share objects
    public class ApplicationSharingException extends Exception {}

    // private static void shareRecord(List<Id> recordIds, List<Id> recipientIds, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     List<Application__Share> posShares = new List<Application__Share>();
        
    //     for (Id recordId: recordIds) {
    //         for (Id recipientId: recipientIds) {
    //             Application__Share posShare = new Application__Share();

    //             posShare.ParentId = recordId;
    //             posShare.UserOrGroupId = recipientId;
    //             posShare.AccessLevel = accessLevel;
    //             posShare.RowCause = sharingRule;

    //             posShares.add(posShare);
    //         }
    //     }
        
    //     Database.SaveResult[] sr = Database.insert(posShares, false);
    //     DatabaseResultHandler.handlerDatabaseResults(sr);
    // }

    // private static void shareRecord(Id recordId, List<Id> recipientIds, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(new List<Id>{recordId}, recipientIds, accessLevel, sharingRule);
    // }

    // private static void shareRecord(List<Id> recordIds, Id recipientId, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(recordIds, new List<Id>{recipientId}, accessLevel, sharingRule);
    // }

    // private static void shareRecord(Id recordId, Id recipientId, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(new List<Id>{recordId}, new List<Id>{recipientId}, accessLevel, sharingRule);
    // }

    public static void shareRecordWithHiringDesk(Id applicationId) {
        List<Application__c> apps = [SELECT Position__r.Account__r.Hiring_desk_group_id__c FROM Application__c WHERE Id = :applicationId];

        System.debug('Applications: ' + apps);
        System.debug('Applications: ' + apps[0].Position__c);
        System.debug('Applications: ' + apps[0].Position__r?.Account__c);
        System.debug('Applications: ' + apps[0].Position__r?.Account__r?.Hiring_desk_group_id__c);
        if (apps == null || apps.size() == 0 || String.isBlank(apps[0].Position__r?.Account__r?.Hiring_desk_group_id__c)) {
            throw new ApplicationSharingException('Could not find hiring desk group from account associated with application with Id ' + applicationId);
        }
        
        Id hiringDeskGroupId = apps[0].Position__r.Account__r.Hiring_desk_group_id__c;

        SharingHandler.shareRecord(applicationId, hiringDeskGroupId, SharingHandler.AccessLevel.EDIT, Schema.Application__Share.RowCause.Hiring_desk__c, 'Application__Share');
    }

    public static void shareRecordsWithHiringManager(Id positionId, List<Id> applicationIds, Id hiringManagerUserId) {
        SharingHandler.shareRecord(applicationIds, hiringManagerUserId, SharingHandler.AccessLevel.EDIT, Schema.Application__Share.RowCause.Hiring_manager__c, 'Application__Share');
    }
}