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
private class CategoriesControllerTest {

    @isTest
    static void testAddRemovePositionCategory() {
        Category__c finance = TestDataFactory.getCategory('Finance');
        Category__c controlling = TestDataFactory.getCategory('Controlling');

        insert finance;
        insert controlling;

        Position__c pos = TestDataFactory.getPosition(false);

        insert pos;

        test.startTest();
        CategoriesController.addCategories(pos.Id, new List<Id>{finance.Id, controlling.Id});

        System.assert([SELECT Id FROM Position_category__c WHERE Position__c = :pos.Id].size() == 2);

        CategoriesController.removeCategory(pos.Id, finance.Id);

        System.assert([SELECT Id FROM Position_category__c WHERE Position__c = :pos.Id].size() == 1);
        test.stopTest();
    }

    @isTest
    static void testAddRemoveVendorCategory() {
        Category__c finance = TestDataFactory.getCategory('Finance');
        Category__c controlling = TestDataFactory.getCategory('Controlling');

        insert finance;
        insert controlling;

        Account vend = TestDataFactory.getVendor();

        insert vend;

        test.startTest();
        CategoriesController.addCategories(vend.Id, new List<Id>{finance.Id, controlling.Id});

        System.assert([SELECT Id FROM Vendor_contact_categories__c WHERE Vendor__c = :vend.Id].size() == 2);

        CategoriesController.removeCategory(vend.Id, finance.Id);

        System.assert([SELECT Id FROM Vendor_contact_categories__c WHERE Vendor__c = :vend.Id].size() == 1);
        test.stopTest();
    }

    @isTest
    static void testGetVendorCategories() {
        Category__c finance = TestDataFactory.getCategory('Finance');
        Category__c controlling = TestDataFactory.getCategory('Controlling');

        insert finance;
        insert controlling;

        Account vend = TestDataFactory.getVendor();

        insert vend;

        Vendor_contact_categories__c vendCat1 = TestDataFactory.getVendorCategory(vend.Id, finance.Id);

        insert vendCat1;

        Test.startTest();
        List<CategoriesController.CategoryInfo> categories = CategoriesController.getCategories(vend.Id, 'record');
        Test.stopTest();

        System.assert(categories.size() == 2);

        for (CategoriesController.CategoryInfo inf: categories) {
            if (inf.id == finance.Id) {
                System.assert(inf.selected == true);
            }
            else {
                System.assert(inf.selected == false);
            }
        }
    }

    @isTest
    static void testGetPositionCategories() {
        Category__c finance = TestDataFactory.getCategory('Finance');
        Category__c controlling = TestDataFactory.getCategory('Controlling');

        insert finance;
        insert controlling;

        Position__c pos = TestDataFactory.getPosition(false);

        insert pos;

        Position_category__c posCat1 = TestDataFactory.getPositionCategory(pos.Id, finance.Id);
        Position_category__c posCat2 = TestDataFactory.getPositionCategory(pos.Id, controlling.Id);

        insert posCat1;
        insert posCat2;

        List<CategoriesController.CategoryInfo> categories = CategoriesController.getCategories(pos.Id, 'record');

        System.assert(categories.size() == 2);

        for (CategoriesController.CategoryInfo inf: categories) {
            System.assert(inf.selected == true);
        }
    }
}