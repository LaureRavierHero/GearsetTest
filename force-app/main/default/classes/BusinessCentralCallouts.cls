public with sharing class BusinessCentralCallouts {
    // https://api.businesscentral.dynamics.com/v2.0/DEV/api/hero/hero/v1.0
    // /companies(18eef3e4-cf6f-ed11-8c34-000d3a23ee52)/DossierObjectTasks(58d52747-6b8b-ed11-9989-000d3a2f8a53)

    /* 
        0 = Environment
        1 = company id
        2 = object task id
    */
    class BusinessCentralCalloutException extends Exception {}

    public static String baseUrlTemplate = '/{0}/api/hero/hero/v1.0/companies({1})/';

    public static Map<String, String> patchEndPoints = new Map<String, String>{
        // 0 = Id
        'DossierObjectTask' => 'DossierObjectTasks({0})/'
    };

    class DossierTask {
        String TaskStatus = 'Review';
        String ResultFileUrl {get; set; }
        String Comment {get; set;}
    }

    public static void setUploadedAttachmentFile(String itemId, String fileUrl) {
        /* Set item's attachment URL and update status */
        if (String.isBlank(itemId) || String.isBlank(fileUrl)) {
            throw new BusinessCentralCalloutException(String.format('Arguments cannot be empty or null file name: {0}, file type: {1}', new List<String>{itemId, fileUrl}));
        }

        Business_Central_connector_settings__mdt settings = [SELECT Company_id__c, Environment_name__c FROM Business_Central_connector_settings__mdt WHERE DeveloperName = 'Business_Central_dossier_items_settings' LIMIT 1];

        String baseUrl = String.format(baseUrlTemplate, new List<String>{settings.Environment_name__c, settings.Company_id__c});
        String endpoint = baseUrl + String.format(patchEndPoints.get('DossierObjectTask'), new List<String>{itemId});

        DossierTask task = new DossierTask();
        task.ResultFileUrl = fileUrl;
        task.Comment = 'Submitted by ' + UserInfo.getUserName();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:BusinessCentral/' + endpoint);
        req.setMethod('PATCH');
        req.setHeader('If-Match', '*');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');

        String body = JSON.serialize(task);

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new BusinessCentralCalloutException(res.getStatus() + ': ' + res.getBody());
        }
    }
}