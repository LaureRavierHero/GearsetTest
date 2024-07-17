public with sharing class PortalButtonVisibilityEvaluator {
    public class PortalButtonVisibilityEvaluatorException extends Exception {}

    private static Boolean evaluateCondition(String value, String expectedValue, String operator) {
        System.debug('Evaluate condition ' + value + ' ' + operator + ' ' + expectedValue);
        Boolean result = false;
        switch on operator {
            when 'in' {
                List<String> expectedValues = expectedValue.split(',');
                result = expectedValues.contains(value);
            }
            when 'equals'{
                result = (value == expectedValue);
            }
            when 'not equals' {
                result = !(value == expectedValue);
            }
            when 'is blank' {
                result = String.isBlank(value);
            }
            when 'is not blank' {
                result = String.isNotBlank(value);
            }
            when else {
                throw new PortalButtonVisibilityEvaluatorException('Unexpected operator ' + operator + '. Could not determine truth value.');
            }
        }

        System.debug(' is: ' + result);
        return result;
    }

    private static Boolean evaluateCriterium(String objectName, SObject record, Criterium__mdt criterium) {
        String operator = criterium.Condition__c;
        String value;
        String expectedValue = criterium.Value__c;

        System.debug('expected value ' + criterium.Value__c);
        System.debug('Operator ' + operator);

        if (criterium.Type__c == 'Record type') {
            value = SchemaUtils.getRecordTypeName(objectName, (Id)record.get('RecordTypeId'));
            System.debug('Value ' + value);
        }
        else if (criterium.Type__c == 'Field value') {
            value = DeveloperUtils.getFieldValueAsString(record, criterium.Field__c);
            System.debug('value ' + value);
        }

        return evaluateCondition(value, expectedValue, operator);
    }

    /* This does NOT work if the highest filter number is greater than 9, since we will introduce substitution errors */
    public static Boolean evaluateFilterLogic(String filterLogic, Map<Integer, Boolean> truthByConditionNumber) {
        String logic = filterLogic;

        System.debug('TRUTH BY CONDITION ' + truthByConditionNumber);
        // If no logic is specified, all conditions need to be true
        if (String.isBlank(logic)) {
            Set<Integer> s = truthByConditionNumber.keySet();
            Set<String> b = new Set<String>();
            for (Integer n: truthByConditionNumber.keySet()) {
                b.add(String.valueOf(n));
            }

            logic = String.join(b, ' AND ');
        }

        String res = logic;
        for (Integer n: truthByConditionNumber.keySet()) {
            res = res.replace(String.valueOf(n), truthByConditionNumber.get(n)? 'true' : 'false');
        }

        res = res.replace('true', '1');
        res = res.replace('false', '0');
        System.debug('TOKENIZED: ' + res);
        return FilterLogicEvaluator.evaluate(res);
    }

    /* Evaluates all filters, check whether there is any filter logic (of not just returns whether all filters are true).
    If there is filter logic, we substitute the corresponding truth values from the filters into it, then evaluate it Boolean value. */
    public static Boolean evaluateFilters(Id userId, String objectName, String filterLogic, List<Portal_button_filter__mdt> filters, SObject record) {
        Map<Integer, Boolean> truthByFilterNumber = new Map<Integer, Boolean>();

        for (Portal_button_filter__mdt filter: filters) {
            System.debug('FILTER NUMBER: ' + filter.Number__c);
            Integer ind = (Integer)filter.Number__c;
            if (truthByFilterNumber.get(ind) != null) {
                throw new PortalButtonVisibilityEvaluatorException('Number used for multiple filters (must be unique): ' + String.valueOf(ind));
            }

            truthByFilterNumber.put(ind, evaluateCriterium(objectName, record, filter.Criterium__r));
        }

        return evaluateFilterLogic(filterLogic, truthByFilterNumber);
    }

    /* Evaluates whether user is valid submitter for record to specified approval process */
    public static Boolean evaluateApprovalSubmitter(List<Portal_button_approval_submitter__mdt> validApprovalSubmitters, Id userId, 
    SObject record, List<Group> userGroups) {
        User u = [SELECT UserRole.Name FROM User WHERE Id = :userId];
        Set<String> userGroupNames = null;

        if (userGroups != null) {
            userGroupNames = DeveloperUtils.getStringFieldSet(userGroups, 'Name');
        }
        String userRole = u.UserRole.Name;

        for (Portal_button_approval_submitter__mdt approver: validApprovalSubmitters) {
            String approvalSubmissionRuleType = approver.Type__c;

            switch on approvalSubmissionRuleType {
                when 'Record owner' {
                    if (((Id)record.get('OwnerId') == userId)) return true;
                }
                when 'Record creator' {
                    if (((Id)record.get('CreatedById') == userId)) return true;
                }
                when 'Role' {
                    if (((String)record.get('Role_name__c') == userRole)) return true;
                }
                when 'Public group' {
                    if (userGroups == null)
                        return false;
                    if ((userGroupNames.contains((String)record.get('Group_name__c')))) return true;
                }
                when else {
                    throw new PortalButtonVisibilityEvaluatorException('Unexpected type on Portal_button_approval_submitter__mdt ' + validApprovalSubmitters);
                }
            }
        }

        return false;
    }
}