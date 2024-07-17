@istest
public class UserTriggerHandlerTest {
    @istest
    static void     testAccountNameIdInsert() {
        user u = TestDataFactory.getUserNoAccount();
        Account a = TestDataFactory.getAccount(System.Label.ApexStandardAccountName);
        insert a;

        u.Account_name__c = a.Name;

        Test.startTest();
        insert u;
        Test.stopTest();

        User res = new List<User>([SELECT AccountId__c FROM User WHERE Id = :u.Id])[0];

        System.assert(res.AccountId__c == a.Id);
    }
}