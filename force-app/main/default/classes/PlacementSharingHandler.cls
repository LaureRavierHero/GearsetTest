public without sharing class PlacementSharingHandler {
    public class PlacementSharingException extends Exception {}

    public static void sharePlacementWithVendor(Id placementId) {
        Id vendorId = [
            SELECT Vendor__c
            FROM Placement__c
            WHERE Id = :placementId
            LIMIT 1
        ].Vendor__c;

        List<User> vendorUser = [
            SELECT Id
            FROM User
            WHERE ContactId IN (
                SELECT Contact__c
                FROM Default_vendor_contact__c
                WHERE Vendor__c = :vendorId
            )
        ];

        if (vendorUser == null || vendorUser.size() == 0) {
            throw new PlacementSharingException('Could not find vendor contact for placement with Id ' + placementId);
        }

        SharingHandler.shareRecord(placementId, vendorUser[0].Id, SharingHandler.AccessLevel.READ, Schema.Placement__Share.RowCause.Vendor__c, 'Placement__Share');
    }

    public static void sharePlacementWithProfessional(Id placementId) {
        List<User> professional = [
            SELECT Id 
            FROM User 
            WHERE ContactId IN (
                SELECT Professional__c FROM Placement__c WHERE Id = :placementId
            )
        ];

        if (professional == null || professional.size() == 0) {
            throw new PlacementSharingException('Could not professional associated with placement with Id ' + placementId);
        }
        SharingHandler.shareRecord(placementId, professional[0].Id, SharingHandler.AccessLevel.READ, Schema.Placement__Share.RowCause.Professional__c, 'Placement__Share');
    }
}