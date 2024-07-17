public with sharing class MailtemplateTriggerHandler {
    private System.TriggerOperation triggerOperation;
    private List<Mailtemplate__c> newList;
    private List<Mailtemplate__c> oldList;
    private Map<Id, Mailtemplate__c> newMap;
    private Map<Id, Mailtemplate__c> oldMap;

    public MailtemplateTriggerHandler(System.TriggerOperation triggerOperation, List<Mailtemplate__c> newList, List<Mailtemplate__c> oldList, Map<Id, Mailtemplate__c> newMap, Map<Id, Mailtemplate__c> oldMap) {
        this.triggerOperation = triggerOperation;
        this.newList = newList;
        // this.newMap = newMap;
        // this.oldMap = oldMap;
        // this.oldList = oldList;
    }

    public void execute() {
        switch on this.triggerOperation {
            when BEFORE_INSERT {
                MailTemplateParser.cleanTemplates(newList);
            }
            // when AFTER_INSERT {}
            when BEFORE_UPDATE{
                MailTemplateParser.cleanTemplates(newList);
            }
            // when AFTER_UPDATE {}
            // when AFTER_DELETE {}
        }
    }
}