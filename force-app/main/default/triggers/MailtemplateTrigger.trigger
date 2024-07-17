trigger MailtemplateTrigger on Mailtemplate__c (before insert, before update, after insert, after update) {
    MailtemplateTriggerHandler handler = new MailtemplateTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}