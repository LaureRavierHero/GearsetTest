public with sharing class MailTemplateParser {
    class MailTemplateParsingException extends Exception {}

    public class    MailTemplateParseResult {
        public String          subject;
        public String          message;

        MailTemplateParseResult(String s, String m) {
            subject = s;
            message = m;
        }

        MailTemplateParseResult(Mailtemplate__c template) {
            subject = template.Subject__c;
            message = template.Message__c;
        }
    }

    private static String  cleanTemplate(String template, Pattern p) {
        Matcher m = p.matcher(template);
        String currVal;
        String replVal;

        String res = template;
        while(m.find()) {
            currVal = m.group(0);
            replVal = m.group(1) + m.group(3) + m.group(5);
            res = res.replace(currVal, replVal);
        }

        return res;
    }

    /* Used in Mailtemplate insert/update triggers. Ensures that all mergefields are 
    stripped of any whitespace ensuring easier parsing later on:
    {{  Last_name__c  }} becomes {{Last_name__c}} */
    public static void  cleanTemplates(List<Mailtemplate__c> mailTemplates) {
        // Pattern explanation:
        // (\\{\\{) => find '{{'
        // (\\s*) => find any number of whitespace
        // (\\S*) => find any number of non-whitespaces
        // (\\}\\}) => find '}}'
        Pattern allWhiteSpace = Pattern.compile('(\\{\\{)(\\s*)(\\S*)(\\s*)(\\}\\})');

        for (Mailtemplate__c mailTemplate: mailTemplates) {
            mailTemplate.Message__c = cleanTemplate(mailTemplate.Message__c, allWhiteSpace);
            mailTemplate.Subject__c = cleanTemplate(mailTemplate.Subject__c, allWhiteSpace);
        }
    }


    /* Parses the template for fields to query: {{Last_name__c}} in template gives us the 
    Last_name__c field to query. */
    private static Set<String>                 getFieldsFromString(String s) {
        Pattern                 p = Pattern.compile('(?<=\\{\\{)(.*?)(?=\\}\\})');
        Matcher                 m = p.matcher(s);
        String                  field;
        Set<String>             fields = new Set<String>();
        while(m.find()) {
            fields.add(m.group(0));
        }

        return fields;
    }

    public static Set<String>                              getFieldsFromTemplate(Mailtemplate__c template) {
        Set<String>             fields = new Set<String>();

        fields.addAll(getFieldsFromString(template.Subject__c));
        fields.addAll(getFieldsFromString(template.Message__c));

        return fields;
    }

    private static SObject                         getRecord(String objectName, Set<String> fields, Id recordId) {
        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', 
        new Set<String>{recordId});
        QueryBuilder qb = new QueryBuilder(fields, objectName, new List<QueryBuilder.FilterClause>{fc});
        qb.setLimit(1);

        SObject obj = Database.query(qb.toString());

        if (obj == null) {
            throw new MailTemplateParsingException('Query error: no objects of type' + objectName +' found matching id '
            + recordId);
        }

        return obj;
    }

    private static Map<Id, SObject>                         getRecords(String objectName, Set<String> fields, Set<Id> recordIds) {
        Map<Id, List<SObject>>  valuesByRecordId = new Map<Id, List<SObject>>();

        QueryBuilder.FilterClause fc = new QueryBuilder.StringFilterClause('Id', 
        DeveloperUtils.convertToStringSet(recordIds));
        QueryBuilder qb = new QueryBuilder(fields, objectName, new List<QueryBuilder.FilterClause>{fc});

        Map<Id, SObject> objects = new Map<Id, SObject>(Database.query(qb.toString()));

        if (objects == null || objects.size() == 0) {
            throw new MailTemplateParsingException('Query error: no objects of type' + objectName +' found matching id in '
            + recordIds);
        }

        return objects;
    }

    public static Map<String, String>                  getValuesByField(SObject record, Set<String> fields) {
        Map<String, String>     valuesByFields = new Map<String, String>();

        for (String fieldName: fields) {
            SObject curr = DeveloperUtils.getObjectFromFieldName(record, fieldName);
            String shortenedKey = (String)DeveloperUtils.getLastElement(fieldName.split('\\.'));

            valuesByFields.put(fieldName, String.valueOf(curr.get(shortenedKey)));
        }

        return valuesByFields;
    }

    private static Map<Id, Map<String, String>>          getValuesByFieldByRecordId(Map<Id, SObject> recordsById, Set<String> fields) {
        Map<Id, Map<String, String>>    valuesByFieldByRecordId = new Map<Id, Map<String, String>>();

        for (Id recordId: recordsById.keySet()) {
            valuesByFieldByRecordId.put(recordId, getValuesByField(recordsById.get(recordId), fields));
        }

        return valuesByFieldByRecordId;
    }

    @TestVisible
    private static MailTemplateParseResult     parseTemplate(Mailtemplate__c template, Id recordId, 
    Map<String, String> valuesByField) {
        String resSubj = template.Subject__c;
        String resMess = template.Message__c;

        for (String fieldName: valuesByField.keySet()) {
            String value = valuesByField.get(fieldName);
            if (value == null)
                value = '';
            String substitute = '{{' + fieldName + '}}';
            Boolean subjectHasField = resSubj.contains(substitute);
            Boolean messageHasField = resMess.contains(substitute);

            // if (String.isBlank(value) && (subjectHasField || messageHasField)) {
            //     throw new MailTemplateParsingException('Error: missing fields used in template with id ' + template.Id + '. No value for field: '
            //     + fieldName + ' for record with id: ' + recordId);
            // }

            resSubj = resSubj.replace(substitute, value);
            resMess = resMess.replace(substitute, value);
        }

        return new MailTemplateParseResult(resSubj, resMess);
    }

    private static Map<Id, MailTemplateParseResult>     parseTemplate(Mailtemplate__c template, Set<Id> recordIds, 
    Map<Id, Map<String, String>> valuesByFieldByRecordId) {
        String resSubj;
        String resMess;
        Map<Id, MailTemplateParseResult>    parsedTemplateByRecordId = new Map<Id, MailTemplateParseResult>();

        for (Id recordId: recordIds) {
            resMess = template.Message__c;
            resSubj = template.Subject__c;
            Map<String, String> valuesByFields = valuesByFieldByRecordId.get(recordId);

            parsedTemplateByRecordId.put(recordId, parseTemplate(template, recordId, valuesByFields));
        }

        return parsedTemplateByRecordId;
    }

    /* Several templates and one record 
    
    Returns filled templates by recordIds */
    public static Map<Id, MailTemplateParseResult>     parseEmailTemplates(String objectName, 
    Id recordId, Map<Id, Mailtemplate__c> templateByTemplateId) {
        Map<Id, Set<String>>            fieldsByTemplateId = new Map<Id, Set<String>>();
        Set<String>                     allFields = new Set<String>();

        for (Id templateId: templateByTemplateId.keySet()) {
            fieldsByTemplateId.put(templateId, getFieldsFromTemplate(templateByTemplateId.get(templateId)));
            allFields.addAll(fieldsByTemplateId.get(templateId));
        }

        Map<Id, MailTemplateParseResult>   parsedMailTemplateByTemplateId = new Map<Id, MailTemplateParseResult>();
        if (allFields.size() != 0) {
            /* Handle actual template arguments in template */
            SObject                 record = getRecord(objectName, allFields, recordId);
            Map<String, String>     values = getValuesByField(record, allFields);

            for (Id templateId: templateByTemplateId.keySet()) {
                Mailtemplate__c template = templateByTemplateId.get(templateId);
    
                parsedMailTemplateByTemplateId.put(templateId, parseTemplate(template, recordId, 
                values));
            }
        }
        else {
            /* Handle template is just text, no arguments */
            for (Id templateId: templateByTemplateId.keySet()) {
                Mailtemplate__c template = templateByTemplateId.get(templateId);
    
                MailTemplateParseResult res = new MailTemplateParseResult(template);
                parsedMailTemplateByTemplateId.put(templateId, res);
            }
        }
        return parsedMailTemplateByTemplateId;
    }

    private static Map<Id, Map<Id, MailTemplateParseResult>>     parseEmailTemplatesNoSubstitutions(
    Map<Id, Mailtemplate__c> templateByTemplateId,
    map<Id, Set<Id>> recordIdsByTemplateId) {
        Map<Id, Map<Id, MailTemplateParseResult>>   parsedMailTemplateByRecordIdByTemplateId = 
            new Map<Id, Map<Id, MailTemplateParseResult>>();
        
        Map<Id, MailTemplateParseResult> filledTemplateByRecordId = new Map<Id, MailTemplateParseResult>();
        
        for (Id templateId: templateByTemplateId.keySet()) {
            Mailtemplate__c template = templateByTemplateId.get(templateId);

            MailTemplateParseResult parseResult = new MailTemplateParseResult(template);
            Map<Id, MailTemplateParseResult> resultByRecordId = new Map<Id, MailTemplateParseResult>();
            for (Id recordId: recordIdsByTemplateId.get(templateId)) {
                resultByRecordId.put(recordId, parseResult);
            }

            parsedMailTemplateByRecordIdByTemplateId.put(templateId, resultByRecordId);
        }

        return parsedMailTemplateByRecordIdByTemplateId;
    }

    private static Map<Id, Map<Id, MailTemplateParseResult>>     parseEmailTemplateswithSubstitutions(
    String objectName,
    Set<String> allFields,
    Set<Id> allRecordIds,
    Map<Id, Mailtemplate__c> templateByTemplateId,
    map<Id, Set<Id>> recordIdsByTemplateId) {
        Map<Id, SObject>                            records = getRecords(objectName, allFields, allRecordIds);
        Map<Id, Map<String, String>>                values = getValuesByFieldByRecordId(records, allFields);
        Map<Id, Map<Id, MailTemplateParseResult>>   parsedMailTemplateByRecordIdByTemplateId = 
            new Map<Id, Map<Id, MailTemplateParseResult>>();

        for (Id templateId: templateByTemplateId.keySet()) {
            Mailtemplate__c template = templateByTemplateId.get(templateId);

            parsedMailTemplateByRecordIdByTemplateId.put(templateId, parseTemplate(template, recordIdsByTemplateId.get(templateId), 
            values));
        }

        return parsedMailTemplateByRecordIdByTemplateId;
    }

    /* Several templates and several records 
    
    Returns filled templates by record Id by template id */
    public static Map<Id, Map<Id, MailTemplateParseResult>>     parseEmailTemplates(String objectName, 
    map<Id, Set<Id>> recordIdsByTemplateId, Map<Id, Mailtemplate__c> templateByTemplateId) {
        Map<Id, Set<String>>            fieldsByTemplateId = new Map<Id, Set<String>>();
        Set<String>                     allFields = new Set<String>();
        Set<Id>                         allRecordIds = new Set<Id>();

        for (Id templateId: templateByTemplateId.keySet()) {
            fieldsByTemplateId.put(templateId, getFieldsFromTemplate(templateByTemplateId.get(templateId)));
            allFields.addAll(fieldsByTemplateId.get(templateId));
            allRecordIds.addAll(recordIdsByTemplateId.get(templateId));
        }

        Map<Id, Map<Id, MailTemplateParseResult>>   parsedMailTemplateByRecordIdByTemplateId = New Map<Id, Map<Id, MailTemplateParseResult>>();

        if (allFields.size() != 0) {
            return parseEmailTemplateswithSubstitutions(objectName, allFields, allRecordIds, templateByTemplateId, recordIdsByTemplateId);
        }
        else {
            return parseEmailTemplatesNoSubstitutions(templateByTemplateId, recordIdsByTemplateId);
        }
    }

    /* One template multiple records 
    
    Returns filled template by record id*/
    public static Map<Id, MailTemplateParseResult>  parseEmailTemplate(String objectName, Set<Id> recordIds, Mailtemplate__c template) {
        Set<String>                     fields = getFieldsFromTemplate(template);
        
        if (fields.size() != 0) {
            /* Handle template with substitutions */
            Map<Id, SObject>                records = getRecords(objectName, fields, recordIds);
            Map<Id, Map<String, String>>    values = getValuesByFieldByRecordId(records, fields);

            return parseTemplate(template, recordIds, values);
        }
        else {
            /* Handle template without substitutions */
            Map<Id, MailTemplateParseResult> resultsByRecordId = new Map <Id, MailTemplateParseResult>();
            MailTemplateParseResult res = new MailTemplateParseResult(template);
            for (Id recordId: recordIds) {
                resultsByRecordId.put(recordId, res);
            }
            return resultsByRecordId;
        }
    }

    /* One template one record 
    
    Returns filled template */

    public static MailTemplateParseResult          parseEmailTemplate(String objectName, Id recordId, Mailtemplate__c template) {
        Set<String>             fields = getFieldsFromTemplate(template);
        
        if (fields.size() != 0) {
            /* Handle template with substitutions */
            SObject                 record = getRecord(objectName, fields, recordId);
            Map<String, String>     values = getValuesByField(record, fields);
    
            return parseTemplate(template, recordId, values);
        }
        else {
            /* Handle template withput substitutions */
            return new MailTemplateParseResult(template);
        }
    }
}