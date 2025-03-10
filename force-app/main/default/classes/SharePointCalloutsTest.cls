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
public with sharing class SharePointCalloutsTest {
    private class SharePointMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Business_Central_connector_settings__mdt settings = [SELECT Company_id__c, Environment_name__c FROM Business_Central_connector_settings__mdt WHERE DeveloperName = 'Business_Central_dossier_items_settings' LIMIT 1];

            System.debug(req.getEndpoint());
            // getSharePointId
            if (req.getEndpoint().contains('?$filter=') && req.getEndpoint().contains('SystemId') && req.getMethod() == 'GET') {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"value": [{"Id":123}]}');
                res.setStatusCode(200);
                return res;
            }
            // postAttachmentFile
            else if (req.getEndpoint().contains('FileName') && req.getMethod() == 'POST') {
                System.debug('POST ATTACHMENT');
                HTTPResponse res = new HTTPResponse();
                res.setBody('{}');
                res.setStatusCode(200);
                return res;
            }
            else if (req.getEndpoint().contains('DossierObjectTasks') && req.getMethod() == 'PATCH') {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{}');
                res.setStatusCode(200);
                return res;
            } 
            else {
                System.debug('unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }

    @IsTest
    static void getSharePointIdTest() {
        Test.setMock(HttpCalloutMock.class, new SharePointMock());

        SharePoint_connector_settings__mdt settings = [SELECT List__c, Site__c FROM SharePoint_connector_settings__mdt WHERE DeveloperName = 'SharePoint_dossier_items' LIMIT 1];
        SharePointCallouts.getSharePointId('12345', settings);
    }

    @IsTest
    static void postAttachmentFile() {
        Test.setMock(HttpCalloutMock.class, new SharePointMock());

        SharePointCallouts.postAttachmentFile('12345', 'Test_file.pdf', 'application/pdf', 'base64string');
    }
}