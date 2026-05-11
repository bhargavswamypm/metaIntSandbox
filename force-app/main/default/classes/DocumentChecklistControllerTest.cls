@isTest
private class DocumentChecklistControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        // Create test Property
        Property__c testProperty = new Property__c(
            Name = 'Test Property 123',
            Built_Up_Area__c = '1800',
            Asking_Price__c = 1010001,
            Accept_Terms__c = true,
            Accept_Terms_Rental__c = true
        );
        insert testProperty;

        // Create Property Documents - Multiple documents for Sale Deed
        List<Property_Document__c> docs = new List<Property_Document__c>{
            new Property_Document__c(Property__c = testProperty.Id, Document_Type__c = 'Sale Deed', Name = 'Sale_Deed_1.pdf'),
            new Property_Document__c(Property__c = testProperty.Id, Document_Type__c = 'Sale Deed', Name = 'Sale_Deed_2.pdf'),
            new Property_Document__c(Property__c = testProperty.Id, Document_Type__c = 'Agreement to Sell', Name = 'Agreement.pdf')
        };
        insert docs;

        // Create files & link them
        List<ContentVersion> cvList = new List<ContentVersion>{
            new ContentVersion(
                Title = 'Sale Deed File 1',
                PathOnClient = 'Sale_Deed_1.pdf',
                VersionData = Blob.valueOf('Sample content 1')
            ),
            new ContentVersion(
                Title = 'Sale Deed File 2',
                PathOnClient = 'Sale_Deed_2.pdf',
                VersionData = Blob.valueOf('Sample content 2')
            ),
            new ContentVersion(
                Title = 'Agreement File',
                PathOnClient = 'Agreement.pdf',
                VersionData = Blob.valueOf('Sample content 3')
            )
        };
        insert cvList;

        // Query to get ContentDocumentIds
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :cvList
        ];

        // Create ContentDocumentLinks
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = insertedCVs[0].ContentDocumentId,
                LinkedEntityId = docs[0].Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ),
            new ContentDocumentLink(
                ContentDocumentId = insertedCVs[1].ContentDocumentId,
                LinkedEntityId = docs[1].Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ),
            new ContentDocumentLink(
                ContentDocumentId = insertedCVs[2].ContentDocumentId,
                LinkedEntityId = docs[2].Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            )
        };
        insert cdlList;
    }
    
    @isTest
    static void testGetChecklistData_Success() {
        
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];

        // IMPORTANT — use FAKE FIELD API NAMES (valid SOQL)
        String fieldsCsv = 'Sale_Deed__c,Agreement_to_Sell__c,E_Khata__c';

        Test.startTest();
        List<Object> result = DocumentChecklistController.getChecklistData(prop.Id, fieldsCsv);
        Test.stopTest();

        List<Map<String, Object>> rows = (List<Map<String, Object>>) result[0];
        System.assertEquals(3, rows.size(), 'Expected 3 document types');

        // Map fake API → real document label
        Map<String, String> labelMap = new Map<String, String>{
            'Sale_Deed__c' => 'Sale Deed',
            'Agreement_to_Sell__c' => 'Agreement to Sell',
            'E_Khata__c' => 'E Khata'
        };

        Boolean foundSaleDeed = false;
        Boolean foundAgreement = false;
        Boolean foundKhata = false;

        for (Map<String, Object> r : rows) {
            String api = (String) r.get('apiName');
            String label = labelMap.get(api);

            if (label == 'Sale Deed') {
                foundSaleDeed = true;
                System.assertEquals(true, r.get('uploaded'), 'Sale Deed should be uploaded');
                System.assertNotEquals(null, r.get('propertyDocumentId'), 'Sale Deed should have property doc ID');
                System.assertNotEquals(null, r.get('contentDocumentId'), 'Sale Deed should have content doc ID');
                
                // TEST MULTIPLE DOCUMENTS - Should have 2 documents
                List<Object> documents = (List<Object>) r.get('documents');
                System.assertNotEquals(null, documents, 'Documents array should not be null');
                System.assertEquals(2, documents.size(), 'Sale Deed should have 2 documents');
                
                // Verify each document has required fields
                for (Object docObj : documents) {
                    Map<String, Object> doc = (Map<String, Object>) docObj;
                    System.assertNotEquals(null, doc.get('propertyDocumentId'), 'Document should have propertyDocumentId');
                    System.assertNotEquals(null, doc.get('contentDocumentId'), 'Document should have contentDocumentId');
                    System.assertNotEquals(null, doc.get('fileName'), 'Document should have fileName');
                }
            }
            if (label == 'Agreement to Sell') {
                foundAgreement = true;
                System.assertEquals(true, r.get('uploaded'), 'Agreement should be uploaded');
                System.assertNotEquals(null, r.get('propertyDocumentId'), 'Agreement should have property doc ID');
                System.assertNotEquals(null, r.get('contentDocumentId'), 'Agreement should have content doc ID');
                
                // Should have 1 document
                List<Object> documents = (List<Object>) r.get('documents');
                System.assertEquals(1, documents.size(), 'Agreement should have 1 document');
            }
            if (label == 'E Khata') {
                foundKhata = true;
                System.assertEquals(false, r.get('uploaded'), 'E Khata should not be uploaded');
                
                // Should have empty documents array
                List<Object> documents = (List<Object>) r.get('documents');
                System.assert(documents == null || documents.isEmpty(), 'E Khata should have no documents');
            }
        }

        System.assert(foundSaleDeed && foundAgreement && foundKhata, 'All document types should be found');
    }

    @isTest
    static void testGetChecklistData_EmptyCsv() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        
        Test.startTest();
        List<Object> res = DocumentChecklistController.getChecklistData(prop.Id, '');
        Test.stopTest();
        
        List<Map<String, Object>> rows = (List<Map<String, Object>>) res[0];
        System.assertEquals(0, rows.size(), 'Empty CSV should return 0 rows');
    }
    
    @isTest
    static void testGetChecklistData_NullPropertyId() {
        try {
            Test.startTest();
            DocumentChecklistController.getChecklistData(null, 'Sale_Deed__c');
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No Property Id'), 'Should throw proper error message');
        }
    }

    @isTest
    static void testUploadFile_Success() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        String data = EncodingUtil.base64Encode(Blob.valueOf('test upload'));

        Test.startTest();
        Map<String, String> res = DocumentChecklistController.uploadFile(
            prop.Id,
            'Agreement to Construct',
            data,
            'TestFile.pdf',
            'application/pdf'
        );
        Test.stopTest();

        System.assertEquals('true', res.get('success'), 'Upload should succeed');
        System.assertNotEquals(null, res.get('propertyDocumentId'), 'Should return property document ID');
        System.assertNotEquals(null, res.get('contentDocumentId'), 'Should return content document ID');
        System.assertEquals('TestFile.pdf', res.get('fileName'), 'Should return file name');
        
        // Verify the document was created
        List<Property_Document__c> docs = [
            SELECT Id, Name, Document_Type__c 
            FROM Property_Document__c 
            WHERE Property__c = :prop.Id 
            AND Document_Type__c = 'Agreement to Construct'
        ];
        System.assertEquals(1, docs.size(), 'Should create 1 property document');
        System.assertEquals('TestFile.pdf', docs[0].Name, 'Document name should match file name');
    }

    @isTest
    static void testUploadFile_MissingPropertyId() {
        Test.startTest();
        Map<String, String> res = DocumentChecklistController.uploadFile(
            null, 'Sale Deed', 'abc', 'file.pdf', 'application/pdf'
        );
        Test.stopTest();
        
        System.assertEquals('false', res.get('success'), 'Should fail without property ID');
        System.assert(res.get('error').contains('Missing Property Id'), 'Should have proper error message');
    }
    
    @isTest
    static void testUploadFile_MissingDocumentType() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        String data = EncodingUtil.base64Encode(Blob.valueOf('test'));
        
        Test.startTest();
        Map<String, String> res = DocumentChecklistController.uploadFile(
            prop.Id, '', data, 'file.pdf', 'application/pdf'
        );
        Test.stopTest();
        
        System.assertEquals('false', res.get('success'), 'Should fail without document type');
        System.assert(res.get('error').contains('Missing document type'), 'Should have proper error message');
    }

    @isTest
    static void testUploadFile_InvalidBase64() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        
        Test.startTest();
        Map<String, String> res = DocumentChecklistController.uploadFile(
            prop.Id, 'Sale Deed', 'INVALID_BASE64!!!', 'bad.pdf', 'application/pdf'
        );
        Test.stopTest();
        
        System.assertEquals('false', res.get('success'), 'Should fail with invalid base64');
        System.assertNotEquals(null, res.get('error'), 'Should have error message');
    }
    
    @isTest
    static void testDeletePropertyDocument_Success() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        
        // Get a document to delete
        Property_Document__c doc = [
            SELECT Id 
            FROM Property_Document__c 
            WHERE Property__c = :prop.Id 
            AND Document_Type__c = 'Sale Deed'
            LIMIT 1
        ];
        
        Test.startTest();
        DocumentChecklistController.deletePropertyDocument(doc.Id);
        Test.stopTest();
        
        // Verify deletion
        List<Property_Document__c> remainingDocs = [
            SELECT Id 
            FROM Property_Document__c 
            WHERE Id = :doc.Id
        ];
        System.assertEquals(0, remainingDocs.size(), 'Document should be deleted');
    }
    
    @isTest
    static void testDeletePropertyDocument_NullId() {
        try {
            Test.startTest();
            DocumentChecklistController.deletePropertyDocument(null);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No Property Document Id'), 'Should throw proper error message');
        }
    }
    
    @isTest
    static void testDeletePropertyDocument_InvalidId() {
        // Create a fake ID (not in database)
        Id fakeId = 'a00000000000000AAA';
        
        try {
            Test.startTest();
            DocumentChecklistController.deletePropertyDocument(fakeId);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Property Document not found'), 'Should throw proper error message');
        }
    }
    
    @isTest
    static void testMultipleUploadsForSameType() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        String data = EncodingUtil.base64Encode(Blob.valueOf('test upload'));

        Test.startTest();
        // Upload first file
        Map<String, String> res1 = DocumentChecklistController.uploadFile(
            prop.Id, 'E Khata', data, 'EKhata_1.pdf', 'application/pdf'
        );
        
        // Upload second file for same document type
        Map<String, String> res2 = DocumentChecklistController.uploadFile(
            prop.Id, 'E Khata', data, 'EKhata_2.pdf', 'application/pdf'
        );
        Test.stopTest();

        System.assertEquals('true', res1.get('success'), 'First upload should succeed');
        System.assertEquals('true', res2.get('success'), 'Second upload should succeed');
        
        // Verify both documents exist
        List<Property_Document__c> docs = [
            SELECT Id, Name 
            FROM Property_Document__c 
            WHERE Property__c = :prop.Id 
            AND Document_Type__c = 'E Khata'
        ];
        System.assertEquals(2, docs.size(), 'Should have 2 documents for E Khata');
        
        // Verify getChecklistData returns both
        List<Object> result = DocumentChecklistController.getChecklistData(
            prop.Id, 'E_Khata__c'
        );
        List<Map<String, Object>> rows = (List<Map<String, Object>>) result[0];
        List<Object> documents = (List<Object>) rows[0].get('documents');
        System.assertEquals(2, documents.size(), 'Should return 2 documents in array');
    }
}