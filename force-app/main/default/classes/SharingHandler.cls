public without sharing class SharingHandler {
    public class SharingException extends Exception {}

    public enum AccessLevel {
        READ,
        EDIT
    }

    private static map<AccessLevel, String> accessLevelString = new Map<AccessLevel, String>{
        AccessLevel.READ => 'Read',
        AccessLevel.EDIT => 'Edit'
    };

    private static void shareRecord(List<Id> recordIds, List<Id> recipientIds, AccessLevel accessLevel, String sharingRule, 
    String objectName) {
        Type t = Type.forName(objectName);
        List<SObject> shares = new List<SObject>();

        for (Id recordId: recordIds) {
            for (Id recipientId: recipientIds) {
                SObject share = (SObject)t.newInstance();

                share.put('ParentId', recordId);
                share.put('UserOrGroupId', recipientId);
                share.put('AccessLevel', accessLevelString.get(accessLevel));
                share.put('RowCause', sharingRule);

                shares.add(share);
            }
        }

        Database.SaveResult[] sr = Database.insert(shares, false);
        DatabaseResultHandler.handlerDatabaseResults(sr);
    }

    public static void shareRecord(Id recordId, List<Id> recipientIds, AccessLevel accessLevel, String sharingRule, String objectName) { // accessLevel is Edit/Read/All
        shareRecord(new List<Id>{recordId}, recipientIds, accessLevel, sharingRule, objectName);
    }

    public static void shareRecord(List<Id> recordIds, Id recipientId, AccessLevel accessLevel, String sharingRule, String objectName) { // accessLevel is Edit/Read/All
        shareRecord(recordIds, new List<Id>{recipientId}, accessLevel, sharingRule, objectName);
    }

    public static void shareRecord(Id recordId, Id recipientId, AccessLevel accessLevel, String sharingRule, String objectName) { // accessLevel is Edit/Read/All
        shareRecord(new List<Id>{recordId}, new List<Id>{recipientId}, accessLevel, sharingRule, objectName);
    }
}