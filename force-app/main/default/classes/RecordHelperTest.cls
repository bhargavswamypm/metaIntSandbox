@isTest
private class RecordHelperTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a Property__c record for testing
        // Note: Adjust field names according to your Property__c object definition
        Property__c testProperty = new Property__c(
            Name = 'Test Property'
            // Add other required fields here
        );
        insert testProperty;
        
        // Create an Account record for testing other object scenarios
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
    }
    
    @isTest
    static void testGetObjectApiName_Property() {
        // Test with Property__c record
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        
        Test.startTest();
        String objectName = RecordHelper.getObjectApiName(property.Id);
        Test.stopTest();
        
        System.assertEquals('Property__c', objectName, 
            'Object API name should be Property__c');
    }
    
    @isTest
    static void testGetObjectApiName_Account() {
        // Test with Account record
        Account account = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String objectName = RecordHelper.getObjectApiName(account.Id);
        Test.stopTest();
        
        System.assertEquals('Account', objectName, 
            'Object API name should be Account');
    }
    
    @isTest
    static void testGetObjectApiName_NullId() {
        // Test with null record Id
        Test.startTest();
        String objectName = RecordHelper.getObjectApiName(null);
        Test.stopTest();
        
        System.assertEquals(null, objectName, 
            'Object API name should be null for null input');
    }
    
    @isTest
    static void testGetObjectApiName_Contact() {
        // Test with Contact record
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;
        
        Test.startTest();
        String objectName = RecordHelper.getObjectApiName(testContact.Id);
        Test.stopTest();
        
        System.assertEquals('Contact', objectName, 
            'Object API name should be Contact');
    }
}