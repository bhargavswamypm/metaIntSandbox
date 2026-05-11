@isTest
private class DocumentSlideshowControllerTest {
    
    @testSetup
    static void setup() {
        // Create test account (or any sObject you want to attach files to)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create ContentVersion (files)
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        // PDF file
        ContentVersion cvPdf = new ContentVersion(
            Title = 'Test PDF Document',
            PathOnClient = 'TestPDF.pdf',
            VersionData = Blob.valueOf('Test PDF Content'),
            IsMajorVersion = true
        );
        contentVersions.add(cvPdf);
        
        // Image file (PNG)
        ContentVersion cvImage = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'TestImage.png',
            VersionData = Blob.valueOf('Test Image Content'),
            IsMajorVersion = true
        );
        contentVersions.add(cvImage);
        
        // Word document
        ContentVersion cvWord = new ContentVersion(
            Title = 'Test Word Document',
            PathOnClient = 'TestDoc.docx',
            VersionData = Blob.valueOf('Test Word Content'),
            IsMajorVersion = true
        );
        contentVersions.add(cvWord);
        
        // Excel file
        ContentVersion cvExcel = new ContentVersion(
            Title = 'Test Excel',
            PathOnClient = 'TestExcel.xlsx',
            VersionData = Blob.valueOf('Test Excel Content'),
            IsMajorVersion = true
        );
        contentVersions.add(cvExcel);
        
        // Text file
        ContentVersion cvText = new ContentVersion(
            Title = 'Test Text File',
            PathOnClient = 'TestText.txt',
            VersionData = Blob.valueOf('Test Text Content'),
            IsMajorVersion = true
        );
        contentVersions.add(cvText);
        
        insert contentVersions;
        
        // Query ContentDocumentIds
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ];
        
        // Create ContentDocumentLinks to link files to the account
        List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = testAccount.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            cdLinks.add(cdl);
        }
        insert cdLinks;
    }
    
    @isTest
    static void testGetRelatedDocuments_Success() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Verify documents were retrieved
        System.assertNotEquals(null, documents, 'Documents list should not be null');
        System.assertEquals(5, documents.size(), 'Should retrieve 5 documents');
        
        // Verify document properties are populated
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            System.assertNotEquals(null, doc.contentDocumentId, 'Content Document ID should be populated');
            System.assertNotEquals(null, doc.title, 'Title should be populated');
            System.assertNotEquals(null, doc.fileExtension, 'File extension should be populated');
            System.assertNotEquals(null, doc.fileSize, 'File size should be populated');
            System.assertNotEquals(null, doc.downloadUrl, 'Download URL should be populated');
            System.assertNotEquals(null, doc.previewUrl, 'Preview URL should be populated');
            System.assertNotEquals(null, doc.iconName, 'Icon name should be populated');
        }
    }
    
    @isTest
    static void testGetRelatedDocuments_PDFDocument() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find PDF document
        DocumentSlideshowController.DocumentWrapper pdfDoc;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Test PDF Document') {
                pdfDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, pdfDoc, 'PDF document should be found');
        System.assertEquals('pdf', pdfDoc.fileExtension.toLowerCase(), 'Extension should be pdf');
        System.assertEquals('doctype:pdf', pdfDoc.iconName, 'Icon should be PDF icon');
        System.assert(pdfDoc.downloadUrl.contains('renditionDownload'), 'PDF should use rendition URL');
    }
    
    @isTest
    static void testGetRelatedDocuments_ImageDocument() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find image document
        DocumentSlideshowController.DocumentWrapper imageDoc;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Test Image') {
                imageDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, imageDoc, 'Image document should be found');
        System.assertEquals('png', imageDoc.fileExtension.toLowerCase(), 'Extension should be png');
        System.assertEquals('doctype:image', imageDoc.iconName, 'Icon should be image icon');
        System.assert(imageDoc.downloadUrl.contains('renditionDownload'), 'Image should use rendition URL');
    }
    
    @isTest
    static void testGetRelatedDocuments_WordDocument() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find Word document
        DocumentSlideshowController.DocumentWrapper wordDoc;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Test Word Document') {
                wordDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, wordDoc, 'Word document should be found');
        System.assertEquals('docx', wordDoc.fileExtension.toLowerCase(), 'Extension should be docx');
        System.assertEquals('doctype:word', wordDoc.iconName, 'Icon should be Word icon');
        System.assert(wordDoc.downloadUrl.contains('document/download'), 'Word doc should use download URL');
    }
    
    @isTest
    static void testGetRelatedDocuments_ExcelDocument() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find Excel document
        DocumentSlideshowController.DocumentWrapper excelDoc;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Test Excel') {
                excelDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, excelDoc, 'Excel document should be found');
        System.assertEquals('xlsx', excelDoc.fileExtension.toLowerCase(), 'Extension should be xlsx');
        System.assertEquals('doctype:excel', excelDoc.iconName, 'Icon should be Excel icon');
    }
    
    @isTest
    static void testGetRelatedDocuments_TextDocument() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find Text document
        DocumentSlideshowController.DocumentWrapper textDoc;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Test Text File') {
                textDoc = doc;
                break;
            }
        }
        
        System.assertNotEquals(null, textDoc, 'Text document should be found');
        System.assertEquals('txt', textDoc.fileExtension.toLowerCase(), 'Extension should be txt');
        System.assertEquals('doctype:txt', textDoc.iconName, 'Icon should be text icon');
    }
    
    @isTest
    static void testGetRelatedDocuments_NoDocuments() {
        // Create account with no documents
        Account emptyAccount = new Account(Name = 'Empty Account');
        insert emptyAccount;
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(emptyAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, documents, 'Documents list should not be null');
        System.assertEquals(0, documents.size(), 'Should retrieve 0 documents for account with no files');
    }
    
    @isTest
    static void testGetRelatedDocuments_InvalidRecordId() {
        // Use invalid record ID
        String invalidId = '001000000000000AAA';
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(invalidId);
        Test.stopTest();
        
        // Should return empty list, not throw exception
        System.assertNotEquals(null, documents, 'Documents list should not be null');
        System.assertEquals(0, documents.size(), 'Should return empty list for invalid ID');
    }
    
    @isTest
    static void testGetRelatedDocuments_NullRecordId() {
        Test.startTest();
        try {
            List<DocumentSlideshowController.DocumentWrapper> documents = 
                DocumentSlideshowController.getRelatedDocuments(null);
            
            // Should return empty list
            System.assertNotEquals(null, documents, 'Documents list should not be null');
            System.assertEquals(0, documents.size(), 'Should return empty list for null ID');
        } catch (Exception e) {
            // Exception is acceptable for null input
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFormatFileSize_Bytes() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Create small file (less than 1KB)
        ContentVersion cvSmall = new ContentVersion(
            Title = 'Small File',
            PathOnClient = 'small.txt',
            VersionData = Blob.valueOf('X'), // 1 byte
            IsMajorVersion = true
        );
        insert cvSmall;
        
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvSmall.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Find the small file
        Boolean foundSmallFile = false;
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            if (doc.title == 'Small File') {
                foundSmallFile = true;
                System.assert(doc.fileSize.contains('B'), 'File size should be in bytes');
            }
        }
        System.assert(foundSmallFile, 'Small file should be found');
    }
    
    @isTest
    static void testGetIconName_AllTypes() {
        // This tests the icon mapping logic indirectly through document retrieval
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Verify different icon types are assigned
        Set<String> iconTypes = new Set<String>();
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            iconTypes.add(doc.iconName);
        }
        
        // Should have at least 4 different icon types from our test data
        System.assert(iconTypes.size() >= 4, 'Should have multiple icon types: ' + iconTypes);
        System.assert(iconTypes.contains('doctype:pdf'), 'Should have PDF icon');
        System.assert(iconTypes.contains('doctype:image'), 'Should have image icon');
        System.assert(iconTypes.contains('doctype:word'), 'Should have Word icon');
    }
    
    @isTest
    static void testDocumentWrapper_Properties() {
        // Test the DocumentWrapper class properties
        DocumentSlideshowController.DocumentWrapper wrapper = new DocumentSlideshowController.DocumentWrapper();
        
        // Set properties
        wrapper.contentDocumentId = '069000000000001';
        wrapper.title = 'Test Title';
        wrapper.fileType = 'PDF';
        wrapper.fileExtension = 'pdf';
        wrapper.fileSize = '1 MB';
        wrapper.createdDate = DateTime.now();
        wrapper.downloadUrl = '/test/download';
        wrapper.previewUrl = '/test/preview';
        wrapper.iconName = 'doctype:pdf';
        
        // Verify properties
        System.assertEquals('069000000000001', wrapper.contentDocumentId);
        System.assertEquals('Test Title', wrapper.title);
        System.assertEquals('PDF', wrapper.fileType);
        System.assertEquals('pdf', wrapper.fileExtension);
        System.assertEquals('1 MB', wrapper.fileSize);
        System.assertNotEquals(null, wrapper.createdDate);
        System.assertEquals('/test/download', wrapper.downloadUrl);
        System.assertEquals('/test/preview', wrapper.previewUrl);
        System.assertEquals('doctype:pdf', wrapper.iconName);
    }
    
    @isTest
    static void testGetRelatedDocuments_MultipleFileTypes() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Count different file types
        Map<String, Integer> fileTypeCounts = new Map<String, Integer>();
        for (DocumentSlideshowController.DocumentWrapper doc : documents) {
            String ext = doc.fileExtension.toLowerCase();
            if (!fileTypeCounts.containsKey(ext)) {
                fileTypeCounts.put(ext, 0);
            }
            fileTypeCounts.put(ext, fileTypeCounts.get(ext) + 1);
        }
        
        // Verify we have multiple types
        System.assert(fileTypeCounts.size() >= 4, 'Should have at least 4 different file types');
        System.assertEquals(1, fileTypeCounts.get('pdf'), 'Should have 1 PDF');
        System.assertEquals(1, fileTypeCounts.get('png'), 'Should have 1 PNG');
        System.assertEquals(1, fileTypeCounts.get('docx'), 'Should have 1 DOCX');
    }
    
    @isTest
    static void testGetRelatedDocuments_SortedByCreatedDate() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<DocumentSlideshowController.DocumentWrapper> documents = 
            DocumentSlideshowController.getRelatedDocuments(testAccount.Id);
        Test.stopTest();
        
        // Verify documents are sorted by created date (ascending)
        if (documents.size() > 1) {
            for (Integer i = 0; i < documents.size() - 1; i++) {
                DateTime currentDate = documents[i].createdDate;
                DateTime nextDate = documents[i + 1].createdDate;
                System.assert(
                    currentDate <= nextDate, 
                    'Documents should be sorted by created date ascending'
                );
            }
        }
    }
}