public with sharing class SharePointCallouts {
    class SharePointCalloutException extends Exception {}
    // {0} is site, {1} is list name. We get these from settings
    // {2} is item id, {3} is file name
    // Ex: /sites/FileManagementDEV/_api/web/lists/getbytitle(\'Files\')/items(191)/AttachmentFiles/add(FileName=\'Test_file_pd.pdf\')
    public static Map<String, String> endPoints = new Map<String, String>{
        'DossierObjectTaskAttachmentTemplate' => '/sites/{0}/_api/web/lists/getbytitle(\'\'{1}\'\')/items({2})/AttachmentFiles/add(FileName=\'\'{3}\'\')', 
        'DossierObjectFindItemByBCId' => '/sites/{0}/_api/web/lists/getbytitle(\'\'{1}\'\')/items'
    };

    @TestVisible
    private static Integer getSharePointId(String businessCentralId, SharePoint_connector_settings__mdt settings) {
        String endpoint = String.format(endPoints.get('DossierObjectFindItemByBCId'), new List<String>{settings.Site__c, settings.List__c, businessCentralId});

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SharePoint/' + EncodingUtil.urlEncode(endpoint, 'UTF-8') + '?$filter=' + EncodingUtil.urlEncode('SystemId eq \'' + businessCentralId + '\'', 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new SharePointCalloutException(res.getStatus() + ': ' + res.getBody());
        }
        else {
            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> n = (List<Object>)m.get('value');
            if (n.size() == 0) {
                throw new SharePointCalloutException('Could not find a SharePoint ListItem with SystemId ' + businessCentralId);
            }
            SharePointListItem item = SharePointListItem.deserialize(JSON.serialize(n[0]));
            return item.Id;
        }
    }

    /* Filename has to have file extension. File has to be base64 String */
    @AuraEnabled
    public static void postAttachmentFile(String businessCentralId, String fileName, String fileType, String file) {
        if (String.isBlank(fileName) || String.isBlank(fileType) || String.isBlank(file) || String.isBlank(businessCentralId)) {
            throw new SharePointCalloutException(String.format('Arguments cannot be empty or null file name: {0}, file type: {1}, SystemId: {3}', new List<String>{fileName, fileType, file, businessCentralId}));
        }

        SharePoint_connector_settings__mdt settings = [SELECT List__c, Site__c FROM SharePoint_connector_settings__mdt WHERE DeveloperName = 'SharePoint_dossier_items' LIMIT 1];

        Integer sharepointId = getSharePointId(businessCentralId, settings);
        String endpoint = String.format(endPoints.get('DossierObjectTaskAttachmentTemplate'), new List<String>{settings.Site__c, settings.List__c, String.valueOf(sharepointId), fileName});

        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:SharePoint/' + EncodingUtil.urlEncode(endpoint, 'UTF-8'));
        req.setMethod('POST');
        req.setHeader('Content-Type', fileType);
        req.setHeader('Accept', 'application/json');
        req.setBodyAsBlob(EncodingUtil.base64Decode(file));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            SharePointCalloutError err = SharePointCalloutError.deserialize(res.getBody());
            throw new SharePointCalloutException(err?.odata_error?.message?.value);
        }
        else {
            SharePointAttachmentFile spFile = SharePointAttachmentFile.deserialize(res.getBody());
            BusinessCentralCallouts.setUploadedAttachmentFile(businessCentralId,'https://heroone.sharepoint.com' + spFile.ServerRelativeUrl);
        }
    }
}