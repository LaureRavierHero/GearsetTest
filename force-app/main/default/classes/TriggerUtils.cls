public class TriggerUtils {
    private static String    getFullName(String firstName, String preposition, String lastName) {
        return (firstName + ' ' + ((String.isEmpty(preposition)) ? '' : (preposition.toLowerCase() + ' ')) + lastName);
    }

    public static void      setFullNames(List<SObject> objects) {
        for (SObject obj: objects) {
            if (String.isBlank((String)obj.get('Name'))) {
                System.debug('Setting name: ' + getFullName((String)obj.get('First_name__c'), (String)obj.get('Preposition__c'), (String)obj.get('Last_name__c')));
                obj.put('Name', getFullName((String)obj.get('First_name__c'), (String)obj.get('Preposition__c'), (String)obj.get('Last_name__c')));
            }
        }
    }

    public static void      addUserAccountToObjects(List<SObject> objects) {
        /* Add account name based on user Id */
        Id accId;

        if (UserInfo.getUserType() != 'Standard') {
            accId = [
                SELECT AccountId
                FROM Contact
                WHERE Id IN (
                    SELECT ContactId 
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                )
                LIMIT 1
            ].AccountId;
        }
        else {
            accId = [SELECT AccountId__c FROM User WHERE Id = :UserInfo.getUserId()][0].AccountId__c;
        }
        for (SObject obj: objects) {
            if (String.isBlank((String)obj.get('Account__c'))) {
                obj.put('Account__c', accId);
            }
        }
    }
}