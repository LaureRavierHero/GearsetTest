public with sharing class DossierTaskController {
    class DossierTaskControllerException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static List<DossierTaskWrapper> getDossierTasks() {
        List<File_object_task__c> fots = [SELECT Name, Deadline_date__c, Business_Central_id__c, Status_task__c FROM File_object_task__c];

        List<DossierTaskWrapper> dtwToReturn = new List<DossierTaskWrapper>();
        for(File_object_task__c fot : fots){
            DossierTaskWrapper wrapper = new DossierTaskWrapper();
            wrapper.Name = fot.Name;
            wrapper.Deadline_date = fot.Deadline_date__c;
            wrapper.Business_Central_id = fot.Business_Central_id__c;
            wrapper.Status_task = fot.Status_task__c;
            wrapper.Disabled = wrapper.Status_task == 'Open' ? false : true;
            dtwToReturn.add(wrapper);
        }
        return dtwToReturn;
    }

    public class DossierTaskWrapper{
		@AuraEnabled public String Name;
		@AuraEnabled public Date Deadline_date;
		@AuraEnabled public String Business_Central_id;
		@AuraEnabled public String Status_task;
        @AuraEnabled public Boolean Disabled;
	}
}