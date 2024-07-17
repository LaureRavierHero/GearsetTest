public with sharing class IntakeViewController {
    @AuraEnabled(cacheable=true)
    public static List<Intake__c> getMostRecentIntake(Id applicationId){
        if (String.isBlank(applicationId)) {
            return null;
        }

        List<Intake__c> intakes = [
            SELECT Id, toLabel(Type_of_intake__c), Date_of_intake__c, toLabel(Status__c)
            FROM Intake__c
            WHERE Application__c = :applicationId
            AND Status__c != 'Intake done'
            ORDER BY Date_of_intake__c DESC
        ];

        if (intakes == null || intakes.size() == 0) {
            return null;
        }

        return intakes;
    }
}