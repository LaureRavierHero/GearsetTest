public with sharing class MailHandler {
    class MailHandlerException extends Exception {}

    /* Creates actual email messages. Expects mailWrapper that specifies all recipients and recordId
    and the result of parsing the corresponding template. */
    private static Messaging.SingleEmailMessage     getMessage(MailWrapper mail, MailTemplateParser.MailTemplateParseResult parsedTemplate) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        message.setToAddresses(mail.recipientIds);
        message.setSubject(parsedTemplate.subject);
        message.setHtmlBody(parsedTemplate.message);

        message.setWhatId(mail.recordId);

        // User greeting thing?
        message.setUseSignature(mail.useSignature);

        message.setEntityAttachments(mail.attachmentIds);
        return message;
    }

    /* Used in flow to send single rejection email to single supplier from application record page
    Calls sendEmail that takes single MailWrapper */
    @InvocableMethod(label = 'Send email frow flow')
    public static void     sendEmail(List<MailWrapper.MailWrapperFlow> mailWrapperFlows) {
        MailWrapper mw = new MailWrapper(mailWrapperFlows[0]);

        sendEmail(mw);
    }
    
    /* Sends single message, could be to any number of recipients */
    public static Messaging.SendEmailResult[]      sendEmail(MailWrapper mail) {
        mail.getTemplate();
        MailTemplateParser.MailTemplateParseResult parsedTemplate = MailTemplateParser.parseEmailTemplate(mail.objectName, mail.recordId, mail.template);
        Messaging.SingleEmailMessage message = getMessage(mail, parsedTemplate);

        Messaging.reserveSingleEmailCapacity(1);
        return Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
    }

    /* Bulk sending of (different) emails. Called by sendEmail. */
    public static Messaging.SendEmailResult[]   sendEmail(List<Messaging.SingleEmailMessage> messages) {
        Messaging.reserveSingleEmailCapacity(messages.size());

        return Messaging.sendEmail(messages);
    }

    private static Map<String, Set<Id>>      getRecordIdsByTemplateType(List<MailWrapper> mails) {
        Map<String, Set<Id>> recordIdsByTemplateType = new Map<String, Set<Id>>();
        for (MailWrapper mw: mails) {
            if (recordIdsByTemplateType.get(mw.mailType) == null) {
                recordIdsByTemplateType.put(mw.mailType, new Set<Id>());
            }
            recordIdsByTemplateType.get(mw.mailType).add(mw.recordId);
        }

        return recordIdsByTemplateType;
    }

    /* Gets the id of a single template from Mailtemplate_account__c */
    private static Id                  getTemplateId(Id accountId, String mailType) {
        QueryBuilder.StringFilterClause accountClause = new QueryBuilder.StringFilterClause('Account__c', new Set<String>{accountId});
        QueryBuilder.StringFilterClause emailTypeClause = new QueryBuilder.StringFilterClause('Type_of_mail__c', new Set<String>{mailType});
        QueryBuilder qb = new QueryBuilder(new Set<String>{'Mailtemplate__c'}, 'Mailtemplate_account__c', new List<QueryBuilder.FilterClause>{accountClause, emailTypeClause});

        List<Mailtemplate_account__c> accountMailConns = Database.query(qb.toString());

        if (accountMailConns == null || accountMailConns.size() == 0) {
            throw new MailHandlerException('No template found with type ' + mailType + ' for account id ' + accountId);
        }
        else if (accountMailConns.size() > 1) {
            throw new MailHandlerException('More than one template found with type ' + mailType + ' for account id ' + accountId);
        }
        return accountMailConns[0].Mailtemplate__c;
    }

    
    /* Gets the actual template (Subject__c/Message__c) so it can be filled. */
    @TestVisible
    private static Mailtemplate__c                getTemplate(Id accountId, String mailType) {
        Id templateId = getTemplateId(accountId, mailType);
        Set<String> fields = SchemaUtils.wildcardSelector('Mailtemplate__c');

        QueryBuilder.StringFilterClause fc = new QueryBuilder.StringFilterClause('Id', new Set<String>{templateId});
        QueryBuilder qb = new QueryBuilder(fields, 'Mailtemplate__c', new List<QueryBuilder.FilterClause>{fc});
        List<Mailtemplate__c> res = Database.query(qb.toString());

        if (res == null || res.size() == 0) {
            throw new MailHandlerException('No mail template could be found for account with id: ' + accountId +
            ' for mail type: ' + mailType);
        }

        return res[0];
    }

    /* Gets connecting objects between account and template (Mailtemplate_account__c) */
    public static List<Mailtemplate_account__c>                  getTemplateConnections(List<MailWrapper> mailWrappers) {
        Set<String> accountIds = new Set<String>();
        Set<String> templateTypes = new Set<String>();

        for (MailWrapper mailWrapper: mailWrappers) {
            accountIds.add(mailWrapper.accountId);
            templateTypes.add(mailWrapper.mailType);
        }
        QueryBuilder.StringFilterClause accountClause = new QueryBuilder.StringFilterClause('Account__c', accountIds);
        QueryBuilder.StringFilterClause emailTypeClause = new QueryBuilder.StringFilterClause('Type_of_mail__c', templateTypes);
        QueryBuilder qb = new QueryBuilder(new Set<String>{'Mailtemplate__c', 'Account__c', 'Type_of_mail__c'}, 'Mailtemplate_account__c', new List<QueryBuilder.FilterClause>{accountClause, emailTypeClause});
        List<Mailtemplate_account__c> accountMailConns = Database.query(qb.toString());

        return accountMailConns;
    }

    public static Map<String, Mailtemplate__c>         getTemplateByTemplateType(List<Mailtemplate_account__c> connectors) {
        Set<Id> templateIds = DeveloperUtils.getIdFieldSet(connectors, 'Mailtemplate__c');
        Set<String> fields = SchemaUtils.wildcardSelector('Mailtemplate__c');
        QueryBuilder.StringFilterClause fc = new QueryBuilder.StringFilterClause('Id', DeveloperUtils.convertToStringSet(templateIds));
        QueryBuilder qb = new QueryBuilder(fields, 'Mailtemplate__c', new List<QueryBuilder.FilterClause>{fc});
        List<Mailtemplate__c> res = Database.query(qb.toString());
        
        Map<Id, Mailtemplate__c> templateById = new Map<Id, Mailtemplate__c>(res);
        Map<String, Mailtemplate__c> templateByType = new Map<String, Mailtemplate__c>();

        for (Mailtemplate_account__c conn: connectors) {
            templateByType.put(conn.Type_of_mail__c, templateById.get(conn.Mailtemplate__c));
        }
        return templateByType;
    }

    /* Function that gets filled templates. Template parser orders results differently based on input. For one template but 
    multiple records, we get the results by recordId */
    private static Map<Id, MailTemplateParser.MailTemplateParseResult> getSingleTemplateArguments(Id accountId, String mailType, 
    String objectName, Set<Id> recordIds) {
        Mailtemplate__c template = getTemplate(accountId, mailType);
        // filled template by record id
        Map<Id, MailTemplateParser.MailTemplateParseResult> filledTemplateByRecordId = 
            MailTemplateParser.parseEmailTemplate(objectName, recordIds, template);

        return filledTemplateByRecordId;
    }

    /* Function that gets filled templates. Template parser orders results differently based on input. For one template but 
    multiple records, we get the results by templateId, then recordId */
    private static Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>>    getMultipleTemplateArguments(
        String objectName, 
        List<MailWrapper> mails,
        List<Mailtemplate_account__c> connectors,
        Map<String, Mailtemplate__c> templateByTemplateType,
        Map<String, Set<Id>> recordIdsByTemplateType) {
        Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>();

        for (String type: templateByTemplateType.keySet()) {
            recordIdsByTemplateId.put(templateByTemplateType.get(type).Id, recordIdsByTemplateType.get(type));
        }
        Map<Id, Mailtemplate__c> templateByTemplateId = new Map<Id, Mailtemplate__c>();
        for (Mailtemplate__c template: templateByTemplateType.values()) {
            templateByTemplateId.put(template.Id, template);
        }

        Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> filledTemplateByRecordIdByTemplateId = 
            MailTemplateParser.parseEmailTemplates(objectName, recordIdsByTemplateId, templateByTemplateId);

        return filledTemplateByRecordIdByTemplateId;
    }

    /* Method that gets the actual email messages when we are dealing with a single template. 
    Combines MailWrapper and filled template based on recordId. */
    private static List<Messaging.SingleEmailMessage>   getMessages(List<MailWrapper> mails, 
    Map<Id, MailTemplateParser.MailTemplateParseResult> filledTemplateByRecordId) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        for (MailWrapper mw: mails) {
            messages.add(getMessage(mw, filledTemplateByRecordId.get(mw.recordId)));
        }
        return messages;
    }

    /* Method that gets the actual email messages when we are dealing with a multiple templates. 
    Combines MailWrapper and filled template based on the type of mail template (which is unique 
    per account) AND the recordId (since we could have the same recordId associated with different 
    mailtemplates in this scenario). */
    private static List<Messaging.SingleEmailMessage>   getMessages(List<MailWrapper> mails, 
    Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> filledTemplateByRecordIdByTemplateType, 
    Map<String, Id> templateIdByType) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

        for (MailWrapper mw: mails) {
            Id templateId = templateIdByType.get(mw.mailType);
            messages.add(getMessage(mw, filledTemplateByRecordIdByTemplateType.get(templateId).get(mw.recordId)));
        }
        return messages;
    }

    /* Use this method if you have multiple records and/or multiple template types 
    to send emails to. Otherwise, use sendEmail */
    public static Messaging.SendEmailResult[]       sendEmails(List<MailWrapper> mails) {
        String objectName = mails[0].objectName;
        Id accountId = SessionConfiguration.accountId;
        
        Map<String, Set<Id>> recordIdsByTemplateType = getRecordIdsByTemplateType(mails);
        Integer numTemplates = recordIdsByTemplateType.keySet().size();

        List<Messaging.SingleEmailMessage> messages;
        if (numTemplates == 1) {
            /* One template multiple record Ids */
            String mailType = mails[0].mailType;
            
            Map<Id, MailTemplateParser.MailTemplateParseResult> filledTemplateByRecordId = 
                getSingleTemplateArguments(accountId, mailType, objectName, recordIdsByTemplateType.get(mailType));
            messages = getMessages(mails, filledTemplateByRecordId);
        }
        else {
            /* Handle multipe templates with multiple record Ids */
            List<Mailtemplate_account__c> connectors = getTemplateConnections(mails);
            Map<String, Mailtemplate__c> templateByTemplateType = getTemplateByTemplateType(connectors);
            Map<Id, Map<Id, MailTemplateParser.MailTemplateParseResult>> filledTemplateByRecordIdByTemplateId = 
                getMultipleTemplateArguments(objectName, mails, connectors, templateByTemplateType, recordIdsByTemplateType);

            Map<String, Id> templateIdByTemplateType = new Map<String, Id>();
            for (String type: templateByTemplateType.keySet()) {
                templateIdByTemplateType.put(type, templateByTemplateType.get(type).Id);
            }

            messages = getMessages(mails, filledTemplateByRecordIdByTemplateId, templateIdByTemplateType);
        }

        return sendEmail(messages);
    }
}