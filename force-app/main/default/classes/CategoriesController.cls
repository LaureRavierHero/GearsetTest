public with sharing class CategoriesController {
    class CategoryControllerException extends Exception {}
    public class CategoryInfo {
        @AuraEnabled public String label;
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean selected = false;

        CategoryInfo(Id i, String lbl, Boolean sel) {
            label = lbl;
            id = i;
            selected = sel;
        }
    }

    private static List<CategoryInfo>        getCategoryInfo(Map<Id, Category__c> categoriesById, Set<Id> selectedIds) {
        List<CategoryInfo> categoryInfo = new List<CategoryInfo>();

        for (Id catId: categoriesById.keySet()) {
            Boolean isSelected = selectedIds.contains(catId);
            Category__c cat = categoriesById.get(catId);

            categoryInfo.add(new CategoryInfo(cat.Id, cat.Name, isSelected));
        }

        return categoryInfo;
    }

    private static List<CategoryInfo>        getCategoryInfo(Map<Id, Category__c> categoriesById) {
        List<CategoryInfo> categoryInfo = new List<CategoryInfo>();

        for (Id catId: categoriesById.keySet()) {
            Category__c cat = categoriesById.get(catId);

            categoryInfo.add(new CategoryInfo(cat.Id, cat.Name, false));
        }

        return categoryInfo;
    }

    private static List<CategoryInfo>       getPositionCategories(String positionId) {
        Map<Id, Category__c> categoriesById =  new Map<Id, Category__c>([SELECT Name, Id FROM Category__c]);
        if (String.isNotBlank(positionId)) {
            List<Position_category__c> selectedCategories = [SELECT Category__c, Category__r.Name FROM Position_category__c	WHERE Position__c = :positionId];
            Set<Id> selectedCategoryIds = DeveloperUtils.getIdFieldSet(selectedCategories, 'Category__c');

            return CategoryInfo.getCategoryInfo(categoriesById, selectedCategoryIds);
        }
        else {
            return CategoryInfo.getCategoryInfo(categoriesById);
        }
    }

    private static List<CategoryInfo>       getVendorCategories(String vendorId) {
        Map<Id, Category__c> categoriesById =  new Map<Id, Category__c>([SELECT Name, Id FROM Category__c]);
        List<Vendor_contact_categories__c> selectedCategories = [SELECT Category__c, Category__r.Name FROM Vendor_contact_categories__c WHERE Vendor__c = :vendorId];
        Set<Id> selectedCategoryIds = DeveloperUtils.getIdFieldSet(selectedCategories, 'Category__c');

        return CategoryInfo.getCategoryInfo(categoriesById, selectedCategoryIds);
    }

    @AuraEnabled(cacheable=true)
    public static List<CategoryInfo>        getCategories(String recordId, String type) { // RecordId can be Vendor or Position id
        if (type == 'record') {
            if (String.isBlank(recordId)) {
                throw new CategoryControllerException('Error: component CategoryCombobox component is on record page but does not have recordId.');
            }
            else {
                String objectName = ((Id)recordId).getSobjectType().getDescribe().getName();
                if (objectName == 'Account') {
                    return getVendorCategories(recordId);
                }
                else if (objectName == 'Position__c') {
                    return getPositionCategories(recordId);
                }
                else {
                    throw new CategoryControllerException('CategoryCombobox component only works with records of type Vendor__c of Position__c, type given is ' + objectName);
                }
            }
        }
        else if (type == 'flow') {
            return getPositionCategories(recordId);
        }
        else {
            System.debug( LoggingLevel.WARN, 'We don\t recognize type ' + type);
            return new List<CategoryInfo>();
        }
    }

    @AuraEnabled
    public static void addCategories(Id recordId, List<Id> categoryIds) {
        // We only ever update from a component on a record page
        String objectName = SchemaUtils.getObjectNameByRecordId(recordId);

        if (objectName == 'Position__c') {
            List<Position_category__c> positionCategories = new List<Position_category__c>();
            for (Id id: categoryIds) {
                Position_category__c posCat = new Position_category__c();
                posCat.Position__c = recordId;
                posCat.Category__c = id;

                positionCategories.add(posCat);
            }

            insert positionCategories;
        }
        else if (objectName == 'Account') {
            List<Vendor_contact_categories__c> vendorCategories = new List<Vendor_contact_categories__c>();
            for (Id id: categoryIds) {
                Vendor_contact_categories__c vendCat = new Vendor_contact_categories__c();

                vendCat.Vendor__c = recordId;
                vendCat.Category__c = id;

                vendorCategories.add(vendCat);
            }
            insert vendorCategories;
        }
        else {
            throw new CategoryControllerException('Did not recognize record type of record with id: ' + recordId);
        }
    }

    @AuraEnabled
    public static void removeCategory(Id recordId, Id categoryId) {
        String objectName = ((Id)recordId).getSobjectType().getDescribe().getName();

        if (objectName == 'Position__c') {
            List<Position_category__c> categoryConnection = [SELECT Id, Position__c, Category__c FROM Position_category__c 
            WHERE (Position__c = :recordId AND Category__c = :categoryId)];

            delete categoryConnection;

        }
        else if (objectName == 'Account') {
            List<Vendor_contact_categories__c> categoryConnection = [SELECT Id, Vendor__c, Category__c FROM Vendor_contact_categories__c 
            WHERE (Vendor__c =: recordId AND Category__c = :categoryId)];

            delete categoryConnection;
        }
        else {
            throw new CategoryControllerException('Did not recognize record type of record with id: ' + recordId);
        }
    }
}