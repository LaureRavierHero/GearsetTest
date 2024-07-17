public class RatePercentageSelectorController {
  
    @AuraEnabled(cacheable=true)
    public static RatePercentageWrapper getRatePercentages(Id recordId){
        Placement__c placement = [SELECT Id, Account__c FROM Placement__c WHERE Id = :recordId];

        List<Placement_rate_percentage__c> placementRatePercentages = [SELECT Id, Name, Rate_Percentage__c, Rate_Percentage__r.Is_standard__c  
                                                                        FROM Placement_Rate_Percentage__c 
                                                                        WHERE Placement__c = :recordId];
        List<Rate_Percentage__c> ratePercentages = [SELECT Id, Name FROM Rate_Percentage__c WHERE Account__c = :placement.Account__c];
        
        RatePercentageWrapper wrapper = new RatePercentageWrapper();
        wrapper.selectedRatePercentageList = placementRatePercentages;
        wrapper.notSelectedRatePercentageList = ratePercentages;

        return wrapper;
    }

    @AuraEnabled
    public static string saveRatePercentages(List<String> ratePercentageIds, String recordId){
        List<Placement_rate_percentage__c> placementRatePercentages = [SELECT Id, Rate_percentage__c 
                                                                        FROM Placement_Rate_Percentage__c 
                                                                        WHERE Placement__c = :recordId];
        delete placementRatePercentages;

        Map<Id, Rate_percentage__c> ratePercentagesById = new Map<Id, Rate_percentage__c>([SELECT Id, Name, Account__c FROM Rate_percentage__c WHERE Id IN :ratePercentageIds]);

        List<Placement_rate_percentage__c> prpToInsert = new List<Placement_rate_percentage__c>();
        for(String ratePercentageId : ratePercentageIds){
            Placement_rate_percentage__c newPRP = new Placement_rate_percentage__c();
            newPRP.Name = ratePercentagesById.get(ratePercentageId).Name;
            newPRP.Placement__c = recordId;
            newPRP.Rate_percentage__c = ratePercentageId;
            prpToInsert.add(newPRP);
        }
        if(prpToInsert.size() > 0){
            insert prpToInsert;
        }
        return 'success';
    }
    public class RatePercentageWrapper{
        @AuraEnabled public List<Placement_rate_percentage__c> selectedRatePercentageList {get;set;}
        @AuraEnabled public List<Rate_Percentage__c> notSelectedRatePercentageList {get;set;}
    }
}