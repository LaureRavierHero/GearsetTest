public with sharing class MailWrapper {
    public Id                   accountId;
    public Id                   recipientId {
        get { return this.recipientId; }
        set {
            this.recipientId = value;
            recipientIds = new List<Id>{this.recipientId};
        }
    }
    public List<Id>             recipientIds; // Has to be Contact or User (but we need those for portal users anyway)
    public Id                   recordId;
    public String               objectName;

    public Id                   templateId {get; set; }
    public Mailtemplate__c      template {get; set; }

    @TestVisible
    public String               mailType;
    public List<String>         attachmentIds; // List of ContentVersion ids/Document ids
    public Boolean              useSignature;

    public class MailWrapperFlow {
        @InvocableVariable(required=true)
        public Id       recipientId;
        @InvocableVariable(required=true)
        public Id       recordId;
        @InvocableVariable(required=true)
        public String   templateType;
        @InvocableVariable
        public String   explanation;
    }

    class MailWrapperException extends Exception {}

    private Id                  getTemplateId() {
        QueryBuilder.StringFilterClause accountClause = new QueryBuilder.StringFilterClause('Account__c', new Set<String>{this.accountId});
        QueryBuilder.StringFilterClause emailTypeClause = new QueryBuilder.StringFilterClause('Type_of_mail__c', new Set<String>{this.mailType});
        QueryBuilder qb = new QueryBuilder(new Set<String>{'Mailtemplate__c'}, 'Mailtemplate_account__c', new List<QueryBuilder.FilterClause>{accountClause, emailTypeClause});

        List<Mailtemplate_account__c> accountMailConns = Database.query(qb.toString());

        if (accountMailConns == null || accountMailConns.size() == 0) {
            throw new MailWrapperException('No template found with type ' + this.mailType + ' for account id ' + this.accountId);
        }
        else if (accountMailConns.size() > 1) {
            throw new MailWrapperException('More than one template found with type ' + this.mailType + ' for account id ' + this.accountId);
        }

        return accountMailConns[0].Mailtemplate__c;
    }

    
    @TestVisible
    public void                getTemplate() {
        templateId = getTemplateId();
        Set<String> fields = SchemaUtils.wildcardSelector('Mailtemplate__c');

        QueryBuilder.StringFilterClause fc = new QueryBuilder.StringFilterClause('Id', new Set<String>{templateId});
        QueryBuilder qb = new QueryBuilder(fields, 'Mailtemplate__c', new List<QueryBuilder.FilterClause>{fc});

        System.debug('GET TEMPLATES QUERY ' + qb.toString());
        List<Mailtemplate__c> res = Database.query(qb.toString());

        if (res == null || res.size() == 0) {
            throw new MailWrapperException('No mail template could be found for account with id: ' + this.accountId +
            ' for mail type: ' + this.mailType);
        }

        this.template = res[0];
    }

    // public static List<Mailtemplate_account__c>                  getTemplateConnections(List<MailWrapper> mailWrappers) {
    //     Set<String> accountIds = new Set<String>();
    //     Set<String> templateTypes = new Set<String>();

    //     for (MailWrapper mailWrapper: mailWrappers) {
    //         accountIds.add(mailWrapper.accountId);
    //         templateTypes.add(mailWrapper.mailType);
    //     }
    //     QueryBuilder.StringFilterClause accountClause = new QueryBuilder.StringFilterClause('Account__c', accountIds);
    //     QueryBuilder.StringFilterClause emailTypeClause = new QueryBuilder.StringFilterClause('Type_of_mail__c', templateTypes);
    //     QueryBuilder qb = new QueryBuilder(new Set<String>{'Mailtemplate__c', 'Account__c', 'Type_of_mail__c'}, 'Mailtemplate_account__c', new List<QueryBuilder.FilterClause>{accountClause, emailTypeClause});

    //     System.debug('GET TEMPLATE IDS QUERY ' + qb.toString());
    //     List<Mailtemplate_account__c> accountMailConns = Database.query(qb.toString());

    //     return accountMailConns;
    // }

    // @TestVisible
    // private static List<Mailtemplate__c>                getTemplates(Set<Id> templateIds) {
    //     Set<String> fields = SchemaUtils.getAllFieldNames('Mailtemplate__c', true, null, 1);

    //     QueryBuilder.StringFilterClause fc = new QueryBuilder.StringFilterClause('Id', DeveloperUtils.convertToStringSet(templateIds));
    //     QueryBuilder qb = new QueryBuilder(fields, 'Mailtemplate__c', new List<QueryBuilder.FilterClause>{fc});

    //     System.debug('GET TEMPLATES QUERY ' + qb.toString());
    //     return Database.query(qb.toString());
    // }

    /* TODO: split update wrappers and get set */
    // public static Map<Id, Mailtemplate__c>         getTemplateByTemplateId(List<MailWrapper> mailWrappers,  
    // List<Mailtemplate_account__c> connectors) {
    //     /* get template ids from connectors where accountIds and types correspond */
    //     Set<Id> templateIds = new Set<Id>();
    //     for (MailWrapper mw: mailWrappers) {
    //         for (Mailtemplate_account__c conn: connectors) {
    //             if (mw.accountId == conn.Account__c && mw.mailType == conn.Type_of_mail__c) {
    //                 mw.templateId = conn.Mailtemplate__c;
    //                 templateIds.add(conn.Mailtemplate__c);
    //                 break;
    //             }
    //         }
    //     }

    //     Map<Id, Mailtemplate__c> templatesByTemplateId = new Map<Id, Mailtemplate__c>(getTemplates(templateIds));
    //     System.debug(templatesByTemplateId);

    //     for (MailWrapper mw: mailWrappers) {
    //         mw.template = templatesByTemplateId.get(mw.templateId);
    //     }

    //     return templatesByTemplateId;
    // }

    // public static Map<Id, Set<Id>>      groupRecordIdsByTemplateId(List<MailWrapper> mailWrappers) {
    //     Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>();

    //     for (MailWrapper mw: mailWrappers) {
    //         if (recordIdsByTemplateId.get(mw.templateId) == null) {
    //             recordIdsByTemplateId.put(mw.templateId, new Set<Id>());
    //         }
    //         recordIdsByTemplateId.get(mw.templateId).add(mw.recordId);
    //     }

    //     // System.debug('RECORD IDS BY TEMPLATE ID ' + recordIdsByTemplateId);
    //     return recordIdsByTemplateId;
    // }

    private MailWrapper(Id recId, String emailType, Boolean signature) {
        accountId = SessionConfiguration.accountId;
        recordId = recId;
        objectName = recordId.getSobjectType().getDescribe().getName();
        mailType = emailType;
        useSignature = signature;
        getTemplate();
    }
    
    public MailWrapper(Id recId, List<Id> recipients, String emailType, Boolean signature) {
        this(recId, emailType, signature);
        recipientIds = recipients;
    }

    public MailWrapper(Id recId, Id recipient, String emailType, Boolean signature) {
        this(recId, emailType, signature);
        recipientId = recipient;
    }

    public MailWrapper(Id recId, Id recipient, String emailType) {
        this(recId, emailType, false);
        recipientId = recipient;
    }

    public MailWrapper(Id recId, List<Id> recipients, String emailType) {
        this(recId, recipients, emailType, false);
    }

    public MailWrapper(MailWrapperFlow mwf) {
        this(mwf.recordId, mwf.recipientId, mwf.templateType, false);
        System.debug(mwf);
    }

    // private static Map<Id, Set<Id>>     groupRecordIdsByTemplateId(List<MailWrapper> mailWrappers) {
    //     Map<Id, Set<Id>> res = new Map<Id, Set<Id>>();

    //     for (MailWrapper mailWrapper: mailWrappers) {
    //         Id key = mailWrapper.template;
    //         Id value = mailWrapper.recordId;

    //         if (res.get(key) == null) {
    //             res.put(key, new Set<Id>());
    //         }

    //         if (String.isNotBlank(value)) {
    //             if (res.get(key) == null) {
    //                 res.put(key, new Set<Id>());
    //             }
    
    //             res.get(key).add(value);
    //         }
    //     }

    //     return res;
    // }
}