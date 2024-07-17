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
@istest
public class SampleDataCreatorTest {

    @istest
    static void     testParseData() {
        Map<String, Object> dataToSerialize = new Map<String, Object> {
            'Account' => new List<Account>{ new Account(Name='Test Account')}
        };
        Map<String, List<SObject>> res = SampleDataCreator.parseData(JSON.serialize(dataToSerialize));

        System.assert(res.get('Account').size() == 1);
    }

    @istest
    static void     testParseDataInvalid() {
        /* Keys have to be valid object names, if not, error thrown */
        Boolean error = false;
        Map<String, Object> dataToSerialize = new Map<String, Object> {
            'BadName' => new List<Account>{ new Account(Name='Test Account')}
        };
        try {
            Map<String, List<SObject>> res = SampleDataCreator.parseData(JSON.serialize(dataToSerialize));
        }
        catch (SampleDataCreator.SampleDataCreatorException e) {
            error = true;
        }

        System.assert(error);
    }

    @istest
    static void     createTestData() {
        User u = TestDataFactory.getUser();
        insert u;

        Boolean error = false;

        try {
            SampleDataCreator.createSampleData('SampleData');
        }
        catch (Exception e) {
            error = true;
        }
        // System.assert(error == false);
    }

    @istest
    static void     createTestDataInvalidFileName() {
        Boolean error = false;
        try {
            SampleDataCreator.createSampleData('SampleDataInvalid');
        }
        catch (Exception e) {
            error = true;
        }

        System.assert(error);
    }

    @istest
    static void     deleteTestData() {
        Boolean error = false;
        try {
            SampleDataCreator.deleteSampleData('SampleData');
        }
        catch (Exception e) {
            error = true;
        }

        // System.assert(error == false);
    }
}