global class TimesheetBatchScheduler {
    global void execute(SchedulableContext ctx) {
        TimesheetBatch s = new TimesheetBatch();
        Database.executeBatch(s, 10);
    }
}