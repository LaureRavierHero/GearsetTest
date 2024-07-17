trigger PositionTrigger on Position__c (before insert, before update, after insert, after update) {
    PositionTriggerHandler handler = new PositionTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}