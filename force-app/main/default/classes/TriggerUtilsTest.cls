@istest
public class TriggerUtilsTest {
    @istest
    static void  testNameFormat() {
        Candidate__c c = TestDataFactory.getCandidate('Test', 'von der', 'Tester-Test Bob');
        TriggerUtils.setFullNames(new List<SObject>{c});
        System.assert(c.Name == 'Test von der Tester-Test Bob');
    }

    @istest
    static void  testAccountAdded() {
        Position__c p = TestDataFactory.getPosition(false);
        System.assert(TestUtils.accountWasAdded(p, 'Position__c'));
    }
}