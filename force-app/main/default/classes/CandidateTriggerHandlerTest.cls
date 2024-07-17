@istest
public class CandidateTriggerHandlerTest {
	@istest
	static void testNameFormat() {
		Candidate__c c = TestDataFactory.getCandidate('Test', 'von der', 'Tester-Test Bob');
		System.assert(TestUtils.nameAdded(c, 'Candidate__c', 'Test von der Tester-Test Bob'));
	}

	@istest
	static void testUniqueId() {
		Candidate__c c = TestDataFactory.getCandidate('Test', 'von der', 'Tester-Test Bob');

		Test.startTest();
		insert c;
		Test.stopTest();

		// Candidate__c cand = new List<Candidate__c>([SELECT Account__c, Vendor__c, Name, UniqueId__c FROM Candidate__c WHERE Id = :c.Id])[0];
		// String expectedId = cand.Account__c + '_' + cand.Vendor__c + '_' + cand.Name.replace(' ', '_');
		// System.assert(expectedId == cand.UniqueId__c);
	}
}