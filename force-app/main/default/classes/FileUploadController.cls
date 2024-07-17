public without sharing class FileUploadController {
    // public class FileDescription {
    //     @AuraEnabled
    //     public String fileName {get; set; }
    //     @AuraEnabled
    //     public String fileContent {get; set; } // base64 string
    //     @AuraEnabled
    //     public String fileUrl {get; set; }

    //     FileDescription(String name, String content) {
    //         fileName = name;
    //         fileContent = content;
    //     }

    //     public FileDescription() {}
    // }

    public class FileDescription {
        @AuraEnabled
        public String name {get; set; }
        @AuraEnabled
        public Id documentId {get; set; } // base64 string

        FileDescription(String nm, Id docId) {
            name = nm;
            documentId = docId;
        }

        public FileDescription() {}
    }

    @AuraEnabled
    public static void saveFile(String fileContent, String fileName, Id associatedRecordId) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(fileContent);
            cv.Title = fileName;
            cv.ContentLocation= 's';
            cv.PathOnClient = fileName;
            
            insert cv;

            ContentVersion cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = associatedRecordId;
            cdl.ContentDocumentId = cd.ContentDocumentId;
            cdl.ShareType = 'I';

            insert cdl;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveFiles(Id associatedRecordId, List<Id> contentDocumentIds) {
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (Id cdId: contentDocumentIds) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = associatedRecordId;
            link.ContentDocumentId = cdId;

            cdls.add(link);
        }

        insert cdls;
    }


    @AuraEnabled(cacheable=true)
    public static List<FileDescription> getFiles(Id recordId) {
        if (String.isBlank(recordId)) {
            System.debug('NO RECORD ID');
            return null;
        }
        System.debug('RECORDID ' + recordId);
        List<FileDescription> fds = new List<FileDescription>();

        List<ContentDocumentLink> cdl = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
        ];

        if (cdl == null || cdl.size() == 0) {
            return fds;
        }
        
        Set<Id> contentDocumentIds = DeveloperUtils.getIdFieldSet(cdl, 'ContentDocumentId');
        
        List<ContentDocument> cds = [
            SELECT Id , Title
            FROM ContentDocument 
            WHERE Id 
            IN :contentDocumentIds
        ];

        for (ContentDocument cd: cds) {
            fds.add(new FileDescription(cd.Title, cd.Id));
        }

        return fds;
    }

    @AuraEnabled
    public static void removeFile(Id contentDocumentId){
        System.debug('Document id: ' + contentDocumentId);
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id =: contentDocumentId];

        delete cd;
    }

    @AuraEnabled
    public static void uploadFiles(Id recordId, List<Id> contentDocumentIds) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();

        for (Id docId: contentDocumentIds) {
            ContentDocumentLink link = new ContentDocumentLink();

            link.LinkedEntityId = recordId;
            link.ContentDocumentId = docId;

            links.add(link);
        }

        System.debug('LINKS: ' + links);
        if (links.size() != 0) {
            insert links;
        }
    }
}