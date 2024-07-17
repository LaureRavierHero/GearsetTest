public without sharing class TimesheetSharingHandler {
    public class TimesheetSharingException extends Exception {}

    @InvocableMethod(label = 'Share timesheet Record')
    public static void shareRecordWithApprover(List<shareRecordWithApproverFlow> flowRecords){
        shareRecordWithApprover(flowRecords[0].recordId);
    }

    public static void shareRecordWithApprover(Id timesheetId) {
        List<Timesheet__c> timesheets = [SELECT Approver__c FROM Timesheet__c WHERE Id = :timesheetId];

        if (timesheets == null || timesheets.size() == 0 || String.isBlank(timesheets[0].Approver__c)) {
            throw new TimesheetSharingException('Could not find approver for timesheet with Id ' + timesheetId);
        }

        Id approverUserId = SchemaUtils.getUserFromContactId(timesheets[0].Approver__c);

        SharingHandler.shareRecord(timesheetId, approverUserId, SharingHandler.AccessLevel.EDIT, Schema.Timesheet__Share.RowCause.Approver__c, 'Timesheet__Share');
    }

    public class shareRecordWithApproverFlow{
        @InvocableVariable(required=true) public Id recordId;
    }
    
}