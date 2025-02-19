public with sharing class filePreviewerService {
    
    @AuraEnabled
    public static String getContentDetails(String recordId) {
        List<ContentDocumentLink> contentDocumentList = [SELECT ContentDocumentId, LinkedEntityId 
                                                            FROM   ContentDocumentLink 
                                                            WHERE  LinkedEntityId =: recordId];
        Set<Id> contentDocumentId = new Set<Id>();
            
        for(ContentDocumentLink cdl : contentDocumentList){
            contentDocumentId.add(cdl.ContentDocumentId);
        }
            
        List<ContentVersion> contentVersionList = [SELECT Id, VersionData, FileType, Title, FileExtension,
                                                    ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,
                                                    CreatedDate, ContentDocumentId, ContentDocument.FileType
                                                    FROM   ContentVersion 
                                                    WHERE  ContentDocumentId IN : contentDocumentId];
        return JSON.serialize(contentVersionList);
    }
}