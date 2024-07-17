/* Class for parsing JSON of List Item from SharePoint. Ex:
{
    "odata.metadata": "https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ListData.FilesListItems/@Element",
    "odata.type": "SP.Data.FilesListItem",
    "odata.id": "cbe267b0-f26a-497a-9dbc-8d3655c73dff",
    "odata.etag": "\"1\"",
    "odata.editLink": "Web/Lists(guid'6f206235-dcbe-4675-a848-b25899b62061')/Items(1)",
    "FileSystemObjectType": 0,
    "Id": 1,
    "ServerRedirectedEmbedUri": null,
    "ServerRedirectedEmbedUrl": "",
    "ContentTypeId": "0x0100BAF9B07A88EA3141B2F52C2B3C744CDA00DF4807A5C7F3B04C8D936C7EFD2607EA",
    "Title": null,
    "ComplianceAssetId": null,
    "SystemId": "378b2fed-ad8a-ed11-9989-6045bd988ee3",
    "Status": "Active",
    "OData__ColorTag": null,
    "ID": 1,
    "Modified": "2023-02-08T12:14:26Z",
    "Created": "2023-02-08T12:14:26Z",
    "AuthorId": 6,
    "EditorId": 6,
    "OData__UIVersionString": "1.0",
    "Attachments": false,
    "GUID": "926592e2-5795-4780-bcff-ff63bd4e8f6e"
}
*/

public with sharing class SharePointListItem {
    public String odata_metadata {get;set;} // in json: odata.metadata
    public String odata_type {get;set;} // in json: odata.type
    public String odata_id {get;set;} // in json: odata.id
    public String odata_etag {get;set;} // in json: odata.etag
    public String odata_editLink {get;set;} // in json: odata.editLink
    public Integer FileSystemObjectType {get;set;} 
    public Integer Id {get;set;} 
    // public Object ServerRedirectedEmbedUri {get;set;} 
    public String ServerRedirectedEmbedUrl {get;set;} 
    public String ContentTypeId {get;set;} 
    // public Object Title {get;set;} 
    // public Object ComplianceAssetId {get;set;} 
    public String SystemId {get;set;} 
    public String Status {get;set;} 
    // public Object OData_ColorTag {get;set;}
    public Integer ID_cpy {get;set;}
    public String Modified {get;set;} 
    public String Created {get;set;} 
    public Integer AuthorId {get;set;} 
    public Integer EditorId {get;set;} 
    public String OData_UIVersionString {get;set;} 
    public Boolean Attachments {get;set;} 
    public String GUID {get;set;}

    public static Map<String, String> jsonPropertyByFieldName = new Map<String, String>{
        'odata_metadata' => 'odata.metadata',
        'odata_type' => 'odata.type',
        'odata_id' => 'odata.id',
        'odata_etag' => 'odata.etag',
        'odata_editLink' => 'odata.editLink',
        'OData_ColorTag' => 'OData__ColorTag',
        'OData_UIVersionString' => 'OData__UIVersionString',
        'ID_cpy' => 'ID'
    };

    public SharePointListItem(JSONParser parser) {
        while (parser.nextToken() != System.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                    if (text == 'odata.metadata') {
                        odata_metadata = parser.getText();
                    } else if (text == 'odata.type') {
                        odata_type = parser.getText();
                    } else if (text == 'odata.id') {
                        odata_id = parser.getText();
                    } else if (text == 'odata.etag') {
                        odata_etag = parser.getText();
                    } else if (text == 'odata.editLink') {
                        odata_editLink = parser.getText();
                    } else if (text == 'FileSystemObjectType') {
                        FileSystemObjectType = parser.getIntegerValue();
                    } else if (text.equals('Id')) {
                        Id = parser.getIntegerValue();
                    // } else if (text == 'ServerRedirectedEmbedUri') {
                    //     ServerRedirectedEmbedUri = parser.readValueAs(Object.class);
                    } else if (text == 'ServerRedirectedEmbedUrl') {
                        ServerRedirectedEmbedUrl = parser.getText();
                    } else if (text == 'ContentTypeId') {
                        ContentTypeId = parser.getText();
                    // } else if (text == 'Title') {
                    //     Title = parser.readValueAs(Object.class);
                    // } else if (text == 'ComplianceAssetId') {
                    //     ComplianceAssetId = parser.readValueAs(Object.class);
                    } else if (text == 'SystemId') {
                        SystemId = parser.getText();
                    } else if (text == 'Status') {
                        Status = parser.getText();
                    // } else if (text == 'OData__ColorTag') {
                    //     OData_ColorTag = parser.readValueAs(Object.class);
                    } else if (text.equals('ID')) {
                        System.debug('Set ID ' + parser.getIntegerValue());
                        ID_cpy = parser.getIntegerValue();
                    } else if (text == 'Modified') {
                        Modified = parser.getText();
                    } else if (text == 'Created') {
                        Created = parser.getText();
                    } else if (text == 'AuthorId') {
                        AuthorId = parser.getIntegerValue();
                    } else if (text == 'EditorId') {
                        EditorId = parser.getIntegerValue();
                    } else if (text == 'OData__UIVersionString') {
                        OData_UIVersionString = parser.getText();
                    } else if (text == 'Attachments') {
                        Attachments = parser.getBooleanValue();
                    } else if (text == 'GUID') {
                        GUID = parser.getText();
                    } else {
                        System.debug(LoggingLevel.WARN, 'SharePointListItem consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public static SharePointListItem deserialize(String json) {
        System.JSONParser parser = System.JSON.createParser(json);
        SharePointListItem spli = new SharePointListItem(parser);
        return spli;
    }

    // private static String sanitize(String JSON) {
    //     String res = JSON;

    //     for (String key: jsonPropertyByFieldName.keySet()) {
    //         res = res.replace(key, jsonPropertyByFieldName.get(key));
    //     }

    //     return res;
    // }

    // public static String serialize(SharePointListItem item) {
    //     String unsanitizedRes = JSON.serialize(item);
    //     String res = sanitize(unsanitizedRes);

    //     return res;
    // }
    
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT ||
                curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }
}