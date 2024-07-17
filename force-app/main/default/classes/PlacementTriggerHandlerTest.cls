@istest
public class PlacementTriggerHandlerTest {
	@istest
	static void postToHeroOrg() {
		Placement__c placement = new Placement__c();

		Test.startTest();
		insert placement;
		Test.stopTest();
	}

	@istest
	static void postToHeroOrgWithContractsPlacementId() {
		Placement__c randomPlacement = new Placement__c();
		insert randomPlacement;

		Placement__c placement = new Placement__c();
		insert placement;

		placement.Contracts_Id__c = randomPlacement.Id;
		
		Test.startTest();
		update placement;
		Test.stopTest();
	}

	@istest
	static void testStatusActive(){
		Placement__c pl = TestDataFactory.getPlacement();
		pl.Status__c = 'New';
		insert pl;

		Test.startTest();
		pl.Sales_contract_status__c = 'Signed';
		pl.Purchase_contract_status__c = 'Signed';
		update pl;
		Test.stopTest();

		Assert.areEqual('Active', [SELECT Id, Processing_Status__c FROM Placement__c WHERE Id = :pl.Id].Processing_Status__c);
	}

	@istest
	static void testRelateStandardRatePercentage(){
		Placement__c pl = TestDataFactory.getPlacementWithRatePercentage();

		Test.startTest();
		Placement__c newPlacement = new Placement__c();
		newPlacement.Account__c = pl.Account__c;
		insert newPlacement;
		Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM Placement_rate_percentage__c WHERE Placement__c = :newPlacement.Id].size());
	}

	@istest
	static void testCheckStatusOnPosition(){
		Account acc = TestDataFactory.getAccount();
		insert acc;

		Position__c pos = TestDataFactory.getPosition(false);
		pos.Number_of_hires__c = '1';
		insert pos;

		Test.startTest();
		Placement__c pl = TestDataFactory.getPlacement();
		pl.Position__c = pos.Id;
		pl.Status__c = 'New';
		insert pl;
		Test.stopTest();

		Assert.areEqual('Hired', [SELECT Id, Status__c FROM Position__c WHERE Id = :pos.Id].Status__c);
	}

	@istest
	static void testCheckStatusOnPositionNotHired(){
		Account acc = TestDataFactory.getAccount();
		insert acc;

		Position__c pos = TestDataFactory.getPosition(false);
		pos.Number_of_hires__c = '2';
		insert pos;

		Test.startTest();
		Placement__c pl = TestDataFactory.getPlacement();
		pl.Position__c = pos.Id;
		pl.Status__c = 'New';
		insert pl;
		Test.stopTest();

		Assert.areEqual('Open', [SELECT Id, Status__c FROM Position__c WHERE Id = :pos.Id].Status__c);
	}

	@istest
	static void testCheckStatusOnPositionHiredMultiple(){
		Account acc = TestDataFactory.getAccount();
		insert acc;

		Position__c pos = TestDataFactory.getPosition(false);
		pos.Number_of_hires__c = '2';
		insert pos;

		Placement__c pl = TestDataFactory.getPlacement();
		pl.Position__c = pos.Id;
		pl.Status__c = 'New';
		insert pl;

		Test.startTest();
		Placement__c pl1 = new Placement__c();
		pl1.Position__c = pos.Id;
		pl1.Status__c = 'New';
		insert pl1;
		Test.stopTest();

		Assert.areEqual('Hired', [SELECT Id, Status__c FROM Position__c WHERE Id = :pos.Id].Status__c);
	}
}