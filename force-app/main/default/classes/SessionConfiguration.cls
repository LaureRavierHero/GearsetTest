public class SessionConfiguration {

    public class SessionConfigurationException extends Exception {}
    public static String accountName {
        get {
            if (String.isBlank(accountName)) {
                List<User> userList = [ SELECT Account_name__c FROM User WHERE Id = :UserInfo.getUserId() ];
                if (userList == null || userList.size() == 0) {
                    throw new SessionConfigurationException('User is not found');
                }
                accountName = userList[0].Account_name__c;
            }
            if (String.isBlank(accountName)) {
                throw new SessionConfigurationException('User is not associated with an account');
            }
            return accountName;
        }
        private set;
    }

    public static Id accountId {
        get {
            if (String.isBlank(accountId)) {
                try {
                    List<Account> accList = [ SELECT Id FROM Account WHERE Name = :accountName ];
                    if (accList == null || accList.size() == 0) {
                        throw new SessionConfigurationException('Account name user is associated with was not found');
                    }
                    accountId = accList[0].Id;
                }
                catch (Exception e) {
                    throw e;
                }
            }
            if (String.isBlank(accountId)) {
                throw new SessionConfigurationException('Account name user is associated with was not found');
            }
            return accountId;
        }
        private set;
    }

    public static Account_datatable_general_settings__mdt workComponentSettings{
        get {
            if (workComponentSettings == null) {
                Set<String> tableFields = SchemaUtils.getAllFieldNames(
                'Account_datatable_general_settings__mdt');
            
                List<QueryBuilder.FilterClause> fcs = new List<QueryBuilder.FilterClause>{
                    new QueryBuilder.StringFilterClause('Account_name__c', new Set<String>{accountName})
                };
                QueryBuilder qb = new QueryBuilder(tableFields, 'Account_datatable_general_settings__mdt', fcs);
                List<Account_datatable_general_settings__mdt> generalSettings = Database.query(qb.toString());
                if (generalSettings == null || generalSettings.size() == 0) {
                    throw new SessionConfigurationException('No settings for work component found for account with name: ' + accountName + 'and id: ' + accountId);
                }

                workComponentSettings = generalSettings[0];
            }
            return workComponentSettings;
        }
        private set;
    }

    public static List<Account_datatable_settings__mdt> workComponentConfig {
        get {
            if (workComponentConfig == null) {
                /* Get all fields */
                Set<String> tableFields = SchemaUtils.getAllFieldNames(
                'Account_datatable_settings__mdt');
            
                List<QueryBuilder.OrderClause> ocs = new List<QueryBuilder.OrderClause>{
                    new QueryBuilder.OrderClause('Order__c', QueryBuilder.SortOrder.ASCEND, QueryBuilder.NullsPosition.NULLSLAST)
                };
                List<QueryBuilder.FilterClause> fcs = new List<QueryBuilder.FilterClause>{
                    new QueryBuilder.StringFilterClause('Account_name__c', new Set<String>{accountName})
                };
                QueryBuilder qb = new QueryBuilder(tableFields, 'Account_datatable_settings__mdt', fcs, ocs);
                workComponentConfig = Database.query(qb.toString());
            }
            if (workComponentConfig == null || workComponentConfig.size() == 0) {
                throw new SessionConfigurationException('No configuration for work component found for account with name: ' + accountName + 'and id: ' + accountId);
            }
            return workComponentConfig;
        }
        private set;
    }

    public static String orgUrl {
        get {
            if (String.isBlank(orgUrl)) {
                orgUrl = URL.getOrgDomainUrl().toExternalForm();
            }
            return orgUrl;
        }
        private set;
    }
}