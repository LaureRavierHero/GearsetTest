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
private class DeveloperUtilsTest {
    @istest
    public static void utilityFormatDateToStringDDMMMYYYY() {
        Date now = Date.today();

        Test.startTest();
        String dateString = DeveloperUtils.formatDateToStringDDMMMYYYY(now);
        Test.stopTest();

        System.assert(String.isNotBlank(dateString));
    }
    
    @istest
    public static void testGetMonthNameByNumber(){
        Integer monthNumber = 12;

        Test.startTest();
        String monthName = DeveloperUtils.getMonthNameByNumber(monthNumber);
        Test.stopTest();

        System.assert(monthName == 'december');
    }

    @istest
    public static void utilityFormatDateTimeToStringDDMMYYY() {
        DateTime now = DateTime.now();

        Test.startTest();
        String dateTimeString = DeveloperUtils.formatDateTimeToStringDDMMYYYY(now);
        Test.stopTest();

        System.assert(String.isNotBlank(dateTimeString));
    }

    @istest
    public static void utilityFormatDateToStringYYYYMMDD() {
        Date now = Date.today();

        Test.startTest();
        String dateString = DeveloperUtils.formatDateToStringYYYYMMDD(now);
        Test.stopTest();

        System.assert(String.isNotBlank(dateString));
    }

    @isTest
    static void mapIdToNameTest() {
        User u = TestDataFactory.getUser();

        insert u;
        System.runAs(u) {
            List<Contact> profs = new List<Contact>();

            for (Integer i = 0; i < 3; ++i) {
                profs.add(TestDataFactory.getProfessional('Test', String.valueOf(i)));
            }
            insert profs;

            Set<Id> ids = DeveloperUtils.getIdFieldSet(profs, 'Id');
            List<Contact> resProfs = [ SELECT Name, Id FROM Contact WHERE Id IN :ids ];

            Test.startTest();
            Map<String, Id> profIdByName = DeveloperUtils.mapIdToName(resProfs);
            Test.stopTest();
            System.assert(profIdByName.keySet().contains('Test 0') && profIdByName.keySet().contains('Test 1')  && 
            profIdByName.keySet().contains('Test 2'));
        }
    }

    @isTest
    static void mapFirstNameLastNameTest() {
        User u = TestDataFactory.getUser();

        insert u;
        System.runAs(u) {
            List<Contact> profs = new List<Contact>();

            for (Integer i = 0; i < 3; ++i) {
                profs.add(TestDataFactory.getProfessional('Test' + String.valueOf(i), 'Last' + String.valueOf(i)));
            }
            insert profs;

            Test.startTest();
            Map<String, String> firstByLast = DeveloperUtils.mapStringFieldToStringField(profs, 'FirstName', 'LastName');
            Test.stopTest();

            System.assert(firstByLast.keySet().contains('Test0') && firstByLast.get('Test0') == 'Last0'
            && firstByLast.keySet().contains('Test1') && firstByLast.get('Test1') == 'Last1');
        }
    }

    @isTest
    static void getLastElementTest() {
        List<String> tst = new List<String>{'zero', 'one', 'two', 'three'};

        System.assert((String)DeveloperUtils.getLastElement(tst) == 'three');
    }
    
    @isTest
    static void sliceTestSimple() {
        List<String> tst = new List<String>{'zero', 'one', 'two', 'three'};
        List<String> res = (List<String>)DeveloperUtils.slice(tst, 1, 3);

        System.assert(res == new List<String>{'one', 'two'});
    }

    @isTest
    static void sliceTestNegative() {
        List<String> tst = new List<String>{'zero', 'one', 'two', 'three'};
        List<String> res = (List<String>)DeveloperUtils.slice(tst, -1);

        System.assert(res == new List<String>{'three'});
    }

    @isTest 
    static void getObjectFromFieldNameTest() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;

        System.runAs(u) {
            insert TestDataFactory.getApplication('Bob', 'Test', p, vend);
            
            SObject application = [SELECT Id, Name, Position__r.Name FROM Application__c LIMIT 1][0];

            Test.startTest();
            Position__c res = (Position__c)DeveloperUtils.getObjectFromFieldName(application, 'Position__r.Name');
            Test.stopTest();

            System.assert(res != null);
        }
    }

    @isTest
    static void mapValuesBetweenObjects() {
        Map<String, String> keyMap = new Map<String, String>{ 'First_name__c' => 'First_name__c'  };
        Candidate__c cand = new Candidate__c();
        cand.First_name__c = 'Lisa';
        Candidate__c cand2 = new Candidate__c();

        Test.startTest();
        DeveloperUtils.mapValuesFromObjectToObject(keyMap, cand, cand2);
        Test.stopTest();

        System.assertEquals('Lisa', cand2.First_name__c);
    }

    @isTest
    static void mapValuesObjectToMap() {
        Map<String, String> keyMap = new Map<String, String>{ 'First_name__c' => 'First_name__c'  };
        Candidate__c cand = new Candidate__c();
        cand.First_name__c = 'Lisa';
        Map<String, Object> cand2 = new Map<String, Object>();
    
        Test.startTest();
        DeveloperUtils.mapValuesFromObjectToMap(keyMap, cand, cand2);
        Test.stopTest();

        System.assertEquals('Lisa', cand2.get('First_name__c'));
    }

    @isTest
    static void testReverseMap() {
        Map<String, String> prevMap = new Map<String, String>{ 'key' => 'value' };

        Test.startTest();
        Map<String,String> newMap = DeveloperUtils.reverseMap(prevMap);
        Test.stopTest();

        System.assertEquals('key', newMap.get('value'));
    }

    @isTest
    static void testMapObjectToIdField() {
        Position__c pos = TestDataFactory.getPosition(true);

        insert pos;

        Id acc = [SELECT Account__c FROM Position__c WHERE Id=:pos.Id LIMIT 1].Account__c;

        Test.startTest();
        Map<Id, Position__c> res = (Map<Id, Position__c>)DeveloperUtils.mapObjectToIdField(
            new List<Position__c>{pos}, 'Account__c');
        Test.stopTest();
        
        System.assertEquals(acc, new List<Id>(res.keySet())[0]);
    }

    @isTest
    static void testGroupIdsByIdField() {
        Account a = TestDataFactory.getAccount();
        a.Hiring_desk_group_id__c = SchemaUtils.getGroupByName('Hero hiring desk');
        
        insert a;

        User u = TestDataFactory.getUserNoAccount();

        insert u;

        Position__c p = TestDataFactory.getPosition(false);
        p.Account__c = a.Id;
        insert p;

        Account vend = TestDataFactory.getVendor();

        insert vend;

        Application__c app = TestDataFactory.getApplication('Test', 'app1', p, vend);

        insert app;

        Test.startTest();
        Map<Id, Set<Id>> res = DeveloperUtils.groupIdsByIdField(new List<Application__c>{app}, 'Position__c', 'Id');
        Test.stopTest();

        System.assert(res.get(app.Position__c).contains(app.Id));
    }

    @isTest
    static void testGetRandomString() {
        String res = DeveloperUtils.getRandomString(8);

        System.assertEquals(8, res.length());
    }
}