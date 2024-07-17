trigger UserTrigger on User (before insert, before update, after insert, after update) {
    UserTriggerHandler handler = new UserTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}