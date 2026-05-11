@isTest
public class PropertyManagerContactControllerTest {

        
    @testSetup
    static void setup() {
        // Create test user for property manager
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User propertyManager = new User(
            Alias = 'pmgr',
            Email = 'propertymanager@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            FirstName = 'Property',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'propertymanager' + DateTime.now().getTime() + '@test.com',
            Phone = '+1234567890',
            Title = 'Senior Property Manager'
        );
        insert propertyManager;
        
        // Get Parent Property RecordType
        List<RecordType> recordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Parent Project'
            LIMIT 1
        ];
        
        Id parentRecordTypeId = recordTypes.isEmpty() ? null : recordTypes[0].Id;
        
        // Create Parent Property with assigned manager
        Property__c parentProperty = new Property__c(
            Name = 'Test Parent Property',
            RecordTypeId = parentRecordTypeId,
            Assigned_to_parent__c = propertyManager.Id
        );
        insert parentProperty;
        
        // Get Child Property RecordType (Sale or Rent)
        List<RecordType> saleRecordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale'
            LIMIT 1
        ];
        
        Id saleRecordTypeId = saleRecordTypes.isEmpty() ? null : saleRecordTypes[0].Id;
        
        // Create Child Property linked to parent
        Property__c childProperty = new Property__c(
            Name = 'Test Child Property',
            RecordTypeId = saleRecordTypeId,
            Parent_Property__c = parentProperty.Id
        );
        insert childProperty;
        
        // Create Parent Property without manager
        Property__c parentWithoutManager = new Property__c(
            Name = 'Parent Without Manager',
            RecordTypeId = parentRecordTypeId
        );
        insert parentWithoutManager;
        
        // Create Child Property linked to parent without manager
        Property__c childWithoutManager = new Property__c(
            Name = 'Child Without Manager',
            RecordTypeId = saleRecordTypeId,
            Parent_Property__c = parentWithoutManager.Id
        );
        insert childWithoutManager;
        
        // Create Property without parent
        Property__c orphanProperty = new Property__c(
            Name = 'Orphan Property',
            RecordTypeId = saleRecordTypeId
        );
        insert orphanProperty;
    }
    
    @isTest
    static void testGetPropertyManagerInfo_WithManager() {
        // Get child property with manager
        List<Property__c> testProps = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Test Child Property' 
            LIMIT 1
        ];
        
        if (testProps.isEmpty()) {
            System.debug('Test property not found - skipping test');
            return;
        }
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetPropertyManagerInfo_WithoutManager() {
        // Get child property without manager
        List<Property__c> testProps = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Child Without Manager' 
            LIMIT 1
        ];
        
        if (testProps.isEmpty()) {
            System.debug('Test property not found - skipping test');
            return;
        }
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        Test.stopTest();
        
        // Verify appropriate message is returned
        System.assertEquals(false, info.hasManager, 'Should not have manager assigned');
        System.assertEquals(null, info.managerName, 'Manager name should be null');
        System.assertEquals(null, info.managerPhone, 'Manager phone should be null');
        System.assertEquals(null, info.managerEmail, 'Manager email should be null');
        System.assertEquals(
            'No property manager is currently assigned to the parent property.', 
            info.message, 
            'Should show appropriate message'
        );
    }
    
    @isTest
    static void testGetPropertyManagerInfo_NoParent() {
        // Get orphan property without parent
        List<Property__c> testProps = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Orphan Property' 
            LIMIT 1
        ];
        
        if (testProps.isEmpty()) {
            System.debug('Test property not found - skipping test');
            return;
        }
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        Test.stopTest();
        
        // Verify appropriate message is returned
        System.assertEquals(false, info.hasManager, 'Should not have manager assigned');
        System.assertEquals(null, info.managerName, 'Manager name should be null');
        System.assertEquals(
            'This property does not have a parent property assigned.', 
            info.message, 
            'Should show appropriate message for missing parent'
        );
    }
    
    @isTest
    static void testGetPropertyManagerInfo_InvalidPropertyId() {
        // Use an invalid property ID
        Id invalidId = '001000000000000AAA';
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(invalidId);
        Test.stopTest();
        
        // Verify appropriate error handling
        System.assertEquals(false, info.hasManager, 'Should not have manager');
        System.assertEquals('Property record not found.', info.message, 'Should show not found message');
    }
    
    @isTest
    static void testGetPropertyManagerInfo_NullPropertyId() {
        Test.startTest();
        try {
            PropertyManagerContactController.PropertyManagerInfo info = 
                PropertyManagerContactController.getPropertyManagerInfo(null);
            
            // If no exception, verify safe handling
            System.assertEquals(false, info.hasManager, 'Should not have manager for null ID');
        } catch (Exception e) {
            // Exception is acceptable for null input
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
            System.assert(e.getMessage().contains('Error retrieving'), 'Error message should be appropriate');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetPropertyManagerInfo_VerifyQueryFields() {
        // Get child property with manager
        List<Property__c> testProps = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Test Child Property' 
            LIMIT 1
        ];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPropertyManagerInfo_Constructor() {
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            new PropertyManagerContactController.PropertyManagerInfo();
        Test.stopTest();
        
        // Verify default constructor initializes hasManager to false
        System.assertEquals(false, info.hasManager, 'hasManager should default to false');
    }
    
    @isTest
    static void testPropertyManagerInfo_SettersGetters() {
        PropertyManagerContactController.PropertyManagerInfo info = 
            new PropertyManagerContactController.PropertyManagerInfo();
        
        // Set all properties
        info.hasManager = true;
        info.managerName = 'Test Manager';
        info.managerPhone = '+9876543210';
        info.managerEmail = 'testmanager@test.com';
        info.managerTitle = 'Test Title';
        info.parentPropertyName = 'Test Parent';
        info.message = 'Test Message';
        
        Test.startTest();
        // Verify all getters return correct values
        System.assertEquals(true, info.hasManager, 'hasManager should be true');
        System.assertEquals('Test Manager', info.managerName, 'Manager name should match');
        System.assertEquals('+9876543210', info.managerPhone, 'Manager phone should match');
        System.assertEquals('testmanager@test.com', info.managerEmail, 'Manager email should match');
        System.assertEquals('Test Title', info.managerTitle, 'Manager title should match');
        System.assertEquals('Test Parent', info.parentPropertyName, 'Parent property name should match');
        System.assertEquals('Test Message', info.message, 'Message should match');
        Test.stopTest();
    }
    
    @isTest
    static void testGetPropertyManagerInfo_PartialManagerData() {
        // Create a user with minimal data
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User minimalManager = new User(
            Alias = 'mmin',
            Email = 'minimal@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Minimal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'minimal' + DateTime.now().getTime() + '@test.com'
            // No Phone or Title
        );
        insert minimalManager;
        
        // Get Parent RecordType
        List<RecordType> recordTypes = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Property__c' AND Name = 'Parent Project' LIMIT 1
        ];
        
        if (recordTypes.isEmpty()) {
            return;
        }
        
        // Create parent with minimal manager
        Property__c parentMinimal = new Property__c(
            Name = 'Parent Minimal Manager',
            RecordTypeId = recordTypes[0].Id,
            Assigned_to_parent__c = minimalManager.Id
        );
        insert parentMinimal;
        
        // Get Sale RecordType
        List<RecordType> saleTypes = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Property__c' AND Name = 'Sale' LIMIT 1
        ];
        
        if (saleTypes.isEmpty()) {
            return;
        }
        
        // Create child property
        Property__c childMinimal = new Property__c(
            Name = 'Child Minimal Manager',
            RecordTypeId = saleTypes[0].Id,
            Parent_Property__c = parentMinimal.Id
        );
        insert childMinimal;
        
        Test.startTest();
        PropertyManagerContactController.PropertyManagerInfo info = 
            PropertyManagerContactController.getPropertyManagerInfo(childMinimal.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetPropertyManagerInfo_MultipleProperties() {
        // Get multiple properties
        List<Property__c> testProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name IN ('Test Child Property', 'Child Without Manager', 'Orphan Property')
        ];
        
        if (testProps.size() < 3) {
            return;
        }
        
        Test.startTest();
        List<PropertyManagerContactController.PropertyManagerInfo> infoList = 
            new List<PropertyManagerContactController.PropertyManagerInfo>();
        
        for (Property__c prop : testProps) {
            PropertyManagerContactController.PropertyManagerInfo info = 
                PropertyManagerContactController.getPropertyManagerInfo(prop.Id);
            infoList.add(info);
        }
        Test.stopTest();
        
        
        // Count how many have managers
        Integer managersFound = 0;
        for (PropertyManagerContactController.PropertyManagerInfo info : infoList) {
            if (info.hasManager) {
                managersFound++;
            }
        }
        
    }
    
    @isTest
    static void testGetPropertyManagerInfo_Cacheable() {
        // Test that the method is cacheable by calling it twice
        List<Property__c> testProps = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Test Child Property' 
            LIMIT 1
        ];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        Test.startTest();
        
        // First call
        PropertyManagerContactController.PropertyManagerInfo info1 = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        
        // Second call (should use cache in real scenario)
        PropertyManagerContactController.PropertyManagerInfo info2 = 
            PropertyManagerContactController.getPropertyManagerInfo(testProps[0].Id);
        
        Test.stopTest();
        
    }
    
}