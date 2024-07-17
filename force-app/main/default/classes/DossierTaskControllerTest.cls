@istest
public class DossierTaskControllerTest {
    
    @istest
    public static void testGetDossierTasks(){
        Placement__c placement = TestDataFactory.getPlacement();
        insert placement;

        //TODO Do this in the TestDataFactory, but Vasco told me it was scary
        File_object_task__c fot = new File_object_task__c();
        fot.Name = 'test';
        fot.Status_task__c = 'Open';
        fot.Number__c = '1';
        fot.Related_to_placement__c = placement.Id;
        fot.Business_Central_id__c = 'testBCid';
        insert fot; 

        Test.startTest();
        List<DossierTaskController.DossierTaskWrapper> wrapper = DossierTaskController.getDossierTasks();
        Test.stopTest();

        Assert.areEqual(1, wrapper.size());
        Assert.areEqual(false, wrapper[0].Disabled);

    }
}