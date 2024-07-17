/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */

@IsTest
public class SharePointListItemTest {
	
	// This test method should give 100% coverage
	static testMethod void testDeserialize() {
		String json = '{'+
		'    \"odata.metadata\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ListData.FilesListItems/@Element\",'+
		'    \"odata.type\": \"SP.Data.FilesListItem\",'+
		'    \"odata.id\": \"cbe267b0-f26a-497a-9dbc-8d3655c73dff\",'+
		'    \"odata.etag\": \"\\\"1\\\"\",'+
		'    \"odata.editLink\": \"Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(1)\",'+
		'    \"FileSystemObjectType\": 0,'+
		'    \"Id\": 1,'+
		'    \"ServerRedirectedEmbedUri\": null,'+
		'    \"ServerRedirectedEmbedUrl\": \"\",'+
		'    \"ContentTypeId\": \"0x0100BAF9B07A88EA3141B2F52C2B3C744CDA00DF4807A5C7F3B04C8D936C7EFD2607EA\",'+
		'    \"Title\": null,'+
		'    \"ComplianceAssetId\": null,'+
		'    \"SystemId\": \"378b2fed-ad8a-ed11-9989-6045bd988ee3\",'+
		'    \"Status\": \"Active\",'+
		'    \"OData__ColorTag\": null,'+
		'    \"ID\": 1,'+
		'    \"Modified\": \"2023-02-08T12:14:26Z\",'+
		'    \"Created\": \"2023-02-08T12:14:26Z\",'+
		'    \"AuthorId\": 6,'+
		'    \"EditorId\": 6,'+
		'    \"OData__UIVersionString\": \"1.0\",'+
		'    \"Attachments\": false,'+
		'    \"GUID\": \"926592e2-5795-4780-bcff-ff63bd4e8f6e\"'+
		'}';
		SharePointListItem objSharePointListItem = SharePointListItem.deserialize(json);

		System.assert(objSharePointListItem != null);
		System.assert(objSharePointListItem.odata_metadata == 'https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ListData.FilesListItems/@Element');
		System.assert(objSharePointListItem.odata_type == 'SP.Data.FilesListItem');
		System.assert(objSharePointListItem.odata_id == 'cbe267b0-f26a-497a-9dbc-8d3655c73dff');
		System.assert(objSharePointListItem.odata_etag == '"1"');
		System.assert(objSharePointListItem.odata_editLink == 'Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(1)');
		System.assert(objSharePointListItem.FileSystemObjectType == 0);
		System.assert(objSharePointListItem.Id == 1);
		// System.assert(objSharePointListItem.ServerRedirectedEmbedUri == null);
		// System.assert(objSharePointListItem.ServerRedirectedEmbedUrl == '');
		System.assert(objSharePointListItem.ContentTypeId == '0x0100BAF9B07A88EA3141B2F52C2B3C744CDA00DF4807A5C7F3B04C8D936C7EFD2607EA');
		// System.assert(objSharePointListItem.Title == null);
		// System.assert(objSharePointListItem.ComplianceAssetId == null);
		System.assert(objSharePointListItem.SystemId == '378b2fed-ad8a-ed11-9989-6045bd988ee3');
		System.assert(objSharePointListItem.Status == 'Active');
		// System.assert(objSharePointListItem.OData_ColorTag == null);
		System.assert(objSharePointListItem.ID_cpy == 1);
		System.assert(objSharePointListItem.Modified == '2023-02-08T12:14:26Z');
		System.assert(objSharePointListItem.Created == '2023-02-08T12:14:26Z');
		System.assert(objSharePointListItem.AuthorId == 6);
		System.assert(objSharePointListItem.EditorId == 6);
		System.assert(objSharePointListItem.OData_UIVersionString == '1.0');
		System.assert(objSharePointListItem.Attachments == false);
		System.assert(objSharePointListItem.GUID == '926592e2-5795-4780-bcff-ff63bd4e8f6e');
	}

    // static testMethod void testSerialize() {
    //     String jsonIn = '{'+
	// 	'    \"odata.metadata\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ListData.FilesListItems/@Element\",'+
	// 	'    \"odata.type\": \"SP.Data.FilesListItem\",'+
	// 	'    \"odata.id\": \"cbe267b0-f26a-497a-9dbc-8d3655c73dff\",'+
	// 	'    \"odata.etag\": \"\\\"1\\\"\",'+
	// 	'    \"odata.editLink\": \"Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(1)\",'+
	// 	'    \"FileSystemObjectType\": 0,'+
	// 	'    \"Id\": 1,'+
	// 	'    \"ServerRedirectedEmbedUri\": null,'+
	// 	'    \"ServerRedirectedEmbedUrl\": \"\",'+
	// 	'    \"ContentTypeId\": \"0x0100BAF9B07A88EA3141B2F52C2B3C744CDA00DF4807A5C7F3B04C8D936C7EFD2607EA\",'+
	// 	'    \"Title\": null,'+
	// 	'    \"ComplianceAssetId\": null,'+
	// 	'    \"SystemId\": \"378b2fed-ad8a-ed11-9989-6045bd988ee3\",'+
	// 	'    \"Status\": \"Active\",'+
	// 	'    \"OData__ColorTag\": null,'+
	// 	'    \"ID\": 1,'+
	// 	'    \"Modified\": \"2023-02-08T12:14:26Z\",'+
	// 	'    \"Created\": \"2023-02-08T12:14:26Z\",'+
	// 	'    \"AuthorId\": 6,'+
	// 	'    \"EditorId\": 6,'+
	// 	'    \"OData__UIVersionString\": \"1.0\",'+
	// 	'    \"Attachments\": false,'+
	// 	'    \"GUID\": \"926592e2-5795-4780-bcff-ff63bd4e8f6e\"'+
	// 	'}';

    //     SharePointListItem r = SharePointListItem.deserialize(jsonIn);
    //     String jsonOut = SharePointListItem.serialize(r);
    //     // Can't assert anything meaningful, strings won't be equal because order may vary
    // }
}