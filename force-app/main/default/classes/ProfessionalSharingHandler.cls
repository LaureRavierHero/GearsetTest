public with sharing class ProfessionalSharingHandler {
    public class ProfessionalSharingException extends Exception {}

    private static void shareRecord(List<Id> contactIds, List<Id> vendorUserIds, String accessLevel) {
        List<ContactShare> shares = new List<ContactShare>();

    
        for (Id contactId: contactIds) {
            for (Id vendorUserId: vendorUserIds) {
                ContactShare share = new ContactShare();

                share.ContactId = contactId;
                share.ContactAccessLevel = accessLevel;
                share.RowCause = Schema.ContactShare.RowCause.Manual;
                share.UserOrGroupId = vendorUserId;

                shares.add(share);
            }
        }

        Database.SaveResult[] sr = Database.insert(shares, false);
        DatabaseResultHandler.handlerDatabaseResults(sr);
    }

    public static void shareRecordWithVendor(Id professionalId, Id vendorId) {
        List<User> vendorUsers = [
            SELECT Id 
            FROM User 
            WHERE ContactId 
                IN (
                SELECT Contact__c 
                FROM Default_vendor_contact__c 
                WHERE Vendor__c = :vendorId
            )
        ];

        if (vendorUsers == null || vendorUsers.size() == 0) {
            throw new ProfessionalSharingException('Could not find user associated with vendor with Id ' + vendorId);
        }

        shareRecord(new List<Id>{professionalId}, new List<Id>{vendorUsers[0].Id}, 'read');
    }
}