@istest
public class TestUtils {
	static Integer s_num = 1;

	/* Call these functions ONLY from test context */
	public static Boolean accountWasAdded(SObject testObj, String tableName) {
		User u = TestDataFactory.getUser();
		insert u;

		Id accId;
		Id pA;

		System.runAs(u) {
			Test.startTest();
			insert testObj;
			Test.stopTest();

			String queryString = 'SELECT Account__c FROM ' + tableName + ' WHERE Id = ' + '\'' + testObj.get('Id') + '\'';

			accId = [SELECT AccountId__c FROM User WHERE Id = :UserInfo.getUserId()][0].AccountId__c;
			pA = (Id)((Database.query(queryString)[0]).get('Account__c'));
		}
		return (accId == pA);
	}

	public static Boolean nameAdded(SObject testObj, String tableName, String expectedResult) {
		User u = TestDataFactory.getUserNoAccount();
		insert u;

		String fullName;
		System.runAs(u) {
			Test.startTest();
			insert testObj;
			Test.stopTest();

			String queryString = 'SELECT Name FROM ' + tableName + ' WHERE Id = ' + '\'' + testObj.get('Id') + '\'';
			fullName = (String)(Database.query(queryString)[0].get('Name'));

			System.debug('NAME: ' + fullName);
		}
		return (fullName == expectedResult);
	}

	public static String getFakeId(Schema.SObjectType sot){
		String result = String.valueOf(s_num++);
		return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
	}
}