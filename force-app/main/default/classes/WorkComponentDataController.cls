public class WorkComponentDataController {
    public class ObjectsData {
        public List<SObject>    objects;
        public Map<Id, Map<String, Id>> docIdsVersionIdsByFieldNameByObjId;

        ObjectsData(List<SObject> objs, Map<Id, Map<String, Id>> linkedDocsInfo) {
            objects = objs;
            docIdsVersionIdsByFieldNameByObjId = linkedDocsInfo;
        }
    }
    
    QueryBuilder.OrderClause order = null;
    Set<String> addFields = new Set<String>();
    List<QueryBuilder.FilterClause> filters {
        get {
            return filters;
        }
        set {
            // Add the fields we need to filter on to query
            for (QueryBuilder.FilterClause filter: value) {
                addFields.add(filter.fieldName);
            }

            filters = value;
        }
    }

    public WorkComponentDataController(QueryBuilder.OrderClause o) {
        order = o;
    }

    public WorkComponentDataController(List<QueryBuilder.FilterClause> f) {
        filters = f;
    }
    
    public WorkComponentDataController(List<QueryBuilder.FilterClause> f, 
    QueryBuilder.OrderClause o) {
        filters = f;
        order = o;
    }
    
    public WorkComponentDataController() {}

    private static List<ContentDocumentLink> getLinkedContentInfo(Set<Id> objectIds, String filterField, String filterPattern) {
        /* Get contentDocumentIds linked to candidate ids so we can get the versionIds
        with a later query (queries can't be nested unfortunately) */
        List<QueryBuilder.FilterClause> fcs = new List<QueryBuilder.FilterClause>();
        fcs.add(new QueryBuilder.StringFilterClause('LinkedEntityId', 
        DeveloperUtils.convertToStringSet(objectIds)));
        if (String.isNotBlank(filterField) && String.isNotBlank(filterPattern)) {
            fcs.add(new QueryBuilder.LikeFilterClause(filterField, filterPattern));
        }
        // QueryBuilder.FilterClause fc_pattern = new QueryBuilder.LikeFilterClause(filterField, filterPattern);
        QueryBuilder qb = new QueryBuilder(
            new Set<String>{ 'LinkedEntityId', 'ContentDocument.LatestPublishedVersionId', 'ContentDocumentId' }, //'ContentDocumentId', 
            'ContentDocumentLink',
            fcs
        );

        return Database.query(qb.toString());
    }

    // private static List<ContentDocument> getContentDocuments(Set<Id> documentIds) {
    //     QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', 
    //     DeveloperUtils.convertToStringSet(documentIds));
    //     QueryBuilder qb = new QueryBuilder(
    //         new Set<String>{ 'LatestPublishedVersionId' },
    //         'ContentDocument',
    //         new List<QueryBuilder.FilterClause>{fc}
    //     );
        
    //     return Database.query(qb.toString());
    // }

    public static Map<Id, Map<String, Id>>   getDocumentIdVersionIdByObjectId(List<ContentDocumentLink> documentLinks, 
    WorkcomponentSettingsController.DocumentColumn docCol) { //,     List<ContentDocument> contentDocs
        Map<Id, Map<String, Id>> versionIdByObjectId = new Map<Id, Map<String, Id>>();
        // Map<Id, Id> documentIdByObjectId = DeveloperUtils.mapIdToIdField(
        //     documentLinks, 
        //     'LinkedEntityId', 
        //     'ContentDocumentId');
        // Map<Id, Id> versionIdByDocumentId = DeveloperUtils.mapIdToIdField(
        //     contentDocs, 
        //     'Id', 
        //     'LatestPublishedVersionId');
        // for (Id key: documentIdByObjectId.keySet()) {
        //     versionIdByObjectId.put(key, versionIdByDocumentId.get(documentIdByObjectId.get(key)));
        // }
        // System.debug('dodument versions: ' + versionIdByDocumentId.values());
        for (ContentDocumentLink link: documentLinks) {
            versionIdByObjectId.put(link.LinkedEntityId, new Map<String, Id>()); //.LatestPublishedVersionId
            // Iterate through all columns here dynamically
            versionIdByObjectId.get(link.LinkedEntityId).put(docCol.idFieldName, link.ContentDocument.LatestPublishedVersionId); // , contentDocs
            versionIdByObjectId.get(link.LinkedEntityId).put(docCol.versionFieldName, link.ContentDocumentId);
        }
        return versionIdByObjectId;
    }

    public static Map<Id, Map<String, Id>> getDocumentAndVersionIdByRecordId(List<WorkcomponentSettingsController.DocumentColumn> documentColumns, 
    Set<Id> objectIds) {
        // Get document links where linkedEntityId in objectIds and filter matches
        if (documentColumns == null) {
            return null;
        }
        Map<Id, Map<String, Id>> res = new Map<Id, Map<String, Id>>();
        for (WorkcomponentSettingsController.DocumentColumn docCol: documentColumns) {
            List<ContentDocumentLink> documentLinks = getLinkedContentInfo(objectIds, docCol.filterOnField, 
            docCol.filterPattern);
            // Link objectId and latestVersionId
            if (documentLinks != null &&  documentLinks.size() != 0) {
                // Set<Id> documentIds = DeveloperUtils.getIdFieldSet(documentLinks, 'ContentDocumentId');
                // List<ContentDocument> contentDocs = getContentDocuments(documentIds);
                res = getDocumentIdVersionIdByObjectId(documentLinks, docCol);
            }
        }

        // Map<Id, Map<String, List<Id>>> res = new Map<Id, Map<String, List<Id>>>();
        // for (Id objId: objectIds) {
        //     res.put(objId, new Map<String, Map<String, Id>>());
        //     for (String colName: tmp.keySet()) {
        //         List<Id> docVersionId = tmp.get(colName)?.get(objId);
        //         if (docVersionId != null) {
        //             res.get(objId).put(colName, docVersionId);
        //         }
        //     }
        // }
        return res;
    }

    private List<SObject>    getObjects(WorkcomponentSettingsController.ComponentConfiguration componentSettings) {
        Set<String> allQueryFields = componentSettings.getQueryFieldsApi();
        // Add all fields we need for filtering to data

        System.debug('allQueryFields: ' + allQueryFields);
        QueryBuilder qb = new QueryBuilder(allQueryFields, componentSettings.objectApiName);
        if (filters != null) {
            qb.setFilterClauses(filters);
        }
        if (order != null) {
            qb.addOrderClause(order);
        }

        System.debug('QUERY OBJECTS: ' + qb.toString());
        return Database.query(qb.toString());
    }

    private void    addDefaultEditableColumn(List<Map<String, Object>> parsedData, Boolean isEditable) {
        for (Map<String, Object> row: parsedData) {
            row.put(WorkcomponentSettingsController.STANDARD_EDITABLE_COL_NAME, isEditable);
        }
    }

    private List<Map<String, Object>>  parseData(List<SObject> objects, Map<Id, Map<String, Id>> linkedDocuments, String dataWeaveMapName) {
        /* Flatten application data so we can map keys like Vendor__r.Name */
        DataWeave.Script script = new DataWeaveScriptResource.flattenJson();
        DataWeave.Result flattenedApplication = script.execute(
            new Map<String, Object>{'payload' => JSON.serialize(objects)});
            
        /* Map object keys to wrapper keys */
        Dataweave_mapping__mdt mapping = [SELECT Id, DeveloperName FROM Dataweave_mapping__mdt WHERE DeveloperName = :dataWeaveMapName LIMIT 1];

        TranslateJsonToObjects translator = new TranslateJsonToObjects(flattenedApplication.getValueAsString(), mapping);
        String applicationsJson = translator.translate();

        /* Add documents to JSON where recordId matches */
        DataWeave.Script script2 = new DataWeaveScriptResource.combineObjectsAndDocuments();
        DataWeave.Result result = script2.execute(
            new Map<String, Object>{'documents' => JSON.serialize(linkedDocuments), 'objects' => applicationsJson});

        /* Parse to objects */
        List<Object> objs = (List<Object>)JSON.deserializeUntyped(result.getValueAsString());
        List<Map<String, Object>> parsedData = new List<Map<String, Object>>();

        for (Object o: objs) {
            parsedData.add((Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(o)));
        }
        
        return parsedData;
    }

    public List<Map<String, Object>>   getData(WorkcomponentSettingsController.ComponentConfiguration componentSettings, String dataWeaveMapName) {
        if (componentSettings == null) {
            return null;
        }
        List<SObject> objects = getObjects(componentSettings);
        if (objects == null || objects.size() == 0) {
            return null;
        }
        Set<Id> objectIds = DeveloperUtils.getIdFieldSet(objects, 'Id');
        Map<Id, Map<String, Id>> linkedDocuments = getDocumentAndVersionIdByRecordId(componentSettings.documentColumns, 
        objectIds);
        
        List<Map<String, Object>> parsedData = parseData(objects, linkedDocuments, dataWeaveMapName);

        if (String.isBlank(componentSettings.rowEditableAPIFieldName)) {
            addDefaultEditableColumn(parsedData, componentSettings.editableComponent);
        }
      
        return parsedData;
    }
}