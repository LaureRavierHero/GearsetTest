public with sharing class WorkcomponentSettingsController {
    public static String STANDARD_EDITABLE_COL_NAME = 'STD_editable_col';

    public class FilterInfo {
        @AuraEnabled public String  columnName;
        @AuraEnabled public String  columnLabel;
        @AuraEnabled public Boolean multiselect;
        @AuraEnabled public String  displayType;

        public FilterInfo(String colName, String colLabel, Boolean multi, String display) {
            columnName = colName;
            columnLabel = colLabel;
            multiselect = multi;
            displayType = display;
        }
    }

    public class QueryField {
        @AuraEnabled public String   fieldName;
        @AuraEnabled public String   queryName;

        QueryField(String fn) {
            fieldName = fn;
            queryName = fn;
        }

        QueryField(String fn, String qfn) {
            fieldName = fn;
            queryName = qfn;
        }
    }

    public class        ComponentConfiguration {
        @AuraEnabled public String                  objectApiName; //Api_object_name__c
        @AuraEnabled public Boolean                 showPagination; //Show_pagination__c
        @AuraEnabled public String                  idColumn = 'Id';
        @AuraEnabled public List<Column>            columns { get; set; }
        @AuraEnabled public List<FilterInfo>        filters { get; set; }
        @AuraEnabled public List<QueryField>        queryFields { get; set; }
        @AuraEnabled public List<DocumentColumn>    documentColumns { get; set; }
        @AuraEnabled public Boolean                 editableComponent { get; set; }
        @AuraEnabled public String                  rowEditableAPIFieldName { get; set; }

        public Set<String>         getQueryFieldsApi() {
            Set<String> apiQueryFields = new Set<String>();

            for (QueryField field: queryFields) {
                apiQueryFields.add(field.queryName);
            }

            // if (String.isNotBlank(rowEditableAPIFieldName)) {
            //     apiQueryFields.add(rowEditableAPIFieldName);
            // }

            // System.debug('GET QUERY FIELDS: ' + apiQueryFields);
            return apiQueryFields;
        }

        public Set<String>         getFieldNames() {
            Set<String> fieldNames = new Set<String>();

            for (QueryField field: queryFields) {
                fieldNames.add(field.fieldName);
            }

            return fieldNames;
        }

        public ComponentConfiguration(Workcomponent_general_settings__mdt settings) {
            objectApiName = settings.Api_object_name__c;
            showPagination = settings.Show_pagination__c;
            rowEditableAPIFieldName = settings.Row_editable_API_field_name__c;
            // If dependent row editability is set, ignore component editability
            editableComponent = String.isBlank(rowEditableAPIFieldName) ? settings.Rows_editable__c : false;
        }
    }

    public class        Column {
        @AuraEnabled public String      label { get; set; }
        @AuraEnabled public Boolean     editable { get; set; }
        @AuraEnabled public Boolean     sortable { get; set; }
        @AuraEnabled public String      type { get; set; }
        @AuraEnabled public String      fieldName { get; set; }

        @AuraEnabled public List<WorkcomponentTypeAttributes.ColumnAction>      actions; // These are column actions (default are wrapping/clipping behaviour controls)
        @AuraEnabled public WorkcomponentTypeAttributes.CellAttributes          cellAttributes;
        @AuraEnabled public WorkcomponentTypeAttributes.TypeAttributes          typeAttributes { get; set; }

        /* Not in use */
        @AuraEnabled public Boolean     hideDefaultActions; // Whether or not users can control wrapping/clipping behaviour
        @AuraEnabled public Boolean     hideLabel { get; set; }
        @AuraEnabled public String      iconName { get; set; }
        @AuraEnabled public Boolean     wrapText { get; set; }
        @AuraEnabled public Integer     wrapTextMaxLines { get; set; }

        {
            editable = false;
            actions = null;
            cellAttributes = null;
            hideDefaultActions = true;
            hideLabel = false;
            iconName = '';
            typeAttributes = null;
            wrapText = false;
            wrapTextMaxLines = 2;
        }

        public Column(Column_component_account_connector__mdt columnSettings, 
        Column_settings__mdt attributeSettings, 
        Map<String, String> columnNamesByFieldNames,
        String objectName, String editableColumnName) {
            label = getLabel(columnSettings.Column_label__c);
            // editable = columnSettings.Editable__c;
            sortable = columnSettings.Sortable__c;
            if (columnSettings.Column_settings__c != null) {
                // Regular
                fieldName = columnNamesByFieldNames.get(attributeSettings.Api_field_name__c);
            }
            else if (columnSettings.Linked_document_column__c != null) {
                // Linked document
                fieldName = columnSettings.Linked_document_column__r.Field_name__c;
            }
            typeAttributes = getAttributes(columnSettings, attributeSettings, columnNamesByFieldNames, objectName, editableColumnName);
            if (columnSettings.Cell_attributes__c != null)
                cellAttributes = getCellAttributes(columnSettings);
        }

        public WorkcomponentTypeAttributes.CellAttributes   getCellAttributes(Column_component_account_connector__mdt colSettings) {
            // TODO: this is just a prototype
            WorkcomponentTypeAttributes.CellAttributes cellAttributes = new WorkcomponentTypeAttributes.CellAttributes();

            cellAttributes.alignment = colSettings.Cell_attributes__r.Alignment__c;
            return cellAttributes;
        }

        public WorkcomponentTypeAttributes.TypeAttributes   getAttributes(Column_component_account_connector__mdt columnSettings, 
        Column_settings__mdt attributeSettings, 
        Map<String, String> columnNamesByFieldNames,
        String objectName, 
        String editableColumnName) {
            type = attributeSettings.Type__c;

            WorkcomponentTypeAttributes.ConcreteTypeAttributesFactory attrFactory = 
                new WorkcomponentTypeAttributes.ConcreteTypeAttributesFactory();
            
            return attrFactory.getTypeAttributes(attributeSettings, 
                columnNamesByFieldNames, 'Id', objectName, editableColumnName);
        }
    }

    public static String     getLabel(String colLabel) {
        String label;
        try {
            label = System.Label.get('', colLabel, UserInfo.getLanguage());
        }
        catch (Exception e) {
            label = colLabel;
        }

        return label;
    }

    public static Workcomponent_general_settings__mdt   getComponentSettings(Id compSettingsId) {
        Set<String> fields = SchemaUtils.wildcardSelector('Workcomponent_general_settings__mdt');
        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id',
        new Set<String>{compSettingsId});
        QueryBuilder qb = new QueryBuilder(fields, 'Workcomponent_general_settings__mdt', new List<QueryBuilder.FilterClause>{fc});
        qb.setLimit(1);
        return Database.query(qb.toString());
    }

    @TestVisible
    private static List<Column_component_account_connector__mdt>          getComponentInfo(String componentName) {
        QueryBuilder.FilterClause fc_component =
            new QueryBuilder.StringFilterClause('Workcomponent_general_settings__r.Component_name__c', new Set<String>{componentName});
        QueryBuilder.FilterClause fc_account =
            new QueryBuilder.StringFilterClause('Account_name__c', new Set<String>{SessionConfiguration.accountName});
        QueryBuilder.FilterClause fc_active = 
        new QueryBuilder.BooleanFilterClause('Active__c', true);
        QueryBuilder.OrderClause oc = new QueryBuilder.OrderClause('Order__c');
        Set<String> fields = SchemaUtils.getAllFieldNames('Column_component_account_connector__mdt');

        QueryBuilder qb = new QueryBuilder(fields, 'Column_component_account_connector__mdt', 
        new List<QueryBuilder.FilterClause>{fc_component, fc_account, fc_active}, new List<QueryBuilder.OrderClause>{oc});

        return Database.query(qb.toString());
    }

    public static Map<Id, Linked_document_column__mdt> getLinkedDocumentColumns(Set<Id> documentColumnIds) {
        Set<String> fields = SchemaUtils.getAllFieldNames('Linked_document_column__mdt');
        QueryBuilder.FilterClause fc =
            new QueryBuilder.StringFilterClause('Id', DeveloperUtils.convertToStringSet(documentColumnIds));
        
        QueryBuilder qb = new QueryBuilder(fields, 'Linked_document_column__mdt', new List<QueryBuilder.FilterClause>{fc});
        List<Linked_document_column__mdt> res = Database.query(qb.toString());

        return new Map<Id, Linked_document_column__mdt>(res);
    }

    public static Map<Id, Column_settings__mdt> getAttributeSettings(Set<Id> columnSettingIds) {
        Set<String> fields = SchemaUtils.getAllFieldNames('Column_settings__mdt');
        QueryBuilder.FilterClause fc =
            new QueryBuilder.StringFilterClause('Id', DeveloperUtils.convertToStringSet(columnSettingIds));
        
        QueryBuilder qb = new QueryBuilder(fields, 'Column_settings__mdt', new List<QueryBuilder.FilterClause>{fc});
        List<Column_settings__mdt> res = Database.query(qb.toString());
        return new Map<Id, Column_settings__mdt>(res);
    }

    public static List<Filter_settings__mdt>    getFilterSettings(List<Column_component_account_connector__mdt> info) {
        Set<Id> filterSettingIds = DeveloperUtils.getIdFieldSet(info, 'Filter_settings__c');

        filterSettingIds.remove(null);
        if (filterSettingIds.size() == 0) {
            return null;
        }
        Set<String> fields = SchemaUtils.getAllFieldNames('Filter_settings__mdt');
        QueryBuilder.FilterClause fc =
            new QueryBuilder.StringFilterClause('Id', DeveloperUtils.convertToStringSet(filterSettingIds));
        
        QueryBuilder qb = new QueryBuilder(fields, 'Filter_settings__mdt', new List<QueryBuilder.FilterClause>{fc});
        return Database.query(qb.toString());
    }

    public static Map<Id, Column_settings__mdt> getAttributeSettingsByConnectorId(List<Column_component_account_connector__mdt> info,
    Map<Id, Column_settings__mdt> attributeSettings) {
        Map<Id, Column_settings__mdt> attributeSettingsByConnectorId = new Map<Id, Column_settings__mdt>();

        for (Column_component_account_connector__mdt conn: info) {
            Column_settings__mdt currAttr;
            if (conn.Linked_document_column__c != null && conn.Linked_document_column__r.Column_settings__c != null) {
                currAttr = attributeSettings.get(conn.Linked_document_column__r.Column_settings__c);
            }
            else if (conn.Column_settings__c != null) {
                currAttr = attributeSettings.get(conn.Column_settings__c);
            }

            attributeSettingsByConnectorId.put(conn.Id, currAttr);
        }

        return attributeSettingsByConnectorId;
    }

    public static List<Column>         getColumns(List<Column_component_account_connector__mdt> info,
    Map<Id, Column_settings__mdt> attributeSettings, Map<String, String> columnNameByFieldName,
    Workcomponent_general_settings__mdt componentSettings) {
        // Columns are made up of connector info and attribute settings
        Map<Id, Column_settings__mdt> attributeSettingsByConnectorId = 
            getAttributeSettingsByConnectorId(info, attributeSettings);
        String editableColumnName = (!String.isBlank(componentSettings.Row_editable_API_field_name__c))? columnNameByFieldName.get(componentSettings.Row_editable_API_field_name__c) : STANDARD_EDITABLE_COL_NAME;

        List<Column> columns = new List<Column>();
        for (Column_component_account_connector__mdt conn: info) {
            Column col = new Column(conn, attributeSettingsByConnectorId.get(conn.Id), 
            columnNameByFieldName, componentSettings.Api_object_name__c, 
            editableColumnName);

            columns.add(col);
        }

        return columns;
    }

    public static List<FilterInfo>    getFilters(List<Column_component_account_connector__mdt> info, 
    Map<String,String> columnNameByFieldName) {
        List<Filter_settings__mdt> filterSettings = getFilterSettings(info);
        List<FilterInfo> filterInfo = new List<FilterInfo>();
        if (filterSettings != null) {
            for (Filter_settings__mdt filterSetting: filterSettings) {
                filterInfo.add(new FilterInfo(
                    columnNameByFieldName.get(filterSetting.Filter_on_api_field_name__c),
                    getLabel(filterSetting.Filter_label__c),
                    filterSetting.Multiselect_filter__c,
                    filterSetting.Display_type__c
                ));
            }
        }
        return filterInfo;
    }

    public static List<QueryField>          getAttributeFields(List<Column> attributes, 
    Map<String, String> fieldNameByColumnName) {
        List<QueryField>     attributeFields = new List<QueryField>();

        for (Column col: attributes) {
            WorkcomponentTypeAttributes.TypeAttributes attrs = col.typeAttributes;
            if (attrs != null) {
                Set<String> neededFieldNames = attrs.getNeededFieldNames();

                if (neededFieldNames != null && neededFieldNames.size() != 0) {
                    for (String neededField: neededFieldNames) {
                        attributeFields.add(new QueryField(fieldNameByColumnName.get(neededField)));
                    }
                }
            }
        }

        return attributeFields;
    }

    public static List<QueryField>       getQueryFields(List<Column_settings__mdt> columnSettings) {
        List<QueryField> queryFields = new List<QueryField>();

        queryFields.add(new QueryField('Id'));
        for (Column_settings__mdt colSetting: columnSettings) {
            String apiFieldName = colSetting.Api_field_name__c;
            String type = colSetting.Type__c;
            // If we are displaying a picklist value as text, we need to query it's label and not it's value
            if (String.isNotBlank(apiFieldName)) {
                if (SchemaUtils.getFieldType('Application__c', apiFieldName) == Schema.DisplayType.PICKLIST && 
                (type == 'datatableCombobox' || type == 'text')) {
                    queryFields.add(new QueryField(apiFieldName, 'toLabel(' + apiFieldName + ')'));
                }
                else {
                    queryFields.add(new QueryField(apiFieldName));
                }
            }
        } 
        
        return queryFields;
    }

    public class DocumentColumn {
        @AuraEnabled public String   filterOnField;
        @AuraEnabled public String   filterPattern;
        @AuraEnabled public String   idFieldName;
        @AuraEnabled public String   versionFieldName;

        DocumentColumn(String filterfield, String pattern, String name, String version) {
            filterOnField = filterfield;
            filterPattern = pattern;
            idFieldName = name;
            versionFieldName = version;
        }
    }

    public static List<DocumentColumn> getDocumentColumns(List<Linked_document_column__mdt> documentColSettings) {
        List<DocumentColumn> docCols = new List<DocumentColumn>();
        for (Linked_document_column__mdt colSetting: documentColSettings) {
            docCols.add(new DocumentColumn(colSetting.Filter_on_field__c, 
            colSetting.Filter_on_pattern__c, colSetting.Field_name__c, colSetting.Version_field_name__c));
        }

        return docCols;
    }

    @AuraEnabled(cacheable=true)
    public static ComponentConfiguration          getSettings(String componentName, Map<String, String> columnNameByFieldName) {
        Map<String, String> fieldNameByColumnName = DeveloperUtils.reverseMap(columnNameByFieldName);
        List<Column_component_account_connector__mdt> info = getComponentInfo(componentName);
        Workcomponent_general_settings__mdt componentSettings = getComponentSettings(info[0].Workcomponent_general_settings__c);

        ComponentConfiguration componentConfiguration = new ComponentConfiguration(componentSettings);
        
        Set<Id> columnSettingIds = DeveloperUtils.getIdFieldSet(info, 'Column_settings__c');
        Set<Id> documentColumnIds = DeveloperUtils.getIdFieldSet(info, 'Linked_document_column__c');
        documentColumnIds.remove(null);

        Map<Id, Linked_document_column__mdt> docCols = null;
        if (documentColumnIds != null && documentColumnIds.size() != 0) {
            docCols = getLinkedDocumentColumns(documentColumnIds);
            for (String key: docCols.keySet()) {
                columnSettingIds.add(docCols.get(key).Column_settings__c);
            }
        }
        columnSettingIds.remove(null);

        Map<Id, Column_settings__mdt> attributeSettings = getAttributeSettings(columnSettingIds);

        componentConfiguration.columns = getColumns(info, attributeSettings, columnNameByFieldName, componentSettings);
        componentConfiguration.filters = getFilters(info, columnNameByFieldName);
        List<QueryField> attributeFields = getAttributeFields(componentConfiguration.columns, fieldNameByColumnName);
        componentConfiguration.queryFields = getQueryFields(attributeSettings.values());
        componentConfiguration.queryFields.addAll(attributeFields);
        if (!String.isBlank(componentConfiguration.rowEditableAPIFieldName)) {
            componentConfiguration.queryFields.add(new QueryField(componentConfiguration.rowEditableAPIFieldName));
        }
        if (docCols != null) {
           componentConfiguration.documentColumns = getDocumentColumns(docCols.values());
        }
        return componentConfiguration;
    }
}