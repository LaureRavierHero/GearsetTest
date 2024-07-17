public without sharing class PositionSharingHandler {
    // Without sharing because Customer Community Plus users do not have access to Share objects
    public class PositionSharingException extends Exception {}

    // private static void shareRecord(Id recordId, List<Id> recipientIds, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     List<Position__Share> posShares = new List<Position__Share>();
        
    //     for (Id recipientId: recipientIds) {
    //         Position__Share posShare = new Position__Share();

    //         posShare.ParentId = recordId;
    //         posShare.UserOrGroupId = recipientId;
    //         posShare.AccessLevel = accessLevel;
    //         posShare.RowCause = sharingRule;

    //         posShares.add(posShare);
    //     }
        
    //     Database.SaveResult[] sr = Database.insert(posShares, false);

    //     DatabaseResultHandler.handlerDatabaseResults(sr);
    // }

    // private static void shareRecord(Id recordId, Id recipientId, String accessLevel, String sharingRule) { // accessLevel is Edit/Read/All
    //     shareRecord(recordId, new List<Id>{recipientId}, accessLevel, sharingRule);
    // }

    public static void shareRecordWithHiringDesk(Id positionId) {
        List<Position__c> pos = [SELECT Account__r.Hiring_desk_group_id__c FROM Position__c WHERE Id = :positionId];

        if (pos == null || pos.size() == 0 || String.isBlank(pos[0].Account__r?.Hiring_desk_group_id__c)) {
            throw new PositionSharingException('Could not find hiring desk group from account associated with position with Id ' + positionId);
        }
        
        Id hiringDeskGroupId = pos[0].Account__r.Hiring_desk_group_id__c;

        SharingHandler.shareRecord(positionId, hiringDeskGroupId, SharingHandler.AccessLevel.EDIT, Schema.Position__Share.RowCause.Hiring_manager_to_hiring_desk__c, 'Position__Share');
    }

    public static void shareRecordWithVendors(Id positionId, List<Id> vendorUserIds) {
        SharingHandler.shareRecord(positionId, vendorUserIds, SharingHandler.AccessLevel.READ, Schema.Position__Share.RowCause.Hiring_desk_to_vendor__c, 'Position__Share');
    }
}