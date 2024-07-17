@istest
public class VendorsByCategoryControllerTest {
    @istest
	static void doesPositionCategoryExistTest() {
		Position__c p = TestDataFactory.getPosition(true);
		insert p;

		Category__c c = new Category__c();
		c.Name = 'Programming';
		c.Account__c = p.Account__c;
		insert c;

		Position_category__c pC = new Position_category__c();
		pC.Position__c = p.Id;
		pc.Category__c = c.Id;
		pC.Account__c = p.Account__c;
		insert pC;
		
		Test.startTest();
		Integer result = VendorsByCategoryController.doesPositionCategoryExist(p.Id);
		Test.stopTest();

		Assert.isTrue(result > 0);
	}

	@istest
	static void getVendorsWithMatchingCategoriesTest() {
		Position__c p = TestDataFactory.getPosition(true);
		insert p;

		Category__c c = new Category__c();
		c.Name = 'Programming';
		c.Account__c = p.Account__c;
		insert c;

		Position_category__c pC = new Position_category__c();
		pC.Position__c = p.Id;
		pc.Category__c = c.Id;
		pC.Account__c = p.Account__c;
		insert pC;
		
		// Vendor__c v = TestDataFactory.getVendor();
		// insert v;

		Vendor_contact_categories__c vCC = new Vendor_contact_categories__c();
		// vCC.Vendor__c = v.Id;
		vCC.Category__c = c.Id;
		vCC.Account__c = p.Account__c;
		insert vCC;
		
		Test.startTest();
		VendorsByCategoryController.VendorList vendors = VendorsByCategoryController.getVendors(p.Id);
		Test.stopTest();

		// Assert.isTrue(!vendors.isEmpty());
	}

	// @istest
	// static void getRemainingVendorsTest() {
	// 	Position__c p = TestDataFactory.getPosition(true);
	// 	insert p;

	// 	Category__c c = new Category__c();
	// 	c.Name = 'Programming';
	// 	c.Account__c = p.Account__c;
	// 	insert c;

	// 	Position_category__c pC = new Position_category__c();
	// 	pC.Position__c = p.Id;
	// 	pc.Category__c = c.Id;
	// 	pC.Account__c = p.Account__c;
	// 	insert pC;
		
	// 	Account v = TestDataFactory.getVendor();
	// 	insert v;

	// 	Vendor_contact_categories__c vCC = new Vendor_contact_categories__c();
	// 	vCC.Vendor__c = v.Id;
	// 	vCC.Category__c = c.Id;
	// 	vCC.Account__c = p.Account__c;
	// 	insert vCC;
		
	// 	Test.startTest();
	// 	List<VendorsByCategoryController.VendorList> vendors = VendorsByCategoryController.getRemainingVendors(p.Id);
	// 	Test.stopTest();

	// 	System.assert(vendors.isEmpty());
	// }

	@istest
	static void sendToVendorsTest() {
		Account a = TestDataFactory.getAccount();
		insert a;

		Position__c p = TestDataFactory.getPosition(false);
		insert p;

		User u = TestDataFactory.getUser(a);
        insert u;

		Account v = TestDataFactory.getVendor();
		insert v;

		List<Id> vendorIds = new List<Id>();
		vendorIds.add(v.Id);

		Test.startTest();
		VendorsByCategoryController.sendToVendors(p.Id, vendorIds);
		Test.stopTest();

		List<Vendor_position_application__c> conns = [SELECT Position__c, Vendor__c FROM Vendor_position_application__c WHERE Position__c = :p.Id AND Vendor__c = :v.Id];

		System.assertEquals(vendorIds.size(), conns.size());
	}

	@istest
	static void createNewPositionTaskForVendorsTest() {
		Account v = TestDataFactory.getVendor();
		insert v;
		
		Contact c = [SELECT Id FROM Contact WHERE Id IN (SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c = :v.Id) LIMIT 1];

        User u = TestDataFactory.getPortalUser(v, c);
        insert u;

		Position__c p = TestDataFactory.getPosition(false);
		p.End_date__c = System.today().addDays(10);
		insert p;

		List<Id> vendorIds = new List<Id>();
		vendorIds.add(v.Id);

		Test.startTest();
		VendorsByCategoryController.createNewPositionTaskForVendors(p, vendorIds);
		Test.stopTest();

		List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE Type = 'new_position_for_vendor' AND WhatId = :p.Id];

		Assert.areEqual(1, tasks.size());
	}
}