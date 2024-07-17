trigger ApplicationTrigger on Application__c (before insert, before update, after insert, after update) {
    ApplicationTriggerHandler handler = new ApplicationTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}