public without sharing class VendorPositionApplicationTriggerHandler {
    private System.TriggerOperation triggerOperation;
	private List<Vendor_position_application__c> newList;
	private List<Vendor_position_application__c> oldList;
	private Map<Id, Vendor_position_application__c> newMap;
	private Map<Id, Vendor_position_application__c> oldMap;
    
    public VendorPositionApplicationTriggerHandler(System.TriggerOperation triggerOperation, List<Vendor_position_application__c> newList, List<Vendor_position_application__c> oldList, Map<Id, Vendor_position_application__c> newMap, Map<Id, Vendor_position_application__c> oldMap) {
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
                sharePositionWithVendors(this.newList);
			}
			when BEFORE_UPDATE{
			}
			when AFTER_UPDATE {
			}
			when AFTER_DELETE {
			}
		}
    }

    public static void sharePositionWithVendors(List<Vendor_position_application__c> newList) {
        if (newList.size() > 0) {
            Id positionId = newList[0].Position__c;
            List<Id> vendorIds = new List<Id>();

			// Get ids of vendors
            for (Vendor_position_application__c vpa: newList) {
				if (!String.isBlank(vpa.Vendor__c)) {
					vendorIds.add(vpa.Vendor__c);
				}
            }

			// Get ids of users associated with default vendor contacts
			List<User> vendorUsers = [SELECT Id FROM User WHERE ContactId IN (
				SELECT Contact__c FROM Default_vendor_contact__c WHERE Vendor__c IN :vendorIds)];

			List<Id> userIds = new List<Id>(DeveloperUtils.getIdFieldSet(vendorUsers, 'Id'));

            PositionSharingHandler.shareRecordWithVendors(positionId, userIds);
        }
    }
}