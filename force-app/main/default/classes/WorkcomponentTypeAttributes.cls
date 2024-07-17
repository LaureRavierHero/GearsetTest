public with sharing class WorkcomponentTypeAttributes {
    /* ----- ACTIONS ----- */
    public virtual class Action {
        String  label;
        String  name;

        Action(String lbl, String nm) {
            label = lbl;
            name = nm;
        }
    }

    class RowAction extends Action {
        RowAction(String lbl, String nm) {
            super(lbl, nm);
        }
    }

    @TestVisible
    public class ColumnAction extends Action {
        Boolean checked;
        Boolean disabled;
        String  iconName;

        @TestVisible
        ColumnAction(String lbl, String nm, Boolean chk, Boolean disable, String iconNm) {
            super(lbl, nm);
            checked = chk;
            disabled = disable;
            iconName = iconNm;
        }
    }
    /* ----- COLUMN AND CELL CONFIGURATION ----- */
    @TestVisible
    class FieldName {
        // Used to bind values in a column name to a field { fieldName: 'columnName' }
        @AuraEnabled public String fieldName { get; set; }
        {
            fieldName = '';
        }

        @TestVisible
        fieldName(String columnName) {
            fieldName = !String.isBlank(columnName) ? columnName: '';
        }
    }

 
    @TestVisible
    public class CellAttributes {
        @AuraEnabled public String      iconName; // name of lightning-icon, aka: 'utility:down'
        @AuraEnabled public String      iconLabel;  // optional: label displayed next to icon
        @AuraEnabled public FieldName   iconLabelField; //
        @AuraEnabled public String      iconPosition { get; set; }   // left or right
        @AuraEnabled public String      iconAlternativeText { get; set; }
        @AuraEnabled public Boolean     showLabel { get; set; }
        @AuraEnabled public String      alignment { get; set; }

        {
            iconName = '';
            iconLabel = '';
            showLabel = false;
            iconLabelField = null;
            iconPosition = 'left';
            iconAlternativeText = '';
            showLabel = false;
            alignment = 'right';
        }
    }

    public virtual class TypeAttributes {
        @AuraEnabled public FieldName rowEditable;

        TypeAttributes() {}
        TypeAttributes(String editableColName) {
            rowEditable = new FieldName(editableColName);
        }

        public virtual Set<String> getNeededFieldNames() {return null;}
    }

    class   TimeFormat {
        @AuraEnabled
        public String  hour;
        @AuraEnabled
        public String  minute;
 
        TimeFormat() {
            hour = '2-digit';
            minute = '2-digit';
        }
    }

    private static Map<String, String> dayOptions = new Map<String, String>{
        'D' => 'numeric',
        'DD' => '2-digit'
    };

    private static Map<String, String> monthOptions = new Map<String, String>{
        'M' => 'numeric',
        'MM' => '2-digit',
        'MTH' => 'short',
        'MONTH' => 'long'
    };

    private static Map<String, String> yearOptions = new Map<String, String>{
        'YY' => '2-digit',
        'YYYY' => 'numeric'
    };

    @TestVisible
    class   DateAttributes extends TypeAttributes {
        @AuraEnabled public String  year;   //
        @AuraEnabled public String  month;  //
        @AuraEnabled public String  day;    // numeric or 2-digit

        @TestVisible
        DateAttributes(String format) {
            List<String> options = format.split('-');

            for (String opt: options) {
                if(opt.contains('D')) {
                    day = dayOptions.get(opt);
                }
                else if(opt.contains('M')) {
                    month = monthOptions.get(opt);
                }
                else if(opt.contains('Y')) {
                    year = yearOptions.get(opt);
                }
            }
        }
    }

    public virtual class RelatedRecordLinkAttributes extends TypeAttributes {
        @AuraEnabled public FieldName   recordId { get; set; }
        @AuraEnabled public String      iconName;
        @AuraEnabled public String      objectApiName { get; set; }
        @AuraEnabled public FieldName   recordName {get; set;}
 
        RelatedRecordLinkAttributes(String nameColumnName,String idColumnName, String objApiName,
        String iconNm) {
            recordName = new FieldName(nameColumnName);
            recordId = new FieldName(idColumnName);
            objectApiName = objApiName;
            iconName = String.isBlank(iconNm)? '' : iconNm;
        }

        public override Set<String> getNeededFieldNames(){ return new Set<String>{ recordId.fieldName, recordName.fieldName }; }
    }

    public virtual class ApplicationMessageAttributes extends TypeAttributes {
        @AuraEnabled public FieldName   recordId { get; set; }
        @AuraEnabled public FieldName   recordName {get; set;}
 
        ApplicationMessageAttributes(String nameColumnName,String idColumnName) {
            recordName = new FieldName(nameColumnName);
            recordId = new FieldName(idColumnName);
        }

        public override Set<String> getNeededFieldNames(){ return new Set<String>{ recordId.fieldName, recordName.fieldName }; }
    }

    // class RelatedRecordLinkAttributesColNameLabel extends RelatedRecordLinkAttributes {
    //     @AuraEnabled public FieldName label {get; set;}
        
    //     RelatedRecordLinkAttributesColNameLabel(String labelColumnName, String idColumnName, String objApiName,
    //     String iconNm) {
    //         super(idColumnName, objApiName, iconNm);
    //         label = new FieldName(labelColumnName);
    //     }

    //     public String  getNameColumnName() {
    //         return label.fieldName;
    //     }
    // }

    // class RelatedRecordLinkAttributesStandardLabel extends RelatedRecordLinkAttributes {
    //     @AuraEnabled public String label { get; set; }
        
    //     RelatedRecordLinkAttributesStandardLabel(String lbl, String idColumnName, String objApiName,
    //     String iconNm) {
    //         super(idColumnName, objApiName, iconNm);
    //         label = lbl;
    //     }
    // }
    class TextAttributes extends TypeAttributes {
        @AuraEnabled public FieldName    value;
        @AuraEnabled public FieldName   recordId;
        @AuraEnabled public String      fieldName;
        @AuraEnabled public Boolean     isRichText;
        @AuraEnabled public Boolean     isFullView;
        // @AuraEnabled public FieldName   rowEditable;

        TextAttributes(String valueColumnName, String idColumnName, String editableColumnName, Boolean isRich, Boolean isView) {
            super(editableColumnName);
            fieldName = valueColumnName;
            value = new FieldName(valueColumnName);
            recordId = new FieldName(idColumnName);
            isRichText = isRich;
            isFullView = isView;
            // rowEditable = new FieldName(editableColumnName);
        }
    }

    public virtual class StarRaterAttributes extends TypeAttributes {
        @AuraEnabled public FieldName       rating;
        @AuraEnabled public FieldName       recordId;
        @AuraEnabled public String          fieldName;

        @TestVisible
        StarRaterAttributes(String ratingColumnName, String idColumnName, String editableColumnName) {
            super(editableColumnName);
            fieldName = ratingColumnName;
            rating = new FieldName(ratingColumnName);
            recordId = new FieldName(idColumnName);
        }

        // public String               getIdColumnName() {
        //     return recordId.fieldName;
        // }

        // public String      getRatingColumnName() {
        //     return rating.fieldName;
        // }
    }

    public class DependentStarRaterAttributes extends StarRaterAttributes {
        @AuraEnabled public FieldName locked;
        DependentStarRaterAttributes(String ratingColumnName, String idColumnName, String lockColumnName, String editColumnName) {
            super(ratingColumnName, idColumnName, editColumnName);
            locked = new FieldName(lockColumnName);
        }

        public override Set<String> getNeededFieldNames(){ return String.isNotBlank(locked.fieldName) ? new Set<String>{locked.fieldName} : null; }
    }

    public class IconValueMap {
        @AuraEnabled public String icon;
        @AuraEnabled public String value;

        iconValueMap(String v, String i) {
            value = v;
            icon = i;
        }
    }

    public class IconCarouselAttributes extends TypeAttributes {
        @AuraEnabled public FieldName               value;
        @AuraEnabled public FieldName               locked;
        @AuraEnabled public FieldName               recordId;
        @AuraEnabled public String                  placeholder;
        @AuraEnabled public String                  fieldName;
        @AuraEnabled public List<IconValueMap>      items;

        @TestVisible
        private List<iconValueMap>        getIconValueMap(String fieldApiName) {
            /* Queries values + icons from metadata based on field api name */
            List<IconValueMap> res = new List<IconValueMap>();
            Set<String> fields = SchemaUtils.getAllFieldNames('Picklist_value_to_icon_map__mdt');

            QueryBuilder.FilterClause fc_account = new QueryBuilder.StringFilterClause('Account_name__c', 
                new Set<String>{SessionConfiguration.accountName});
            QueryBuilder.FilterClause fc_field = new QueryBuilder.StringFilterClause('Api_field_name__c', 
                new Set<String>{fieldApiName});
            QueryBuilder qb = new QueryBuilder(fields, 'Picklist_value_to_icon_map__mdt', 
                new List<QueryBuilder.FilterClause>{fc_account, fc_field});
            
            List<Picklist_value_to_icon_map__mdt> iconValueMapEntries = Database.query(qb.toString());
            DeveloperUtils.printList(iconValueMapEntries);
            for (Picklist_value_to_icon_map__mdt entry: iconValueMapEntries) {
                res.add(new IconValueMap(entry.Picklist_value__c, entry.Icon_name__c));
            }
            
            DeveloperUtils.printList(res);
            return res;
        }

        @TestVisible
        IconCarouselAttributes(String valueColumnName, String idColumnName, String lockedColumnName,
        String fieldApiName, String editableColumnName) {
            super(editableColumnName);
            value = new FieldName(valueColumnName);
            recordId = new FieldName(idColumnName);
            items = getIconValueMap(fieldApiName);
            locked = new FieldName(lockedColumnName);
            fieldName = valueColumnName;
        }

        public override Set<String> getNeededFieldNames(){ return String.isNotBlank(locked.fieldName) ? new Set<String>{locked.fieldName} : null; }
    }

    public class IconFromPicklist extends TypeAttributes {
        @AuraEnabled public FieldName               value;
        @AuraEnabled public String                  fieldName;
        @AuraEnabled public List<IconValueMap>      items;

        // TODO: THIS IS DUPLICATED CODE! (SEE ICON CAROUSEL)
        @TestVisible
        private List<iconValueMap>        getIconValueMap(String fieldApiName) {
            /* Queries values + icons from metadata based on field api name */
            List<IconValueMap> res = new List<IconValueMap>();
            Set<String> fields = SchemaUtils.getAllFieldNames('Picklist_value_to_icon_map__mdt');

            QueryBuilder.FilterClause fc_account = new QueryBuilder.StringFilterClause('Account_name__c', 
                new Set<String>{SessionConfiguration.accountName});
            QueryBuilder.FilterClause fc_field = new QueryBuilder.StringFilterClause('Api_field_name__c', 
                new Set<String>{fieldApiName});
            QueryBuilder qb = new QueryBuilder(fields, 'Picklist_value_to_icon_map__mdt', 
                new List<QueryBuilder.FilterClause>{fc_account, fc_field});
            
            List<Picklist_value_to_icon_map__mdt> iconValueMapEntries = Database.query(qb.toString());
            DeveloperUtils.printList(iconValueMapEntries);
            for (Picklist_value_to_icon_map__mdt entry: iconValueMapEntries) {
                res.add(new IconValueMap(entry.Picklist_value__c, entry.Icon_name__c));
            }
            
            DeveloperUtils.printList(res);
            return res;
        }

        @TestVisible
        IconFromPicklist(String valueColumnName, String fieldApiName) {
            fieldName = valueColumnName;
            value = new FieldName(valueColumnName);
            items = getIconValueMap(fieldApiName);
        }
    }

    public virtual class ComboboxAttributes extends TypeAttributes {
        @AuraEnabled public FieldName               value;
        @AuraEnabled public FieldName               recordId;
        // @AuraEnabled public FieldName               rowEditable;
        @AuraEnabled public String                  placeholder;
        @AuraEnabled public String                  fieldName;
        @AuraEnabled public List<SchemaUtils.PicklistItem>      options;

        @TestVisible
        ComboboxAttributes(String valueColumnName, String idColumnName, String editableColumnName,
        List<SchemaUtils.PicklistItem> opts) {
            super(editableColumnName);
            value = new FieldName(valueColumnName);
            recordId = new FieldName(idColumnName);
            // rowEditable = new FieldName(editableColumnName);
            placeholder = '';
            options = opts;
            fieldName = valueColumnName;
        }

        @TestVisible
        ComboboxAttributes(String valueColumnName, String idColumnName, String editableColumnName,
        String ph, List<SchemaUtils.PicklistItem> opts) {
            this(valueColumnName, idColumnName, editableColumnName, opts);
            placeholder = ph;
        }
    }

    @TestVisible
    public class ComboboxAttributesDependentDisable extends ComboboxAttributes {
        @AuraEnabled public FieldName       locked;

        @TestVisible
        ComboboxAttributesDependentDisable(String valueColumnName, String lockColumnName, String idColumnName, 
        String editableColumnName, List<SchemaUtils.PicklistItem> opts) {
            super(valueColumnName, idColumnName, editableColumnName, opts);
            System.debug('EDITABLE IF TRUE: ' + lockColumnName);

            locked = new FieldName(lockColumnName);
        }

        @TestVisible
        ComboboxAttributesDependentDisable(String valueColumnName, String lockColumnName, String idColumnName, 
        String ph, String editableColumnName, List<SchemaUtils.PicklistItem> opts) {
            this(valueColumnName, lockColumnName, idColumnName, editableColumnName, opts);
            placeholder = ph;
        }

        public override Set<String> getNeededFieldNames(){ return String.isNotBlank(locked.fieldName) ? new Set<String>{locked.fieldName} : null; }
    }

    @TestVisible
    public class DocumentLink extends TypeAttributes {
        @AuraEnabled public FieldName   documentId; // Name of column containing Ids
        @AuraEnabled public FieldName   versionId;
        @AuraEnabled public String      iconName;
        @AuraEnabled public String      variant;
        @AuraEnabled public String      title;
        @AuraEnabled public String      urlPrefix;
        @AuraEnabled public String      urlPostfix;

        DocumentLink(String docIdColumnName, String versionIdColName, String iName, String iVar, String t, String prefix,
        String postfix) {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            documentId = new FieldName(docIdColumnName);
            versionId = new FieldName(versionIdColName);
            iconName = iName;
            title = t;
            urlPrefix = baseUrl + prefix;
            urlPostfix = postfix;
        }
    }

    class ActionAttributes extends TypeAttributes {
        @AuraEnabled public List<RowAction> rowActions;
        @AuraEnabled public String          menuAlignment;
    }

    public class ButtonAttributes extends TypeAttributes {
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public String  iconName;
        @AuraEnabled public String  iconPosition;
        @AuraEnabled public String  label;
        @AuraEnabled public String  name;
        @AuraEnabled public String  title;
        @AuraEnabled public String  variant;
    }

    public class ButtonIconAttributes extends TypeAttributes {
        @AuraEnabled public String  alternativeText;
        @AuraEnabled public String  class_x;
        @AuraEnabled public Boolean disabled;
        @AuraEnabled public String  iconClass;
        @AuraEnabled public String  iconName;
        @AuraEnabled public String  name;
        @AuraEnabled public String  title;
        @AuraEnabled public String  variant;

        ButtonIconAttributes(String iName, String var, String ti) {
            title = ti;
            iconName = iName;
            variant = var;
        }
    }

    public interface TypeAttributesFactory {
        TypeAttributes getTypeAttributes(Column_settings__mdt attributeSettings, 
        Map<String,String> columnNamesByFieldNames, String keyFieldColumn,
        String objectName, String editableFieldName);
    }

    public class    ConcreteTypeAttributesFactory {
        public TypeAttributes getTypeAttributes(Column_settings__mdt attributeSettings, 
        Map<String,String> columnNamesByFieldNames, String keyFieldColumn,
        String objectName, String editableColumnName) {
            String type = attributeSettings.Type__c;
  
            switch on attributeSettings.Type__c {
                when 'recordViewNavigation' {
                    String idColumnName = columnNamesByFieldNames.get(attributeSettings.Related_record_attributes__r.Id_api_field_name__c);
                    String nameColumnName = columnNamesByFieldNames.get(attributeSettings.Related_record_attributes__r.Name_api_field_name__c);
                    return new RelatedRecordLinkAttributes(
                        nameColumnName,
                        idColumnName,
                        attributeSettings.Related_record_attributes__r.Object_api_name__c,
                        attributeSettings.Related_record_attributes__r.Icon_name__c
                    );
                }
                when 'date-local' {
                    return new DateAttributes(attributeSettings.Date_attributes__r.Format__c);
                }
                when 'customText' {
                    Boolean isRichText = attributeSettings.Text_attributes__r.Is_rich_text__c;
                    Boolean isFullView = attributeSettings.Text_attributes__r.Is_full_view__c;
                    String textColumnName = columnNamesByFieldNames.get(attributeSettings.Text_attributes__r.Text_api_field_name__c);

                    return new TextAttributes(
                        textColumnName,
                        keyFieldColumn,
                        editableColumnName,
                        isRichText,
                        isFullView
                    );
   
                }
                when 'starRating' {
                    String ratingColumnName = columnNamesByFieldNames.get(attributeSettings.Star_rating_attributes__r.Rating_api_field_name__c);
                    String lockColumnName = columnNamesByFieldNames.get(attributeSettings.Star_rating_attributes__r.Lock_api_field_name__c);
                    if (!String.isBlank(lockColumnName)) {
                        return new DependentStarRaterAttributes(
                            ratingColumnName,
                            lockColumnName,
                            keyFieldColumn,
                            editableColumnName
                        );
                    }
                    else {
                        return new StarRaterAttributes(
                            ratingColumnName,
                            keyFieldColumn,
                            editableColumnName
                        );
                    }
                }
                when 'datatableCombobox' {
                    System.debug('COMBOBOX: ' + attributeSettings);

                    Boolean dependsOn = (attributeSettings.Combobox_picklist_attributes__r.Editable_if_true__c != null);
                    if (!dependsOn) {
                        return new ComboboxAttributes(
                            attributeSettings.Combobox_picklist_attributes__r.Choice_column_field_name__c,
                            keyFieldColumn,
                            editableColumnName,
                            SchemaUtils.getPicklistOptions(objectName, attributeSettings.Combobox_picklist_attributes__r.Api_field_name__c)
                        );
                    }
                    else {
                        return new ComboboxAttributesDependentDisable (
                            attributeSettings.Combobox_picklist_attributes__r.Choice_column_field_name__c,
                            columnNamesByFieldNames.get(attributeSettings.Combobox_picklist_attributes__r.Editable_if_true__c),
                            keyFieldColumn,
                            editableColumnName,
                            SchemaUtils.getPicklistOptions(objectName, attributeSettings.Combobox_picklist_attributes__r.Api_field_name__c)
                        );
                    }
                }
                when 'iconCarousel' {
                    return new IconCarouselAttributes(
                        attributeSettings.Combobox_picklist_attributes__r.Choice_column_field_name__c,
                        keyFieldColumn,
                        columnNamesByFieldNames.get(attributeSettings.Combobox_picklist_attributes__r.Editable_if_true__c),
                        attributeSettings.Combobox_picklist_attributes__r.Api_field_name__c, 
                        editableColumnName
                    );
                }
                when 'iconFromPicklist' {
                    return new IconFromPicklist(
                        columnNamesByFieldNames.get(attributeSettings.Icon_from_picklistvalue_attributes__r.Api_field_name__c),
                        attributeSettings.Icon_from_picklistvalue_attributes__r.Api_field_name__c
                    );
                }
                when 'button-icon' {
                    return new ButtonIconAttributes(
                        attributeSettings.Button_icon_attributes__r.Icon_name__c,
                        attributeSettings.Button_icon_attributes__r.Variant__c,
                        attributeSettings.Button_icon_attributes__r.Title__c
                    );
                }
                when 'documentLink' {
                    return new DocumentLink(
                        attributeSettings.Document_link_attributes__r.Document_id_field_name__c,
                        attributeSettings.Document_link_attributes__r.Document_version_field_name__c,
                        attributeSettings.Document_link_attributes__r.Icon_name__c,
                        attributeSettings.Document_link_attributes__r.Variant__c,
                        attributeSettings.Document_link_attributes__r.Title__c,
                        attributeSettings.Document_link_attributes__r.Url_prefix__c,
                        attributeSettings.Document_link_attributes__r.Url_postfix__c
                    );
                }
                when 'applicationMessage' {
                    String idColumnName = columnNamesByFieldNames.get(attributeSettings.Application_message_attributes__r.Id_field_api_name__c);
                    String nameColumnName = columnNamesByFieldNames.get(attributeSettings.Application_message_attributes__r.Name_field_api_name__c);
                    return new ApplicationMessageAttributes(
                        nameColumnName,
                        idColumnName
                    );
                }
            }
            return null;
        }
    }
}