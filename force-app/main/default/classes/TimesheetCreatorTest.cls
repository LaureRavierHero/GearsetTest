@istest
public class TimesheetCreatorTest {

    @istest
    public static void testCreateTimesheet(){
        Account acc = TestDataFactory.getAccount();
		insert acc;
	
		Contact c = TestDataFactory.getContact();
		c.AccountId = acc.Id;
		insert c;
        
        User u = TestDataFactory.getPortalUser(acc, c);
		insert u;

        c.User__c = u.Id;
        update c;

        Placement__c placement = TestDataFactory.getPlacement();
		placement.Professional__c = c.Id;
        placement.Start_Date__c = Date.newInstance(2024, 01, 25);
        placement.Expected_end_date__c = placement.Start_Date__c.addDays(60);
        placement.Timesheet_date_notation__c = 'Days';
        placement.Timesheet_size__c = 28;
		insert placement;

        Test.startTest();

        TimesheetCreator creator =  new TimesheetCreator();
        creator.createTimesheets(new Map<Id, Placement__c>([
            SELECT
                Id, Timesheets_created_till__c, Start_date__c, End_date__c,
                Name, Timesheet_date_notation__c, Timesheet_size__c, Expected_end_date__c, Cost_center__c, Approver_timesheets__c,
                Professional__c, Professional__r.User__c, Account__r.Standard_rate_percentage__c, Account__r.Name
            FROM
                Placement__c
        ]));
        
        Test.stopTest();

        List<Timesheet__c> timesheets = [SELECT Id, Placement__c, OwnerId FROM Timesheet__c WHERE Placement__c = :placement.Id];
        List<Timesheet_Entry__c> entries = [SELECT Id FROM Timesheet_Entry__c WHERE Timesheet__c = :timesheets[0].Id];

        Assert.areEqual(4, timesheets.size());
        Assert.areEqual(4, entries.size());
    }
}