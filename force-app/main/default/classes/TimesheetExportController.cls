public with sharing class TimesheetExportController {
	public List<TimesheetRegistrationController.TimesheetEntries> entries {get;set;}
	public String professional {get;set;}
	public String employer {get;set;}
	public String job {get;set;}
	public Boolean anyExpensesMade {get;set;}

	public TimesheetExportController() {
		String recordId = ApexPages.currentPage().getParameters().get('recordid');

		TimesheetRegistrationController.TimesheetWrapper timesheets = TimesheetRegistrationController.getData(recordId);
		

		// System.debug('lookie here');
		// System.debug(timesheets.entries.timelogs);

		entries = timesheets.entries;

		Timesheet_entry__c firstEntry = entries[0].timelogs[0];

		professional = firstEntry.Timesheet__r.Professional__r.Name;
		employer = firstEntry.Timesheet__r.Placement__r.Account__r.Name;
		job = firstEntry.Timesheet__r.Placement__r.Name;
		anyExpensesMade = timesheets.anyExpensesMade;
	}
}