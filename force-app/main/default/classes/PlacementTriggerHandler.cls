public with sharing class PlacementTriggerHandler {
    private System.TriggerOperation triggerOperation;
	private List<Placement__c> newList;
	private List<Placement__c> oldList;
	private Map<Id, Placement__c> newMap;
	private Map<Id, Placement__c> oldMap;

    public PlacementTriggerHandler(System.TriggerOperation triggerOperation, List<Placement__c> newList, List<Placement__c> oldList, Map<Id, Placement__c> newMap, Map<Id, Placement__c> oldMap) {
        this.triggerOperation = triggerOperation;
		this.newList = newList;
		this.newMap = newMap;
		this.oldMap = oldMap;
		this.oldList = oldList;
    }

    public void execute() {
		switch on this.triggerOperation {
			when BEFORE_INSERT {
			}
			when AFTER_INSERT {
				checkSetStatusOnPosition(newList);
				relateStandardRatePercentages(newList);
			}
			when BEFORE_UPDATE{
				checkStatusActive(newMap, oldMap);
			}
			when AFTER_UPDATE {

			}
			when AFTER_DELETE {
			}
		}
    }

	public static void checkStatusActive(Map<Id, Placement__c> newMap, Map<Id, Placement__c> oldMap){
		for(Id placementId : newMap.keySet()){
			if(oldMap.get(placementId).Processing_Status__c != 'Active' 
			&& newMap.get(placementId).Sales_contract_status__c == 'Signed' 
			&& newMap.get(placementId).Purchase_contract_status__c == 'Signed'){
				newMap.get(placementId).Processing_Status__c = 'Active';
			}
		}
	}

	public static void relateStandardRatePercentages(List<Placement__c> placements){
		Set<Id> accountIds = new Set<Id>();

		for(Placement__c pl : placements){
			accountIds.add(pl.Account__c);
		}

		List<Rate_Percentage__c> standardRatePercentagesForAccount = [SELECT Id, Name, Account__c FROM Rate_percentage__c WHERE Account__c IN :accountIds AND Is_standard__c = true];
		Map<String, List<Rate_percentage__c>> ratePercentagesByAccount = new Map<String, List<Rate_percentage__c>>();

		for(Rate_Percentage__c rp : standardRatePercentagesForAccount){
			if(ratePercentagesByAccount.containsKey(rp.Account__c)){
				ratePercentagesByAccount.get(rp.Account__c).add(rp);
			}else{
				ratePercentagesByAccount.put(rp.Account__c, new List<Rate_percentage__c>{rp});
			}
		}
		System.debug(ratePercentagesByAccount);
        List<Placement_rate_percentage__c> prpToInsert = new List<Placement_rate_percentage__c>();
		for(Placement__c pl : placements){
			System.debug(pl.Id);
			System.debug(pl.Account__c);
			if(ratePercentagesByAccount.containsKey(pl.Account__c)){
				for(Rate_percentage__c rp : ratePercentagesByAccount.get(pl.Account__c)){
					System.debug(rp);
					Placement_rate_percentage__c newPRP = new Placement_rate_percentage__c();
					newPRP.Name = rp.Name;
					newPRP.Placement__c = pl.Id;
					newPRP.Rate_percentage__c = rp.Id;
					prpToInsert.add(newPRP);
					System.debug(prpToInsert);				}
			}
		}
		if(prpToInsert.size() > 0){
            insert prpToInsert;
        }
	}

	public static void checkSetStatusOnPosition(List<Placement__c> placements){
		Set<Id> posIds = new Set<Id>();
		for(Placement__c plac : placements){
			posIds.add(plac.Position__c);
		}

		Map<Id, Position__c> positionsById = new Map<Id, Position__c>([SELECT Id, Number_of_hires__c FROM Position__c WHERE Id IN :posIds]);

		List<Position__c> positionsToUpdate = new List<Position__c>();
		Map<Id, Integer> numberOfHiredByPositionId = new Map<Id, Integer>();

		for(Id id : positionsById.keySet()){
			Position__c pos = positionsById.get(id);
			if(Integer.valueOf(pos.Number_of_hires__c) == 1){
				pos.Processing_status__c = 'Placement';
				pos.Status__c = 'Hired';
				pos.Closed_reason__c = 'Hired';
				positionsToUpdate.add(pos);
			}else{
				numberOfHiredByPositionId.put(id, Integer.valueOf(pos.Number_of_hires__c));
			}
		}

		if(numberOfHiredByPositionId.size() > 0){
			AggregateResult[] countedPlacements = [SELECT Position__c, COUNT(Id) FROM Placement__c WHERE Position__c IN :numberOfHiredByPositionId.keySet() GROUP BY Position__c];
			for(AggregateResult ar : countedPlacements){
				if(numberOfHiredByPositionId.get(String.valueOf(ar.get('Position__c'))) == Integer.valueOf(ar.get('expr0'))){
					Position__c posToUpdate = new Position__c();
					posToUpdate.Id = String.valueOf(ar.get('Position__c'));
					posToUpdate.Processing_status__c = 'Placement';
					posToUpdate.Status__c = 'Hired';
					posToUpdate.Closed_reason__c = 'Hired';
					positionsToUpdate.add(posToUpdate);
				}
			}
		}

		update positionsToUpdate;
	}

	public static Map<Id, Id> getContactIds(Set<Id> recordIds){
		//TODO select account, the default hiring desk account, get the contact__c from that default hiring desk account, and put that in a map
		Map<Id, Placement__c> placementPerAccountId = new Map<Id, Placement__c>();
		Map<Id, Id> contactIdPerPlacementId = new Map<Id, Id>();
		
		// Get related account id's
		// Loop through them and fill the emails Set and placementPerAccountId Map
		Map<Id, Placement__c> placements = new Map<Id, Placement__c>([SELECT Id, Account__c, Account__r.Hiring_Desk_Email__c FROM Placement__c WHERE Id IN :recordIds]);
		for(Placement__c p : placements.values()){
			placementPerAccountId.put(p.Account__c, placements.get(p.Id));
		}

		List<Default_hiring_desk_contact__c> defaultContacts = [SELECT Account__c, Contact__c FROM Default_hiring_desk_contact__c WHERE Account__c IN :placementPerAccountId.keySet()];
		for(Default_hiring_desk_contact__c dc : defaultContacts){
			contactIdPerPlacementId.put(placementPerAccountId.get(dc.Account__c).Id, dc.Contact__c);
		}

		return contactIdPerPlacementId;
	}

	public class PlacementTriggerHandlerException extends Exception {}
}