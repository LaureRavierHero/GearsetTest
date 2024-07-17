trigger VendorPositionApplicationTrigger on Vendor_position_application__c (before insert, before update, after insert, after update) {
    VendorPositionApplicationTriggerHandler handler = new VendorPositionApplicationTriggerHandler(Trigger.operationType, Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    handler.execute();
}