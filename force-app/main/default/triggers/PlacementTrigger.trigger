trigger PlacementTrigger on Placement__c (before insert, before update, after insert, after update, before delete, after delete) {
    PlacementTriggerHandler handler = new PlacementTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}