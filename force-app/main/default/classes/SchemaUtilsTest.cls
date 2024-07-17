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
private class SchemaUtilsTest {

    @isTest
    static void testWildCard() {

        Set<String> res = SchemaUtils.wildcardSelector('Position__c');

        System.assert(res.contains('Name'));
        System.assert(res.contains('Approval_status__c'));
    }

    @isTest
    static void testGetAllFieldNamesExpand() {
        String obj = 'Application__c';
        Map<String, List<String>> relationshipsByObj = new Map<String, List<String>>{
            'Application__c' => new List<String>{'Position__r'},//'Vendor__r'
            'Position__c' => new List<String>{'Account__r'}
            // 'Vendor__c' => new List<String>{'Account__r'}
        };

        Set<String> res = SchemaUtils.getAllFieldNames(obj, relationshipsByObj);

        System.assert(res.contains('Position__r.Account__r.Name'));
        System.assert(res.contains('Position__r.Id'));
        System.assert(res.contains('Position__c'));
    }

    @isTest
    static void testGetAllFieldNames() {
        String obj = 'Application__c';
        List<String> rels = new List<String>{'Position__r'}; // 'Vendor__r'

        Set<String> res = SchemaUtils.getAllFieldNames(obj, rels);

        // System.assert(res.contains('Vendor__r.Email__c'));
        System.assert(res.contains('Position__r.Id'));
        System.assert(res.contains('Position__c'));
    }

    @isTest
    static void testGetFieldType() {
        String objectName = 'Application__c';
        String fieldName = 'Status__c';

        Schema.DisplayType type = SchemaUtils.getFieldType(objectName, fieldName);

        System.assertEquals(Schema.DisplayType.PICKLIST, type);

        fieldName = 'Hours_available__c';
        type = SchemaUtils.getFieldType(objectName, fieldName);

        System.assertEquals(Schema.DisplayType.DOUBLE, type);
    }

    @isTest
    static void testInvalidObject() {
        try {
            Set<String> res = SchemaUtils.getAllFieldNames('Ladieda');
            System.Assert.fail();
        } catch (Exception e) {
            System.assert(e.getTypeName() == 'SchemaUtils.SchemaUtilsException');
        }
    }

    @isTest
    static void testGetRecordTypeId() {
        Id res = SchemaUtils.getRecordTypeId('Contact', 'Professional');

        System.assert(res != null);
    }

    @isTest
    static void testGetRecordTypeName() {
        Id recordTypeId = SchemaUtils.getRecordTypeId('Contact', 'Professional');
        String res = SchemaUtils.getRecordTypeName('Contact', recordTypeId);

        System.assert(res == 'Professional');
    }
}