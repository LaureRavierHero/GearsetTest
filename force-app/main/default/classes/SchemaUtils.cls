public without sharing class SchemaUtils {
    public class SchemaUtilsException extends Exception{}

    public static Id getUserFromContactId(Id cId) {
        List<User> users = [SELECT Id FROM User WHERE ContactId = :cId];

        if (users == null || users.size() == 0) {
            throw new SchemaUtilsException('No user associated with contact ' + cId);
        }
        if (users.size() > 1) {
            throw new SchemaUtilsException('Multiple users associated with contact ' + cId);
        }
        return users[0].Id;
    }

    public static Id getQueueIdFromName(String name) {
        return [SELECT Id FROM Group WHERE Type = 'queue' AND Name = :name LIMIT 1].Id;
    }

    public static Id getPermissionSetId(String permissionSetApiName) {
        return [SELECT Id FROM PermissionSet WHERE Name = :permissionSetApiName LIMIT 1].Id;
    }

    private static List<GroupMember> getGroupMembers(Set<Id> lastFoundMemberIds) {
        return [
            SELECT GroupId, Group.Name, Group.Type
            FROM GroupMember 
            WHERE UserOrGroupId 
            IN :lastFoundMemberIds 
            AND (Group.Type = 'Regular' OR Group.Type = 'Queue')];
    }

    /* Fetches the "regular" groups a user is part of, so only queue and regular and role. */
    public static Set<Id> getGroupsUserIsPartOf(Id userId) {
        Set<Id> roleGroupIds = new Set<Id>();

        // Get user role id
        User u = [SELECT UserRoleId FROM User WHERE Id = :userId LIMIT 1];

        if (!String.isBlank(u.UserRoleId)) {
            // Get group(s) that correspond with role (group type='Role')
            List<group> roleGroups = [SELECT Id FROM Group WHERE RelatedId = :u.UserRoleId];
            roleGroupIds.addAll(DeveloperUtils.getIdFieldSet(roleGroups, 'Id'));
        }

        Set<Id> allGroupIds = new Set<Id>();

        Set<Id> lastFoundMemberIds = new Set<Id>();
        lastFoundMemberIds.addAll(roleGroupIds);
        lastFoundMemberIds.add(userId);

        while (lastFoundMemberIds.size() != 0) {
            List<GroupMember> members = getGroupMembers(lastFoundMemberIds);

            allGroupIds.addAll(lastFoundMemberIds);
            lastFoundMemberIds.clear();

            if (members != null && members.size() != 0) {
                Set<Id> newGroupIds = DeveloperUtils.getIdFieldSet(members, 'GroupId');
                lastFoundMemberIds.addAll(newGroupIds);
                lastFoundMemberIds.removeAll(allGroupIds);
            }
        }

        allGroupIds.remove(userId);
        return allGroupIds;
    }

    public static Set<Id> filterGroupsByUserMemberShip(Id userId, Set<Id> consideredGroupIds) {
        Set<Id> userGroupIds = getGroupsUserIsPartOf(userId);
        Set<Id> commonIds = new Set<Id>();

        for (Id consideredId: consideredGroupIds) {
            if (userGroupIds.contains(consideredId)) {
                commonIds.add(consideredId);
            }
        }

        return commonIds;
    }

    // public static Set<Id> isUserPartOfGroups(String userId, Set<Id> groupIds){
    //     Map<Id, GroupMember> userSpecificGroupMembers = new Map<Id, GroupMember>([SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :userId AND GroupId IN :groupIds]);
    //     if(userSpecificGroupMembers.size() > 0){
    //         return groupIds;
    //     }

    //     Map<Id, GroupMember> allMembersUnderGroupIds = new Map<Id, GroupMember>([SELECT Id, GroupId FROM GroupMember WHERE GroupId IN :groupIds]);
    //     Map<Id, GroupMember> lastFoundGroupMembers = new Map<Id, GroupMember>();
    //     lastFoundGroupMembers.putAll(allMembersUnderGroupIds);
    //     Integer i = 0;
    //     while(i < 4){
    //         Map<id, GroupMember> memberUnderCurrentFoundGroups = new Map<Id, GroupMember>([SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :lastFoundGroupMembers.keySet()]);
    //         if(memberUnderCurrentFoundGroups.size() == null){
    //             break;
    //         }

    //         allMembersUnderGroupIds.putAll(memberUnderCurrentFoundGroups);

    //         lastFoundGroupMembers.clear();
    //         lastFoundGroupMembers.putAll(memberUnderCurrentFoundGroups);

    //     }

    //     for(Groupmember member : allMembersUnderGroupIds.values()){
    //         groupIds.add(member.GroupId);
    //         if(member.UserOrGroupId == userId){
    //             return groupIds;
    //         }
    //     }

    //     return null;
    // }

    public static String getObjectNameByRecordId(Id recordId) {
        return recordId.getSobjectType().getDescribe().getName();
    }

    @AuraEnabled
    public static Schema.DisplayType        getFieldType(String objectName, String fieldName) {
        Schema.DescribeSObjectResult objectDescribe = getObjectDescription(objectName);

        Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
        Schema.SObjectField field = fieldsMap.get(fieldName);

        if (field != null) {
            return field.getDescribe().getType();
        }
        return null;
    }
    
    /* Dynamically query for object description */
    private static Schema.DescribeSObjectResult    getObjectDescription(String objectName) {
        try  {
            Schema.DescribeSObjectResult[] objectDescriptions = Schema.describeSObjects(new List<String>{objectName});
            return objectDescriptions[0];
        }
        catch (System.InvalidParameterValueException e) {
            throw new SchemaUtilsException('Could not find object ' + objectName);
        }
    }

    public static Id getRecordTypeId(String objectName, String typeName) {
        Schema.DescribeSObjectResult descr = getObjectDescription(objectName);
        Schema.RecordTypeInfo recordTypeInfo = descr.getRecordTypeInfosByName().get(typeName);

        if (recordTypeInfo == null) {
            throw new SchemaUtilsException('Record type ' + typeName + ' on ' + objectName + ' not found!');
        }
        
        return recordTypeInfo.getRecordTypeId();
    }

    public static String getRecordTypeName(String objectName, Id typeId) {
        Schema.DescribeSObjectResult descr = getObjectDescription(objectName);
        Schema.RecordTypeInfo recordTypeInfo = descr.getRecordTypeInfosById().get(typeId);

        if (recordTypeInfo == null) {
            throw new SchemaUtilsException('Record type id ' + typeId + ' on ' + objectName + ' not found!');
        }
        
        return recordTypeInfo.getName();
    }

    public class PicklistItem {
        @AuraEnabled
        public String itemName;
        @AuraEnabled
        public String itemLabel;

        PicklistItem(String name, String label) {
            itemLabel = label;
            itemName = name;
        }
    }
    
    public static List<PicklistItem>        getPicklistOptions(String objectName, String fieldName) {
        List<PicklistItem> values = new List<PicklistItem>();
        Schema.DescribeSObjectResult objDescr = getObjectDescription(objectName);
        Schema.SObjectField field = objDescr.fields.getMap().get(fieldName);
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

        List<Schema.PicklistEntry> ple = fieldDescribe.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            values.add(New PicklistItem(pickListVal.getValue(), pickListVal.getLabel()));
        }
        return values;
    }

    private static Set<String> getFieldNames (
        Map<String, Map<String, String>> dependencyMap, 
        Map<String, Set<String>> fieldsByObjectName,
        List<String> order,
        String rootObjectName) {
        Map<String, Set<String>> res = new Map<String, Set<String>>();
        
        Integer counter = 0;
        /* We start by adding all fields that are at the end of paths to the result set
        Ex: if we have a final path Position__r.Account__r.Owner.Id, we add { User => (Id)} 
        to the map*/
        for (Integer i = 0; i < order.size(); ++i) {
            Map<String, String> objectByFieldName = dependencyMap.get(order[i]);

            if (objectByFieldName.keySet().size() != 0) {
                counter = i;
                break;
            }
            res.put(order[i], fieldsByObjectName.get(order[i]));
        }
        /* Now we start building composite strings starting with the 
        objects that have the least long paths and whose composite parts are
        alread in the result set.
        
        Ex: 
        final path: Position__r.Account__r.Owner.Id
        
        { User => (Id, Name)} is already in the result set, so now we move on to 
        adding the relationhip fields on account to the result set. 

        Account has a relationship Owner to User, so in the result set we add 
        Account__r.Owner.Id and Account__r.Owner.Name, as well as all "regular" 
        fields on Account.

        We keep doing this until we end up witg complete fields on the starting object,
        aka: Position__r.Account__r.Owner.Id on Application__c for example.
        */
        for (Integer i = counter; i < order.size(); ++i) {
            String objectName = order[i];
            Set<String> fields = new Set<String>(fieldsByObjectName.get(objectName));
            res.put(objectName, fields);

            Set<String> relationships = dependencyMap.get(objectName).keySet();
            for (String relation: relationships) {
                Set<String> fieldsOnRelation = res.get(dependencyMap.get(objectName).get(relation));
                for (String field: fieldsOnRelation) {
                    res.get(objectName).add(relation + '.' + field);
                }
            }
        }

        DeveloperUtils.printMap(res);
        return res.get(rootObjectName);
    }

    private static Set<String>  extractFullPathsFromBaseObject(Map<String, Map<String, String>> dependencyMap,
    Map<String, Set<String>> fieldsByObjectName, String rootObjectName) {
        DataDependencyModeller dependencyModel = DataDependencyModeller.createDependencyGraph(dependencyMap);
        List<String> topographicalSortOrder = DataDependencyModeller.getTopographicalSortOrder(dependencyMap, dependencyModel);
        Set<String> fieldNames = getFieldNames(dependencyMap, fieldsByObjectName, topographicalSortOrder, rootObjectName);
        return fieldNames;
    }

    private static String handleDependenciesAndStackInner(String curr, Schema.DescribeFieldResult fieldDescription,
    Map<String, Map<String, String>> dependencyMap) {
        if (fieldDescription.isNamePointing()) {
            // I have not handled fields that can have multiple parent types (WHOID etc)
            System.debug(LoggingLevel.WARN, 'getExpandedObjectDescription: fields where isNamePointing is true are not handled. ' 
            + 'Results may be incomplete [' + fieldDescription.getName() + ']');
        }
        String otherObjectName = fieldDescription.getReferenceTo()[0].getDescribe().getName();
        String relationshipName = fieldDescription.getRelationshipName();
        
        /* Exclude self-references */
        if (otherObjectName != curr) {
            dependencyMap.get(curr).put(relationshipName, otherObjectName);
            // stack.add(otherObjectName);
            return otherObjectName;
        }
        else {
            System.debug('Excluding self reference: ' + otherObjectName + ' ' + curr);
            return null;
        }
    }

    private static String handleDependenciesAndStack(String curr, Schema.DescribeFieldResult fieldDescription,
    Map<String, List<String>> relationshipsToExpandByObject, Map<String, Map<String, String>> dependencyMap) {
        /* If a relationship needs expanding we add the related object to the stack and save the relationship info */
        if (relationshipsToExpandByObject.get(curr) != null && 
        relationshipsToExpandByObject.get(curr).contains(fieldDescription.getRelationshipName())) {
            return handleDependenciesAndStackInner(curr, fieldDescription, dependencyMap);
        }
        return null;
    }

    private static String handleDependenciesAndStack(String curr, Schema.DescribeFieldResult fieldDescription,
    Map<String, Map<String, String>> dependencyMap) {
        return handleDependenciesAndStackInner(curr, fieldDescription, dependencyMap);
    }

    private enum FunctionType {
        ALL_FIELDS,
        FIELDS_BY_REL
    }

    class Settings {
        String objectName {get; set;}
        Map<String, List<String>> relationshipsToExpandByObject {get; set;}
        Set<String> relatedObjects {get; set;}
        FunctionType type {get; set;}
    }

    private static Set<String> getFieldsAndRelatedObjectFields(Settings settings) {
        List<String> stack = new List<String>();
        Set<String> visited = new Set<String>();
        Map<String, Map<String, String>> dependencyMap = new Map<String, Map<String, String>>(); // Holds related objects by relationship name by name of object that has a lookup to afformentioned object
        Map<String, Set<String>> fieldsByObjectName = new Map<String, Set<String>>();

        String curr;
        Schema.DescribeSObjectResult objectDescription;
        List<SObjectField> fields;
        String otherObjectName; // Named of object relationship points to
        String relationshipName;

        stack.add(settings.objectName);
        while (stack.size() != 0) {
            curr = stack.get(stack.size() - 1);
            stack.remove(stack.size() - 1);

            if (!visited.contains(curr)) {
                dependencyMap.put(curr, new Map<String, String>());
                fieldsByObjectName.put(curr, new Set<String>());
                visited.add(curr);

                objectDescription = getObjectDescription(curr);
                fields = objectDescription.fields.getMap().values();

                for (SObjectField field: fields) {
                    /* We add all non-lookup field names to the map regardless */
                    Schema.DescribeFieldResult fieldDescription = field.getDescribe();
                    fieldsByObjectName.get(curr).add(fieldDescription.getName());

                    /* If we encounter a relationship field */
                    if (fieldDescription.getType() == Schema.DisplayType.Reference) {
                        /* When to add objects to the stack depends on which function the user called. 
                        See comments above getAllFieldNames functions for clarification. */
                        String stackAddition = null;
                        switch on settings.type {
                            when FIELDS_BY_REL {
                                stackAddition = handleDependenciesAndStack(curr, fieldDescription, settings.relationshipsToExpandByObject, dependencyMap);
                                
                            }
                            when ALL_FIELDS {
                                stackAddition = handleDependenciesAndStack(curr, fieldDescription, dependencyMap);
                            }
                        }
                        if (String.isNotBlank(stackAddition)) {
                            stack.add(stackAddition);
                        }
                    }
                }
            }
        }

        return extractFullPathsFromBaseObject(dependencyMap, fieldsByObjectName, settings.objectName);
    }

    /* Equivalent to SQL SELECT * FROM [TABLE] */
    public static Set<String> wildcardSelector(String objectName) {
        Schema.DescribeSObjectResult objectDescription = getObjectDescription(objectName);
        List<SObjectField> fields = objectDescription.fields.getMap().values();
        Set<String> fieldNames = new Set<String>();

        for (SObjectField field: fields) {
            Schema.DescribeFieldResult fieldDescription = field.getDescribe();
            if (fieldDescription.getType() != Schema.DisplayType.Reference) {
                fieldNames.add(fieldDescription.getName());
            }
        }

        return fieldNames;
    }

    /* Takes a map containing object names and the relationships to expand on them
    Ex: 
    Position__c => ('Account__r', 'Vendor__r'),
    Vendor__c => ('Contact__r')
    Application__c => ('Position__r', 'Hiring_manager__r')

    If application is the root (objectName)
    Will return something along the lines of:
    (
        Position__c,
        Position__r.Account__r.Name
        Position__r.Vendor__r.Name
        Position__r.Vendor__r.Contact__r.Name
        Hiring_manager__r.Id
        
        etc
    )
    */
    public static Set<String> getAllFieldNames(String objectName, Map<String, List<String>> relationshipsToExpandByObject) {
        Settings s = new Settings();
        s.objectName = objectName;
        s.relationshipsToExpandByObject = relationshipsToExpandByObject;
        s.type = FunctionType.FIELDS_BY_REL;
        return getFieldsAndRelatedObjectFields(s);
    }

    /* Takes the name of the root object and all relationships to expand on it. Like above 
    only will traverse only one layer deep */
    public static Set<String> getAllFieldNames(String objectName, List<String> relationshipsToExpand) {
        Settings s = new Settings();
        s.objectName = objectName;
        s.relationshipsToExpandByObject = new Map<String, List<String>>{objectName => relationshipsToExpand};
        s.type = FunctionType.FIELDS_BY_REL;

        return getFieldsAndRelatedObjectFields(s);
    }

    /* Takes an object name and will attempt to expand the entire tree of objects from it.
    Use this with caution because cycles or heap usage may become an issue.
    Best suited for metadata/settings etc */
    public static Set<String> getAllFieldNames(String objectName) {
        Settings s = new Settings();
        s.objectName = objectName;
        s.type = FunctionType.ALL_FIELDS;
        return getFieldsAndRelatedObjectFields(s);
    }

    public static Id getGroupByName(String name) {
        List<Group> grp = [SELECT Id FROM Group WHERE Name = :name];

        if (grp == null || grp.size() == 0) {
            throw new SchemaUtilsException('Could not find group with name: ' + name);
        }
        else if (grp.size() > 1) {
            throw new SchemaUtilsException('Found multiple groups with name: ' + name);
        }

        return grp[0].Id;
    }
}