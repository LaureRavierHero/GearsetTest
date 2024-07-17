trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete, after delete) {
    AccountTriggerHandler handler = new AccountTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}