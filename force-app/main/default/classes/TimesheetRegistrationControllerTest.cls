@istest
public class TimesheetRegistrationControllerTest {
	@istest
	public static void testGetData(){
		Account acc = TestDataFactory.getAccount();
		insert acc;
	
		Contact c = TestDataFactory.getContact();
		c.AccountId = acc.Id;
		insert c;
		
		User u = TestDataFactory.getPortalUser(acc, c);
		insert u;

		Timesheet__c timesheet = TestDataFactory.getTimesheetComplete(c.Id);
		insert timesheet;

		List<Timesheet_entry__c> entries = TestDataFactory.getTimesheetEntries(timesheet.Id);
		insert entries;

		Test.startTest();
		TimesheetRegistrationController.TimesheetWrapper wrapper = TimesheetRegistrationController.getData(timesheet.Id);
		Test.stopTest();

		Assert.areEqual(7, wrapper.entries.size());
		Assert.areEqual(1, wrapper.ratePercentages.size());
		Assert.isTrue(wrapper.timesheetId == timesheet.Id);
	}

	@istest
	public static void testSaveTimesheetEntries(){
		Account acc = TestDataFactory.getAccount();
		insert acc;
	
		Contact c = TestDataFactory.getContact();
		c.AccountId = acc.Id;
		insert c;
		
		User u = TestDataFactory.getPortalUser(acc, c);
		insert u;

		Timesheet__c timesheet = TestDataFactory.getTimesheetComplete(c.Id);
		insert timesheet;

		List<Timesheet_entry__c> entries = TestDataFactory.getTimesheetEntries(timesheet.Id);
		insert entries;
		
		Timesheet_entry__c singleEntry = TestDataFactory.getTimesheetEntry();
		singleEntry.Timesheet__c = timesheet.Id;
		singleEntry.Date__c = System.today();
		insert singleEntry;

		TimesheetRegistrationController.TimesheetWrapper wrapper = TimesheetRegistrationController.getData(timesheet.Id);

		wrapper.entries[0].timelogs.add(new Timesheet_entry__c(
			Timesheet__c = timesheet.Id,
			Comment__c = 'test'
		));

		List<String> idsToUpdate = new List<String>();
		idsToUpdate.add(wrapper.entries[0].timelogs[0].Id);

		List<String> idsToDelete = new List<String>();
		idsToDelete.add(wrapper.entries[0].timelogs[1].Id);

		Test.startTest();
		TimesheetRegistrationController.DMLResult result = TimesheetRegistrationController.saveTimesheetEntries(wrapper.entries, idsToUpdate, idsToDelete);
		Test.stopTest();

		Assert.areEqual(true, result.insertEntries);
		Assert.areEqual(true, result.updateEntries);
		Assert.areEqual(true, result.deleteEntries);
	}

	// @istest
	// public static void testSubmitForApproval(){
	// 	Account acc = TestDataFactory.getAccount();
	// 	insert acc;
	
	// 	Contact c = TestDataFactory.getContact();
	// 	c.AccountId = acc.Id;
	// 	insert c;
		
	// 	User u = TestDataFactory.getPortalUser(acc, c);
	// 	insert u;

	// 	Timesheet__c timesheet = TestDataFactory.getTimesheetComplete(c.Id);
	// 	// OPTIMIZE Yeah the user approves his own timesheet, big whoop what are you gonna do about it?
	// 	timesheet.Timesheet_approver__c = u.Id;
	// 	insert timesheet;

	// 	List<Timesheet_entry__c> entries = TestDataFactory.getTimesheetEntries(timesheet.Id);
	// 	insert entries;

	// 	Test.startTest();
	// 	TimesheetRegistrationController.submitForApproval(timesheet.Id);
	// 	Test.stopTest();

	// 	System.debug('verify time');

	// 	ProcessInstanceWorkitem piwi = [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :timesheet.Id LIMIT 1];
	// 	List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE Type = 'approve_timesheet'];

	// 	System.debug('tasks');
	// 	System.debug(tasks);

	// 	Assert.areEqual(1, tasks.size());
	// 	Assert.isTrue(piwi != null);
	// }
	
	// @istest	
	// public static void testReopen(){
	// 	Account acc = TestDataFactory.getAccount();
	// 	insert acc;
	
	// 	Contact c = TestDataFactory.getContact();
	// 	c.AccountId = acc.Id;
	// 	insert c;
		
	// 	User u = TestDataFactory.getPortalUser(acc, c);
	// 	insert u;

	// 	Timesheet__c timesheet = TestDataFactory.getTimesheetComplete(c.Id);
	// 	insert timesheet;

	// 	List<Timesheet_entry__c> entries = TestDataFactory.getTimesheetEntries(timesheet.Id);
	// 	insert entries;

	// 	TimesheetRegistrationController.submitForApproval(timesheet.Id);
		
	// 	Test.startTest();
	// 	TimesheetRegistrationController.reopen(timesheet.Id);
	// 	Test.stopTest();

	// 	Integer count = [SELECT COUNT() FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :timesheet.Id LIMIT 1];

	// 	Assert.areEqual(0, count);
	// }
}