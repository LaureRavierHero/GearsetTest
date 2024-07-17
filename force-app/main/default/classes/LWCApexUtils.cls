public with sharing class LWCApexUtils {
    @AuraEnabled
    public static Boolean isCommunityContext() {
        return (System.Site.getSiteId() != null);
    }
}