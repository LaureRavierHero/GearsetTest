trigger CandidateTrigger on Candidate__c (before insert, before update, after insert, after update) {
    CandidateTriggerHandler handler = new CandidateTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}