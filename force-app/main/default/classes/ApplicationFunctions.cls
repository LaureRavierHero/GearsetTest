public with sharing class ApplicationFunctions {
    public static Id createProfessional(Id applicationId, String email, String phone) {
        Application__c app = [
            SELECT Candidate__r.First_name__c, Candidate__r.Last_name__c, Candidate__r.Preposition__c
            FROM Application__c
            WHERE Id = :applicationId
        ];

        Contact professional = new Contact();

        professional.FirstName = app.Candidate__r.First_name__c;
        professional.LastName = String.isNotBlank(app.Candidate__r.Preposition__c) ? (app.Candidate__r.Preposition__c + ' ' + app.Candidate__r.Last_name__c) : app.Candidate__r.Last_name__c;
        professional.Phone = phone;
        professional.Email = email;
        professional.RecordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Professional');
        professional.accountId = [SELECT Id FROM Account WHERE Name = 'Hero Interim Professionals' LIMIT 1].Id;

        insert professional;

        // Update application to reflect professional creation
        app = new Application__c();
        app.Id = applicationId;
        app.Professional__c = professional.Id;

        update app;

        return professional.Id;
    }

    // public class ProfessionalCreationWrapper {
    //     @InvocableVariable(required=true) public String phone;
    //     @InvocableVariable(required=true) public String email;
    //     @InvocableVariable(required=true) public Id applicationId;
    // }

    // @InvocableMethod(label = 'Create professional')
    // public static void createProfessional(List<ProfessionalCreationWrapper> wrappers) {
    //     createProfessional(wrappers[0].applicationId, wrappers[0].email, wrappers[0].phone);
    // }
}