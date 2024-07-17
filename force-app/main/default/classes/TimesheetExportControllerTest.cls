@isTest
public class TimesheetExportControllerTest {
	@isTest
	public static void testTimesheetExportController() {

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

		TimesheetRegistrationController.TimesheetWrapper wrapper = TimesheetRegistrationController.getData(timesheet.Id);

		String professionalName = wrapper.entries[0].timelogs[0].Timesheet__r.Professional__r.Name;


		PageReference thePage = new PageReference('/apex/TimesheetExport');
		thePage.getParameters().put('recordid', timesheet.Id);
		Test.setCurrentPage(thePage);

		Test.startTest();
		TimesheetExportController controller = new TimesheetExportController();
		Test.stopTest();

		Assert.areEqual(professionalName, controller.professional);
	}
}