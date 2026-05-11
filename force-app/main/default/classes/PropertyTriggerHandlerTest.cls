@isTest
public class PropertyTriggerHandlerTest {
    
    // Setup method to create test data
    @testSetup
    static void setupTestData() {
        // Get Seller RecordType Id
        Id sellerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                                .get('Sellers').getRecordTypeId();
        
        // Create test contacts with different phone formats
        List<Contact> testContacts = new List<Contact>();
        
        Contact con1 = new Contact();
        con1.LastName = 'Test Contact 1';
        con1.Phone = '8296020419';
        con1.Email = 'test1@example.com';
        con1.RecordTypeId = sellerRecordTypeId;
        testContacts.add(con1);
        
        Contact con2 = new Contact();
        con2.LastName = 'Test Contact 2';
        con2.Phone = '9876543210';
        con2.Secondary_Phone__c = '9998887776';
        con2.Email = 'test2@example.com';
        con2.RecordTypeId = sellerRecordTypeId;
        testContacts.add(con2);
        
        Contact con3 = new Contact();
        con3.LastName = 'Test Contact 3';
        con3.Phone = '7778889990';
        con3.Email = 'test3@example.com';
        con3.RecordTypeId = sellerRecordTypeId;
        testContacts.add(con3);
        
        insert testContacts;
    }
    
    // Test 1: Matching existing contact by Phone (exact match)
    @isTest
    static void testPhoneMatchExact() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Phone = '8296020419' LIMIT 1];
        
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'New Owner';
        prop.OwnerPhoneNumber__c = '8296020419';
        prop.OwnerEmail__c = 'newemail@example.com';
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(existingContact.Id, insertedProp.Seller_Contact__c, 
                           'Should match existing contact by phone');
        
        // Verify no new contact was created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount, 'No new contact should be created');
    }
    
    // Test 2: Matching with different phone formats (country code variations)
    @isTest
    static void testPhoneMatchWithCountryCode() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Phone = '8296020419' LIMIT 1];
        
        List<Property__c> properties = new List<Property__c>();
        
        // Test with +91 prefix
        Property__c prop1 = new Property__c();
        prop1.OwnerName__c = 'Owner with +91';
        prop1.OwnerPhoneNumber__c = '+918296020419';
        prop1.Accept_Terms__c = true;
            prop1.Accept_Terms_Rental__c = true;
        properties.add(prop1);
        
        // Test with 91 prefix
        Property__c prop2 = new Property__c();
        prop2.OwnerName__c = 'Owner with 91';
        prop2.OwnerPhoneNumber__c = '918296020419';
        prop2.Accept_Terms__c = true;
            prop2.Accept_Terms_Rental__c = true;
        properties.add(prop2);
        
        // Test with spaces
        Property__c prop3 = new Property__c();
        prop3.OwnerName__c = 'Owner with spaces';
        prop3.OwnerPhoneNumber__c = '91 829 602 0419';
        prop3.Accept_Terms__c = true;
            prop3.Accept_Terms_Rental__c = true;
        properties.add(prop3);
        
        // Test with hyphens
        Property__c prop4 = new Property__c();
        prop4.OwnerName__c = 'Owner with hyphens';
        prop4.OwnerPhoneNumber__c = '+91-8296-020-419';
        prop4.Accept_Terms__c = true;
            prop4.Accept_Terms_Rental__c = true;
        properties.add(prop4);
        
        Test.startTest();
        insert properties;
        Test.stopTest();
        
        List<Property__c> insertedProps = [SELECT Id, Seller_Contact__c FROM Property__c];
        
        for(Property__c prop : insertedProps) {
            System.assertEquals(existingContact.Id, prop.Seller_Contact__c, 
                               'All phone format variations should match the same contact');
        }
        
        // Verify no new contacts were created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount, 'No new contacts should be created for format variations');
    }
    
    // Test 3: Matching by Secondary Phone
    @isTest
    static void testSecondaryPhoneMatch() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Secondary_Phone__c = '9998887776' LIMIT 1];
        
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Owner Secondary Phone';
        prop.OwnerPhoneNumber__c = '9998887776';
        prop.OwnerEmail__c = 'secondary@example.com';
     prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(existingContact.Id, insertedProp.Seller_Contact__c, 
                           'Should match existing contact by secondary phone');
        
        // Verify no new contact was created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount, 'No new contact should be created');
    }
    
    // Test 4: Matching by Email when phone doesn't match
    @isTest
    static void testEmailMatchWhenPhoneDoesntMatch() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Email = 'test1@example.com' LIMIT 1];
        
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Owner Email Match';
        prop.OwnerPhoneNumber__c = '1234567890'; // Different phone
        prop.OwnerEmail__c = 'test1@example.com'; // Matching email
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(existingContact.Id, insertedProp.Seller_Contact__c, 
                           'Should match existing contact by email when phone doesnt match');
        
        // Verify no new contact was created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount, 'No new contact should be created');
    }
    
    // Test 5: Email case-insensitive matching
    @isTest
    static void testEmailCaseInsensitiveMatch() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Email = 'test1@example.com' LIMIT 1];
        
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Owner Email Case';
        prop.OwnerPhoneNumber__c = '5555555555';
        prop.OwnerEmail__c = 'TEST1@EXAMPLE.COM'; // Different case
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(existingContact.Id, insertedProp.Seller_Contact__c, 
                           'Should match email case-insensitively');
    }
    
    // Test 6: Creating new contact when no match found
    @isTest
    static void testCreateNewContactWhenNoMatch() {
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Completely New Owner';
        prop.OwnerPhoneNumber__c = '5551234567';
        prop.OwnerEmail__c = 'newowner@example.com';
       prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertNotEquals(null, insertedProp.Seller_Contact__c, 
                              'Seller_Contact__c should be populated');
        
        // Verify new contact was created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(4, contactCount, 'A new contact should be created');
        
        // Verify the new contact details
        Contact newContact = [SELECT Id, LastName, Phone, Email FROM Contact 
                             WHERE Id = :insertedProp.Seller_Contact__c];
        System.assertEquals('Completely New Owner', newContact.LastName);
        System.assertEquals('5551234567', newContact.Phone);
        System.assertEquals('newowner@example.com', newContact.Email);
    }
    
    // Test 7: Creating contact with default name when OwnerName is blank
    @isTest
    static void testCreateContactWithDefaultName() {
        Property__c prop = new Property__c();
        // OwnerName__c is blank
        prop.OwnerPhoneNumber__c = '4445556666';
        prop.OwnerEmail__c = 'noname@example.com';
      prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        Contact newContact = [SELECT Id, LastName FROM Contact WHERE Id = :insertedProp.Seller_Contact__c];
        
        System.assertEquals('Unknown Owner', newContact.LastName, 
                           'Should use default name when OwnerName is blank');
    }
    
    // Test 8: Phone priority over email when both match different contacts
    @isTest
    static void testPhonePriorityOverEmail() {
        Contact phoneContact = [SELECT Id FROM Contact WHERE Phone = '8296020419' LIMIT 1];
        Contact emailContact = [SELECT Id FROM Contact WHERE Email = 'test2@example.com' LIMIT 1];
        
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Priority Test';
        prop.OwnerPhoneNumber__c = '8296020419'; // Matches phoneContact
        prop.OwnerEmail__c = 'test2@example.com'; // Matches emailContact
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(phoneContact.Id, insertedProp.Seller_Contact__c, 
                           'Phone should have priority over email');
    }
    
    // Test 9: Bulk insert test
    @isTest
    static void testBulkInsert() {
        List<Property__c> properties = new List<Property__c>();
        
        // 100 properties with matching contacts
        for(Integer i = 0; i < 100; i++) {
            Property__c prop = new Property__c();
            prop.OwnerName__c = 'Bulk Owner ' + i;
            prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
            prop.OwnerPhoneNumber__c = '8296020419'; // Existing contact
            properties.add(prop);
        }
        
        // 100 properties requiring new contacts
        for(Integer i = 0; i < 100; i++) {
            Property__c prop = new Property__c();
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
            prop.OwnerName__c = 'New Bulk Owner ' + i;
            prop.OwnerPhoneNumber__c = '6000000' + String.valueOf(i).leftPad(3, '0');
            prop.OwnerEmail__c = 'bulk' + i + '@example.com';
            properties.add(prop);
        }
        
        Test.startTest();
        insert properties;
        Test.stopTest();
        
        List<Property__c> insertedProps = [SELECT Id, Seller_Contact__c FROM Property__c];
        System.assertEquals(200, insertedProps.size());
        
        // All should have Seller_Contact__c populated
        for(Property__c prop : insertedProps) {
            System.assertNotEquals(null, prop.Seller_Contact__c);
        }
        
        // Should have 103 contacts (3 original + 100 new)
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(103, contactCount);
    }
    
    // Test 10: Update scenario - matching on update
    @isTest
    static void testUpdateScenario() {
        Contact existingContact = [SELECT Id FROM Contact WHERE Phone = '8296020419' LIMIT 1];
        
        // Create property without owner details
        Property__c prop = new Property__c();
        prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        insert prop;
        
        // Now update with owner details
        prop.OwnerName__c = 'Updated Owner';
        prop.OwnerPhoneNumber__c = '+918296020419';
        prop.OwnerEmail__c = 'updated@example.com';
        prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        update prop;
        Test.stopTest();
        
        Property__c updatedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(existingContact.Id, updatedProp.Seller_Contact__c, 
                           'Should match contact on update');
        
        // Verify no new contact was created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount);
    }
    
    // Test 11: Property without any owner details
    @isTest
    static void testPropertyWithoutOwnerDetails() {
        Property__c prop = new Property__c();
        // No owner details provided
        prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(null, insertedProp.Seller_Contact__c, 
                           'Seller_Contact__c should be null when no owner details provided');
        
        // No new contact should be created
        Integer contactCount = [SELECT COUNT() FROM Contact];
        System.assertEquals(3, contactCount);
    }
    
    // Test 12: Only phone provided (no email)
    @isTest
    static void testOnlyPhoneProvided() {
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Phone Only Owner';
        prop.OwnerPhoneNumber__c = '3331112222';
        // No email
        prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertNotEquals(null, insertedProp.Seller_Contact__c);
        
        Contact newContact = [SELECT Id, Phone, Email FROM Contact WHERE Id = :insertedProp.Seller_Contact__c];
        System.assertEquals('3331112222', newContact.Phone);
        System.assertEquals(null, newContact.Email);
    }
    
    // Test 13: Only email provided (no phone)
    @isTest
    static void testOnlyEmailProvided() {
        Property__c prop = new Property__c();
        prop.OwnerName__c = 'Email Only Owner';
        prop.OwnerEmail__c = 'emailonly@example.com';
        // No phone
         prop.Accept_Terms__c = true;
            prop.Accept_Terms_Rental__c = true;
        Test.startTest();
        insert prop;
        Test.stopTest();
        
        Property__c insertedProp = [SELECT Id, Seller_Contact__c FROM Property__c WHERE Id = :prop.Id];
        System.assertNotEquals(null, insertedProp.Seller_Contact__c);
        
        Contact newContact = [SELECT Id, Phone, Email FROM Contact WHERE Id = :insertedProp.Seller_Contact__c];
        System.assertEquals(null, newContact.Phone);
        System.assertEquals('emailonly@example.com', newContact.Email);
    }
}