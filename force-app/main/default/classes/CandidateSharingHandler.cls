public with sharing class CandidateSharingHandler {
    public class CandidateSharingException extends Exception {}

    // private static void shareRecord(List<Id> recordIds, List<Id> recipientIds, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     List<Candidate__Share> canShares = new List<Candidate__Share>();
        
    //     for (Id recordId: recordIds) {
    //         for (Id recipientId: recipientIds) {
    //             Candidate__Share canShare = new Candidate__Share();

    //             canShare.ParentId = recordId;
    //             canShare.UserOrGroupId = recipientId;
    //             canShare.AccessLevel = accessLevel;
    //             canShare.RowCause = sharingRule;

    //             canShares.add(canShare);
    //         }
    //     }
        
    //     Database.SaveResult[] sr = Database.insert(canShares, false);
    //     DatabaseResultHandler.handlerDatabaseResults(sr);
    // }

    // private static void shareRecord(List<Id> recordIds, Id recipientId, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(recordIds, new List<Id>{recipientId}, accessLevel, sharingRule);
    // }

    // private static void shareRecord(Id recordId, Id recipientId, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(new List<Id>{recordId}, new List<Id>{recipientId}, accessLevel, sharingRule);
    // }

    public static void shareRecordWithHiringDesk(Id applicationId) {
        List<Application__c> apps = [SELECT Position__r.Account__r.Hiring_desk_group_id__c, Candidate__c FROM Application__c WHERE Id = :applicationId];

        if (apps == null || apps.size() == 0 || String.isBlank(apps[0].Position__r?.Account__r?.Hiring_desk_group_id__c)) {
            throw new CandidateSharingException('Could not find hiring desk group from account associated with application with Id ' + applicationId);
        }
        
        Id hiringDeskGroupId = apps[0].Position__r.Account__r.Hiring_desk_group_id__c;

        SharingHandler.shareRecord(apps[0].Candidate__c, hiringDeskGroupId, SharingHandler.AccessLevel.READ, Schema.Candidate__Share.RowCause.Hiring_desk__c, 'Candidate__Share');
    }

    public static void shareRecordsWithHiringManager(List<Id> applicationIds, Id hiringManagerUserId) {
        List<Application__c> apps = [SELECT Candidate__c FROM Application__c WHERE Id IN :applicationIds];

        List<Id> candidateIds = new List<Id>(DeveloperUtils.getIdFieldSet(apps, 'Candidate__c'));

        SharingHandler.shareRecord(candidateIds, hiringManagerUserId, SharingHandler.AccessLevel.READ, Schema.Candidate__Share.RowCause.Hiring_manager__c, 'Candidate__Share');
    }
}