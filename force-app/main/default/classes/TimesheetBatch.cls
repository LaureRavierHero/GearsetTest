public class TimesheetBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Timesheets_created_till__c, Start_date__c, End_date__c, Placement__c.Approver_timesheets__c,'
            + ' Name, Timesheet_date_notation__c, Timesheet_size__c, Expected_end_date__c, Cost_center__c,'
            + ' Professional__c, Professional__r.User__c, Account__r.Standard_rate_percentage__c, Account__r.Name'
            + ' FROM Placement__c'
            + ' WHERE Create_timesheet__c = true'
        );
    }

    public void execute(Database.BatchableContext bc, List<Placement__c> scope) {
        Map<Id, Placement__c> placementIds = new Map<Id, Placement__c>(scope);

        System.debug('placementIds');
        System.debug(placementIds);

        TimesheetCreator creator = new TimesheetCreator();
        creator.createTimesheets(placementIds);
    }


    public void finish(Database.BatchableContext bc) {
    }
}