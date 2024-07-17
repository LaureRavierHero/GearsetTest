public class DataDependencyModeller {
    public Map<String, Set<String>>           parents; 
    public Map<String, Set<String>>           children;

    public class DataDependencyModellerException extends Exception {}

    public DataDependencyModeller() {
        this.parents = new Map<String, Set<String>>();
        this.children = new Map<String, Set<String>>();
    }

    public void     addRelationship(String child, String parent) {
        /* Adds relationship between two objects to the list of
        children and parents for the objects involved respectively. */
        if (this.children.get(parent) == null)  {
            this.children.put(parent, new Set<String>());
        }
        this.children.get(parent).add(child);

        if (this.parents.get(child) == null)  {
            this.parents.put(child, new Set<String>());
        }
        this.parents.get(child).add(parent);
    }

    public static DataDependencyModeller      createDependencyGraph(Map<String, Map<String, String>> fieldDependencies) {
        /* Maps all relationships: adds parent names to child objects and child names
        to parent objects. */
        DataDependencyModeller dependencies = new DataDependencyModeller();

        for (String objName: fieldDependencies.keySet()) {
            Map<String, String> parentsByField = fieldDependencies.get(objName);
            for (String fieldName: fieldDependencies.get(objName).keySet()) {
                dependencies.addRelationship(objName, parentsByField.get(fieldName));
            }
        }
        return dependencies;
    }

    /* Topographical sorting algorithm. Sorts objectNames so that all parents are
    inserted before all their children. Will break on circular dependencies. */
    public static List<String>     getTopographicalSortOrder(Map<String, Map<String, String>> fieldDependencies,
    DataDependencyModeller dependencies) {
        List<String>     nodes = new List<String>();
        List<String>    sortedResult = new List<String>();

        System.debug('DEPS: ' + fieldDependencies.keySet().size());

        for (String key: fieldDependencies.keySet()) {
            System.debug(key);
            System.debug(fieldDependencies.get(key).keySet());
            // DeveloperUtils.printMap(fieldDependencies.get(key));
        }

        // Add all nodes without parents to list
        for (String objName: fieldDependencies.keySet()) {
            if (dependencies.parents.get(objName) == null || dependencies.parents.get(objName).size() == 0) {
                nodes.add(objName);
            }
        }

        while (nodes.size() > 0) {
            System.debug('Nodes ' + nodes);
            // Remove current node from nodes to sort and add to sorted
            String node = nodes[0];
            nodes.remove(0);

            sortedResult.add(node);
            Set<String> nodeChildren =  dependencies.children.get(node);
            // For all children of node that was just sorted, if they have no other parent dependencies, add them to list for sort
            if (nodeChildren != null) {
                for (String child: nodeChildren) {
                    dependencies.parents.get(child).remove(node);
                    if (dependencies.parents.get(child) == null || dependencies.parents.get(child).size() == 0) {
                        nodes.add(child);
                    }
                }
            }
        }

        System.debug(dependencies.parents.get('Application__c'));
        System.debug('SORTED RES ' + sortedResult.size());
        DeveloperUtils.printList(sortedResult);
        if (sortedResult.size() != fieldDependencies.keySet().size()) {
            throw new DataDependencyModellerException('Could not determine topological order because circular dependencies exist. Please adjust input.');
        }
        return sortedResult;
    }

    public static List<String>     getTopographicalSortOrder(Map<String, Map<String, String>> fieldDependencies) {
        DataDependencyModeller dependencies = createDependencyGraph(fieldDependencies);
        return getTopographicalSortOrder(fieldDependencies, dependencies);
    }
}