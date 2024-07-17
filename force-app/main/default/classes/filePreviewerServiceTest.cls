@IsTest
private class filePreviewerServiceTest{
    @IsTest
    static void testGetContentDetails() {
        // Create a test Account to link ContentDocumentLink
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test ContentDocument by inserting a ContentVersion
        ContentVersion testVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'Test Document.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
        insert testVersion;
        
        // Retrieve the ContentDocumentId from the ContentVersion
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testVersion.Id LIMIT 1];

        // Create a test ContentDocumentLink
        ContentDocumentLink testDocumentLink = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'I' // 'I' for 'Inferred permission'
        );
        insert testDocumentLink;

        // Test the getContentDetails method
        Test.startTest();
        String result = filePreviewerService.getContentDetails(testAccount.Id);
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains(insertedVersion.ContentDocumentId), 'Result should contain the ContentDocumentId');
        System.assert(result.contains(testVersion.Id), 'Result should contain the ContentVersionId');
    }
}