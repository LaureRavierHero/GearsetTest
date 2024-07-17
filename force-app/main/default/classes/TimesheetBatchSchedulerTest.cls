@istest
public class TimesheetBatchSchedulerTest {
    @IsTest
    public static void testTimesheetBatchScheduler() {
        Test.startTest();
        new TimesheetBatchScheduler().execute(null);
        Test.stopTest();
    }
}