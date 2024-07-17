@istest
public class RatePercentageSelectorControllerTest {
   
    @istest
    public static void getRatePercentageTest(){
        Placement__c pl = TestDataFactory.getPlacementWithRatePercentage();

        Test.startTest();
        RatePercentageSelectorController.RatePercentageWrapper wrapper = RatePercentageSelectorController.getRatePercentages(pl.id);
        Test.stopTest();

        Assert.isNotNull(wrapper);
        Assert.areEqual(1, wrapper.selectedRatePercentageList.size());
        Assert.areEqual(1, wrapper.notSelectedRatePercentageList.size());

    }

    @istest
    public static void saveRatePercentageTest(){
        Placement__c pl = TestDataFactory.getPlacementWithRatePercentage();

        List<Rate_percentage__c> rps = [SELECT id FROM Rate_percentage__c];
        List<String> rpsIds = new List<String>();
        for(Rate_percentage__c rp : rps){
            rpsIds.add(rp.Id);
        }

        Test.startTest();
        String result = RatePercentageSelectorController.saveRatePercentages(rpsIds, pl.id);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(1, [SELECT Id FROM Placement_rate_percentage__c].size());
    }

    @istest
    public static void saveRatePercentageDeleteTest(){
        Placement__c pl = TestDataFactory.getPlacementWithRatePercentage();

        List<Rate_percentage__c> rps = [SELECT id FROM Rate_percentage__c];
        List<String> rpsIds = new List<String>();

        Test.startTest();
        String result = RatePercentageSelectorController.saveRatePercentages(rpsIds, pl.id);
        Test.stopTest();

        Assert.isNotNull(result);
        Assert.areEqual(0, [SELECT Id FROM Placement_rate_percentage__c].size());
    }
}