public class SampleDataCreator {
    class SampleDataCreatorException extends Exception {
    }

    public static Map<String, List<SObject>>    parseData(String jsonString) {
        Map<String, Object>             partialDeserialized = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        Map<String, List<SObject>>      sampleData = new Map<String, List<SObject>>();
        for (String key: partialDeserialized.keySet()) {
            // Create list of specific objects from generic object
            String partialJsonString = JSON.serialize(partialDeserialized.get(key));
            if (System.Type.forName('List<' + key + '>') == null) {
                throw new SampleDataCreatorException('Not a valid object name: ' + key);
            }
            List<SObject> objs = (List<SObject>)(JSON.deserialize(partialJsonString, System.Type.forName('List<' + key + '>' )));
            sampleData.put(key, objs);
        }
        return sampleData;
    }

    public static Map<String, Map<String, String>>        mapDependenciesByField(Map<String, List<SObject>> sampleData) {
        /* Returns the name of the object a field depends on for all fields in an object by that object's name */
        List<Schema.DescribeSObjectResult> descriptions = Schema.describeSObjects(new List<String>(sampleData.keySet()));
        Map<String, Map<String, String>>    dependenciesByField = new Map<String, Map<String, String>>();
        for (Schema.DescribeSObjectResult description: descriptions) {
            Map<String, String>     relationTypeByField = new Map<string, String>();
            Map<String, SObjectField>           fields = description.fields.getMap();
            for (SObjectField f: fields.values()) {
                DescribeFieldResult df = f.getDescribe();
                if (df.getType() == Schema.DisplayType.Reference 
                && (df.isCustom() || (description.getName() == 'Contact' && df.getName() == 'AccountId'))
                && (sampleData.keySet().contains(df.getReferenceTo()[0].getDescribe().getName()))
                && (df.getReferenceTo()[0].getDescribe().getName() != description.getName())) {
                    // Ignore self-references
                    relationTypeByField.put(df.getName(), df.getReferenceTo()[0].getDescribe().getName());
                }
            }
            dependenciesByField.put(description.getName(), relationTypeByField);
        }
        return dependenciesByField;
    }

    

    /* Topographical sorting algorithm. Sorts objectNames so that all parents are
        inserted before all their children. Will break on circular dependencies. */
    // public static List<String>     getInsertionOrder(Map<String, Map<String, String>> fieldDependencies,
    // DataDependencyModeller dependencies) {
    //     List<String>     nodes = new List<String>();
    //     List<String>    sortedResult = new List<String>();

    //     // Add all nodes without parents to list
    //     for (String objName: fieldDependencies.keySet()) {
    //         if (dependencies.parents.get(objName) == null || dependencies.parents.get(objName).size() == 0) {
    //             nodes.add(objName);
    //         }
    //     }

    //     while (nodes.size() > 0) {
    //         // Remove current node from nodes to sort and add to sorted
    //         String node = nodes[0];
    //         nodes.remove(0);

    //         sortedResult.add(node);
    //         Set<String> nodeChildren =  dependencies.children.get(node);
    //         // For all children of node that was just sorted, if they have no other parent dependencies, add them to list for sort
    //         if (nodeChildren != null) {
    //             for (String child: nodeChildren) {
    //                 dependencies.parents.get(child).remove(node);
    //                 if (dependencies.parents.get(child) == null || dependencies.parents.get(child).size() == 0) {
    //                     nodes.add(child);
    //                 }
    //             }
    //         }
    //     }
    //     return sortedResult;
    // }

    public static void              resolveDependentFields(Map<String, Map<String, Id>> idToNameMappingByObjectName,
    Map<String, Map<String, String>> fieldDependencies, 
    Map<String, List<SObject>> sampleData, String objName) {
        /* Function updates lookup and master-detail fields. We assume the 'Name' field of the parent object
        was specified in the sample data. Here, we replace it with an Id */
        if (fieldDependencies.get(objName) != null && fieldDependencies.get(objName).size() != 0) {
            for (String fieldName: fieldDependencies.get(objName).keySet()) {
                // Replace lookup field names with corresponding Ids
                for (SObject obj: sampleData.get(objName)) {
                    String oldVal = (String)obj.get(fieldName);
                    String depObjName = fieldDependencies.get(objName).get(fieldName);
                    String newVal = idToNameMappingByObjectName.get(depObjName).get(oldVal);
                    obj.put(fieldName, newVal);
                }
            }
        }
    }

    public static void              updateIdToNameMapping(Map<String, Map<String, Id>> idToNameMappingByObjectName, 
    Map<String, List<SObject>> sampleData, 
    String objName) {
        /* Function makes sure that during insertion, for all parent objects, we keep a mapping from 
        the record name to the record Id. This is used in 'resolveDependentFields' to add Ids to 
        relationship fields. */
        Set<String>     objectNames = new Set<String>();
        for (SObject innerObj: sampleData.get(objName)) {
            objectNames.add((String)innerObj.get('Name'));
        }
        String queryString = 'SELECT Id, Name FROM ' + objName + ' WHERE Name IN :objectNames';
        List<SObject> objs = Database.query(queryString);
        idToNameMappingByObjectName.put(objName, DeveloperUtils.mapIdToName(objs));
    }

    public static void             insertSampleData(Map<String, List<SObject>> sampleData, 
    Map<String, Map<String, String>> fieldDependencies,
    DataDependencyModeller dependencyGraph, 
    List<String> insertOrder) {
        Map<String, Map<String, Id>>    idToNameMappingByObjectName = new Map<String, Map<String, Id>>();
        for (String objName: insertOrder) {
            try {
                resolveDependentFields(idToNameMappingByObjectName, fieldDependencies, sampleData, objName);
                insert sampleData.get(objName);
                if (dependencyGraph.children.get(objName) != null && dependencyGraph.children.get(objName).size() != 0) {
                    updateIdToNameMapping(idToNameMappingByObjectName, sampleData, objName);
                }
            }
            catch (Exception e) {
                throw e;
            }
        }
    }

    public static void      createSampleData(String srName) {
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = :srName];

        try {
            Map<String, List<SObject>> sampleData = parseData(resource.Body.toString());
            Map<String, Map<String, String>> fieldDependencies = mapDependenciesByField(sampleData);
            DataDependencyModeller dependencyGraph = DataDependencyModeller.createDependencyGraph(fieldDependencies);
            List<String> insertOrder = DataDependencyModeller.getTopographicalSortOrder(fieldDependencies, dependencyGraph);

            insertSampleData(sampleData, fieldDependencies, dependencyGraph, insertOrder);
        }
        catch (Exception e) {
            throw e;
        }
    }

    public static void      deleteSampleData(String srName) {
        // Just selects by name, so be careful if using this!
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = :srName];
        List<SObject> allResults = new List<SObject>();

        try {
            Map<String, List<SObject>> sampleData = parseData(resource.Body.toString());
            Map<String, Map<String, String>> fieldDependencies = mapDependenciesByField(sampleData);
            DataDependencyModeller dependencyGraph = DataDependencyModeller.createDependencyGraph(fieldDependencies); 
            List<String> reverseDeleteOrder = DataDependencyModeller.getTopographicalSortOrder(fieldDependencies, dependencyGraph);
            
            for (Integer i = reverseDeleteOrder.size() - 1; i >= 0; --i) {
                String objName = reverseDeleteOrder[i];

                Set<String> names = new Set<String>();
                for (SObject obj: sampleData.get(objName)) {
                    names.add((String)obj.get('Name'));
                }
                String queryString = 'SELECT Name, Id FROM ' + objName + ' WHERE Name IN :names';
                allResults.addAll(Database.query(queryString));
            }

            Database.DeleteResult[] results = Database.delete(allResults, false);

            for (Database.DeleteResult res: results) {
                if (!res.isSuccess()) {
                    System.debug(LoggingLevel.WARN, res.getErrors());
                }
            }
        }
        catch (Exception e) {
            throw e;
        }
    }
}