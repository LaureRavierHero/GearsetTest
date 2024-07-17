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
private class QueryBuilderTest {
    @isTest
    static void queryBuilderSimplest() {
        QueryBuilder qb = new QueryBuilder('Application__c');
        qb.addSelectField('Name');

        QueryBuilder.OrderClause oc = new QueryBuilder.OrderClause('Name', QueryBuilder.sortOrder.ASCEND);
        QueryBuilder.LikeFilterClause lc = new QueryBuilder.LikeFilterClause('Name', '%a');

        qb.addFilterClause(lc);
        qb.addOrderClause(oc);

        System.assertEquals('SELECT Name\nFROM Application__c\nWHERE Name LIKE \'%a\'\nORDER BY Name ASC NULLS FIRST', qb.toString());
    }

    @isTest
    static void queryBuilderSimpleSelect() {
        Set<String> fields = new Set<String>{'Name', 'Id'};

        QueryBuilder qb = new QueryBuilder(fields, 'Application__c');

        String query = qb.toString(false);
        System.assert(query == 'SELECT Name,Id\nFROM Application__c');
    }

    @isTest
    static void queryBuilderSelectOrderBy() {
        Set<String> fields = new Set<String>{'Name', 'Id'};

        QueryBuilder.OrderClause oc = new QueryBuilder.OrderClause('Name');

        QueryBuilder qb = new QueryBuilder(fields, 'Application__c', new List<QueryBuilder.OrderClause>{oc});


        String query = qb.toString(false);
        System.assert(query == 'SELECT Name,Id\nFROM Application__c\nORDER BY Name ASC NULLS FIRST');
    }

    @isTest
    static void queryBuilderSelectFilterBy() {
        Set<String> fields = new Set<String>{'Name', 'Id'};
        List<Integer> dFilterVals = new List<Integer>{1, 2, 3};

        QueryBuilder.FilterClause fc = new QueryBuilder.IntegerFilterClause('Id', dFilterVals);
        QueryBuilder.FilterClause fc2 = new QueryBuilder.StringFilterClause('Name', new Set<String>{'Hi'});
        QueryBuilder qb = new QueryBuilder(fields, 'Application__c', new List<QueryBuilder.FilterClause>{fc, fc2});


        String query = qb.toString(false);
        System.assert(query == 'SELECT Name,Id\nFROM Application__c\nWHERE Id IN (1,2,3) AND Name IN (\'Hi\')');
    }

    @isTest
    static void queryBuilderSelectFilterOrderBy() {
        Set<String> fields = new Set<String>{'Name', 'Id'};
        List<Integer> dFilterVals = new List<Integer>{1, 2, 3};

        QueryBuilder.OrderClause oc = new QueryBuilder.OrderClause('Name', QueryBuilder.SortOrder.DESCEND, QueryBuilder.NullsPosition.NULLSFIRST);
        QueryBuilder.FilterClause fc = new QueryBuilder.IntegerFilterClause('Id', dFilterVals);
        QueryBuilder.FilterClause fc2 = new QueryBuilder.StringFilterClause('Name', new Set<String>{'Hi'});
        QueryBuilder qb = new QueryBuilder(fields, 'Application__c', new List<QueryBuilder.FilterClause>{fc, fc2}, new List<QueryBuilder.OrderClause>{oc});


        String query = qb.toString(false);
        System.assert(query == 'SELECT Name,Id\nFROM Application__c\nWHERE Id IN (1,2,3) AND Name IN (\'Hi\')\nORDER BY Name DESC NULLS FIRST');
    }
}