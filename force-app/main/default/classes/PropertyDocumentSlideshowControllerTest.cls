@isTest
public class PropertyDocumentSlideshowControllerTest {

    @testSetup
    static void setupTestData() {

        // Create a Property
        Property__c prop = new Property__c(
            Name = 'Test Property',
            Built_Up_Area__c = '1800',
            Asking_Price__c = 1010001
        );
        insert prop;

        // Create 2 Property Document records
        List<Property_Document__c> pDocs = new List<Property_Document__c>{
            new Property_Document__c(Name='SaleDeed.pdf', Property__c = prop.Id, Document_Type__c = 'Sale Deed'),
            new Property_Document__c(Name='PropertyImage.png', Property__c = prop.Id, Document_Type__c = 'Property Images')
        };
        insert pDocs;

        // Create ContentVersions
        List<ContentVersion> versions = new List<ContentVersion>{
            new ContentVersion(
                Title = 'SaleDeed',
                PathOnClient = 'SaleDeed.pdf',
                VersionData = Blob.valueOf('PDF content')
            ),
            new ContentVersion(
                Title = 'Property Images',
                PathOnClient = 'Image.png',
                VersionData = Blob.valueOf('PNG content')
            )
        };
        insert versions;

        // Retrieve actual ContentDocument IDs
        versions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :versions
        ];

        // Link SaleDeed.pdf
        insert new ContentDocumentLink(
            ContentDocumentId = versions[0].ContentDocumentId,
            LinkedEntityId    = pDocs[0].Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );

        // Link PropertyImage.png
        insert new ContentDocumentLink(
            ContentDocumentId = versions[1].ContentDocumentId,
            LinkedEntityId    = pDocs[1].Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
    }

    // ---------------------------------------------------------
    // TEST 1 – Fetch Property Documents
    // ---------------------------------------------------------
    @isTest
    static void testGetPropertyDocuments() {

        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];

        Test.startTest();
        List<PropertyDocumentSlideshowController.DocumentWrapper> result =
            PropertyDocumentSlideshowController.getPropertyDocuments(prop.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 documents');

        // Manual find (NO STREAMS)
        PropertyDocumentSlideshowController.DocumentWrapper pdfDoc = null;
        PropertyDocumentSlideshowController.DocumentWrapper pngDoc = null;

        for (PropertyDocumentSlideshowController.DocumentWrapper d : result) {

            System.assertNotEquals(null, d.contentDocumentId);
            System.assertNotEquals(null, d.title);
            System.assertNotEquals(null, d.fileExtension);
            System.assertNotEquals(null, d.fileType);
            System.assertNotEquals(null, d.fileSize);
            System.assertNotEquals(null, d.createdDate);
            System.assertNotEquals(null, d.downloadUrl);
            System.assertNotEquals(null, d.previewUrl);
            System.assertNotEquals(null, d.iconName);

            if (d.fileExtension != null && d.fileExtension.toLowerCase() == 'pdf') {
                pdfDoc = d;
            }
            if (d.fileExtension != null && d.fileExtension.toLowerCase() == 'png') {
                pngDoc = d;
            }
        }

        // Validate PDF doc
        System.assertNotEquals(null, pdfDoc, 'PDF doc must exist');
        System.assert(pdfDoc.downloadUrl.contains('renditionDownload'),
            'PDF should use preview rendition');
        System.assertEquals('doctype:pdf', pdfDoc.iconName);

        // Validate PNG doc
        System.assertNotEquals(null, pngDoc, 'PNG doc must exist');
        System.assert(pngDoc.downloadUrl.contains('renditionDownload'),
            'Image should use preview rendition');
        System.assertEquals('doctype:image', pngDoc.iconName);
    }

    // ---------------------------------------------------------
    // TEST 2 – Property with NO documents
    // ---------------------------------------------------------
    @isTest
    static void testNoDocuments() {

        Property__c emptyProp = new Property__c(
            Name = 'Empty Prop',
            Built_Up_Area__c = '1000',
            Asking_Price__c = 500000
        );
        insert emptyProp;

        Test.startTest();
        List<PropertyDocumentSlideshowController.DocumentWrapper> result =
            PropertyDocumentSlideshowController.getPropertyDocuments(emptyProp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(),
            'Should return empty list when property has no documents');
    }

}