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
private class SharePointCalloutErrorTest {
    static testMethod void testParse() {
		String json = '{\"odata.error\":{\"code\":\"-2130575257, Microsoft.SharePoint.SPException\",\"message\":{\"lang\":\"nl-NL\",\"value\":\"De opgegeven naam wordt al gebruikt.\\n\\n. De naam van het document of de map is niet gewijzigd. Als u de naam wilt wijzigen in een andere waarde, sluit u dit dialoogvenster en bewerkt u de eigenschappen van het document of de map.\"}}}';
		SharePointCalloutError r = SharePointCalloutError.deserialize(json);
		System.assert(r != null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		SharePointCalloutError.Message objMessage = new SharePointCalloutError.Message(System.JSON.createParser(json));
		System.assert(objMessage != null);
		System.assert(objMessage.lang == null);
		System.assert(objMessage.value == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		SharePointCalloutError.Odata_error objOdata_error = new SharePointCalloutError.Odata_error(System.JSON.createParser(json));
		System.assert(objOdata_error != null);
		System.assert(objOdata_error.code == null);
		System.assert(objOdata_error.message == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		SharePointCalloutError objSharePointCalloutError = new SharePointCalloutError(System.JSON.createParser(json));
		System.assert(objSharePointCalloutError != null);
		System.assert(objSharePointCalloutError.odata_error == null);
	}
}