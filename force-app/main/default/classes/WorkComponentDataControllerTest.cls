/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class WorkComponentDataControllerTest {
    public class ApplicationWrapper {
        @AuraEnabled public Id applicationId;
        @AuraEnabled public String applicationName;
        @AuraEnabled public Date availableFrom;
        @AuraEnabled public Decimal rate;
        @AuraEnabled public Decimal hoursAvailable;
        @AuraEnabled public Decimal rating;
        @AuraEnabled public String status;
        @AuraEnabled public String comment;
        @AuraEnabled public String rejectionReasonHiringDesk;
        @AuraEnabled public String sendToHiringManager;
        @AuraEnabled public Boolean reasonRejectionEditable;

        /* Position fields */
        // TODO: something about money
        @AuraEnabled public Id positionId;
        @AuraEnabled public String positionName;
        @AuraEnabled public Datetime deadline;
        @AuraEnabled public Id hiringManagerId;
        @AuraEnabled public String hiringManagerName;

        /* Candidate fields */
        @AuraEnabled public Id candidateId;
        @AuraEnabled public String candidateName;

        /* Contact fields */
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;

        /* Vendor fields */
        @AuraEnabled public Id vendorId;
        @AuraEnabled public String vendorName;

        /* Other fields */
        @AuraEnabled public Id cvId;
        @AuraEnabled public Id versionId;
    }

    public static Map<String, String> fieldNamesByColumnNames = new Map<String, String> {
        'applicationId' => 'Id',
        'applicationName' => 'Name',
        'availableFrom' => 'Available_from__c',
        'rate' => 'Desired_rate__c',
        'hoursAvailable' => 'Hours_available__c',
        'rating' => 'Review_score__c',
        'status' => 'Status__c',
        'comment' => 'Comment__c',
        'positionId' => 'Position__c',
        'positionName' => 'Position__r.Name',
        'deadline' => 'Position__r.Internal_deadline__c',
        'hiringManagerId' => 'Position__r.Hiring_manager__r.Id',
        'hiringManagerName' => 'Position__r.Hiring_manager__r.Name',
        'candidateId' => 'Candidate__c',
        'candidateName' => 'Candidate__r.Name',
        'contactId' => 'Contact__c',
        'contactName' => 'Contact__r.Name',
        'contactPhone' => 'Contact__r.Phone',
        'contactEmail' => 'Contact__r.Email',
        'vendorId' => 'Vendor__c',
        'vendorName' => 'Vendor__r.Name',
        'rejectionReasonHiringDesk' => 'Reason_rejection_hiring_desk__c',
        'sendToHiringManager' => 'Send_to_hiring_manager__c',
        'reasonRejectionEditable' => 'Reason_rejection_hd_editable__c',
        'cvId' => 'cvId',
        'versionId' => 'versionId'
    };

    public static Map<String, String> columnNamesByFieldNames = DeveloperUtils.reverseMap(fieldNamesByColumnNames);
    @isTest
    static void testGetData() {
        User u = TestDataFactory.getUser();

        insert u;
        System.runAs(u) {
        // List<Application__c> appList = new List<Application__c>();
        //     Position__c p = TestDataFactory.getPosition(false);
        //     insert p;
        //     for (Integer i = 0; i < 8; ++i) {
        //         appList.add(TestDataFactory.getApplicationWithCv('Fn_' + i, 'Ln_' + i, p));
        //         Application__c app = appList[i];
        //     }
        //     String componentName = 'Standard hiring desk workcomponent';

        //     Test.startTest();
        //     WorkcomponentSettingsController.ComponentConfiguration conf = WorkcomponentSettingsController.getSettings(componentName, columnNamesByFieldNames);
            
        //     List<QueryBuilder.FilterClause> filters = new List<QueryBuilder.FilterClause>();
        //     filters.add(new QueryBuilder.StringFilterClause('Position__c', p.Id));
        //     WorkComponentDataController contr = new WorkComponentDataController(filters);

        //     List<Map<String, Object>> res = contr.getData(conf, columnNamesByFieldNames);//(data, columnNamesByFieldNames, conf.queryFields);
        //     Test.stopTest();

        //     System.assert(res.size() == 8);
        }
    }

    @isTest
    static void testGetDataNoApplications() {
        User u = TestDataFactory.getUser();

        insert u;
        // System.runAs(u) {
        //     List<Application__c> appList = new List<Application__c>();
        //     Position__c p = TestDataFactory.getPosition(false);
        //     insert p;
        //     String componentName = 'Standard hiring desk workcomponent';

        //     Test.startTest();
        //     WorkcomponentSettingsController.ComponentConfiguration conf = WorkcomponentSettingsController.getSettings(componentName, columnNamesByFieldNames);
        //     List<QueryBuilder.FilterClause> filters = new List<QueryBuilder.FilterClause>();
        //     filters.add(new QueryBuilder.StringFilterClause('Position__c', p.Id));
        //     WorkComponentDataController contr = new WorkComponentDataController(filters);

        //     List<Map<String, Object>> res = contr.getData(conf, columnNamesByFieldNames);//(data, columnNamesByFieldNames, conf.queryFields);
        //     Test.stopTest();

        //     System.assert(res == null);
        // }
    }
}