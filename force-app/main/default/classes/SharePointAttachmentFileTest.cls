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
@isTest
private class SharePointAttachmentFileTest {

    static testMethod void testDeserialize() {
		String json = '{'+
		'    \"odata.metadata\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ApiData.Attachments/@Element\",'+
		'    \"odata.type\": \"SP.Attachment\",'+
		'    \"odata.id\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')\",'+
		'    \"odata.editLink\": \"Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')\",'+
		'    \"FileName\": \"Test_file_pd.pdf\",'+
		'    \"FileNameAsPath\": {'+
		'        \"DecodedUrl\": \"Test_file_pd.pdf\"'+
		'    },'+
		'    \"ServerRelativePath\": {'+
		'        \"DecodedUrl\": \"/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf\"'+
		'    },'+
		'    \"ServerRelativeUrl\": \"/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf\"'+
		'}';
		SharePointAttachmentFile objSharePointAttachmentFile = SharePointAttachmentFile.deserialize(json);

		System.assert(objSharePointAttachmentFile != null);
		System.assert(objSharePointAttachmentFile.odata_metadata == 'https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ApiData.Attachments/@Element');
		System.assert(objSharePointAttachmentFile.odata_type == 'SP.Attachment');
		System.assert(objSharePointAttachmentFile.odata_id == 'https://heroone.sharepoint.com/sites/FileManagementDEV/_api/Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')');
		System.assert(objSharePointAttachmentFile.odata_editLink == 'Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')');
		System.assert(objSharePointAttachmentFile.FileName == 'Test_file_pd.pdf');
		System.assert(objSharePointAttachmentFile.FileNameAsPath.DecodedUrl == 'Test_file_pd.pdf');
		System.assert(objSharePointAttachmentFile.ServerRelativePath.DecodedUrl == '/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf');
		System.assert(objSharePointAttachmentFile.ServerRelativeUrl == '/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf');
	}

    // static testMethod void testSerialize() {
    //     String json = '{'+
	// 	'    \"odata.metadata\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/$metadata#SP.ApiData.Attachments/@Element\",'+
	// 	'    \"odata.type\": \"SP.Attachment\",'+
	// 	'    \"odata.id\": \"https://heroone.sharepoint.com/sites/FileManagementDEV/_api/Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')\",'+
	// 	'    \"odata.editLink\": \"Web/Lists(guid\'6f206235-dcbe-4675-a848-b25899b62061\')/Items(191)/AttachmentFiles(\'Test_file_pd.pdf\')\",'+
	// 	'    \"FileName\": \"Test_file_pd.pdf\",'+
	// 	'    \"FileNameAsPath\": {'+
	// 	'        \"DecodedUrl\": \"Test_file_pd.pdf\"'+
	// 	'    },'+
	// 	'    \"ServerRelativePath\": {'+
	// 	'        \"DecodedUrl\": \"/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf\"'+
	// 	'    },'+
	// 	'    \"ServerRelativeUrl\": \"/sites/FileManagementDEV/Lists/Files/Attachments/191/Test_file_pd.pdf\"'+
	// 	'}';
	// 	SharePointAttachmentFile objSharePointAttachmentFile = SharePointAttachmentFile.deserialize(json);

    //     String jsonOut = SharePointAttachmentFile.serialize(objSharePointAttachmentFile);
    //     // Can't assert anything meaningful, strings won't be equal because order may vary
    // }
}