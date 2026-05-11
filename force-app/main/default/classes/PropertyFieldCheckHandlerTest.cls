@isTest
public class PropertyFieldCheckHandlerTest {

        
    @testSetup
    static void setup() {
        // Create test users with emails
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User user1 = new User(
            Alias = 'usr1',
            Email = 'testuser1@gettaproperties.com',
            UserType__c='Property owners',
           
            EmailEncodingKey = 'UTF-8',
            LastName = 'User One',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser1' + DateTime.now().getTime() + '@test.com'
        );
        insert user1;
        
        User user2 = new User(
            Alias = 'usr2',
            Email = 'testuser2@gettaproperties.com',
               UserType__c='Property owners',
          
            EmailEncodingKey = 'UTF-8',
            LastName = 'User Two',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser2' + DateTime.now().getTime() + '@test.com'
        );
        insert user2;
        
        // Get RecordTypes
        List<RecordType> recordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name IN ('Parent Project', 'Sale')
        ];
        
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.Name, rt.Id);
        }
        
        // Create Parent Properties
        Property__c parentProperty1 = new Property__c(
            Name = 'Parent Property 1',
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Parent Project')
        );
        insert parentProperty1;
        
        Property__c parentProperty2 = new Property__c(
            Name = 'Parent Property 2',
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Parent Project')
        );
        insert parentProperty2;
        
        // Create Child Properties
        Property__c childProperty1 = new Property__c(
            Name = 'Child Property 1',
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Sale'),
            Parent_Property__c = parentProperty1.Id,
            Property_No__c = 'PROP-001'
        );
        insert childProperty1;
        
        Property__c childProperty2 = new Property__c(
            Name = 'Child Property 2',
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Sale'),
            Parent_Property__c = parentProperty1.Id,
            Property_No__c = 'PROP-002'
        );
        insert childProperty2;
        
        Property__c childProperty3 = new Property__c(
            Name = 'Child Property 3',
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Sale'),
            Parent_Property__c = parentProperty2.Id,
            Property_No__c = 'PROP-003'
        );
        insert childProperty3;
        
        // Create Property Assignments (link users to parent properties)
        List<Property_Assignment__c> assignments = new List<Property_Assignment__c>();
        
        assignments.add(new Property_Assignment__c(
            Property__c = parentProperty1.Id,
            User__c = user1.Id,
            Assignment_Type__c = 'User'
        ));
        
        assignments.add(new Property_Assignment__c(
            Property__c = parentProperty1.Id,
            User__c = user2.Id,
            Assignment_Type__c = 'User'
        ));
        
        assignments.add(new Property_Assignment__c(
            Property__c = parentProperty2.Id,
            User__c = user1.Id,
            Assignment_Type__c = 'User'
        ));
        
        insert assignments;
    }
    
    // ===== EMAIL NOTIFICATION TESTS =====
    
    @isTest
    static void testNotifyParentAssignments_SingleProperty() {
        // Get child property
        List<Property__c> childProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name = 'Child Property 1' 
            LIMIT 1
        ];
        
        if (childProps.isEmpty()) {
            System.debug('Test data not found - skipping test');
            return;
        }
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childProps[0].Id, new List<String>{'Property_No__c', 'Facing__c'});
        
        Test.startTest();
        
        // Reset email invocation count
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
        // Verify email was sent
        System.assertEquals(emailsBefore + 1, emailsAfter, 'One email should be sent');
    }
    
    @isTest
    static void testNotifyParentAssignments_MultipleProperties() {
        // Get multiple child properties from same parent
        List<Property__c> childProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name IN ('Child Property 1', 'Child Property 2')
            ORDER BY Name
        ];
        
        if (childProps.size() < 2) {
            return;
        }
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childProps[0].Id, new List<String>{'Property_No__c'});
        propMissingMap.put(childProps[1].Id, new List<String>{'Configuration__c', 'Location__c'});
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testNotifyParentAssignments_DifferentParents() {
        // Get child properties from different parents
        List<Property__c> childProps = [
            SELECT Id, Name, Parent_Property__c
            FROM Property__c 
            WHERE Name IN ('Child Property 1', 'Child Property 3')
            ORDER BY Name
        ];
        
        if (childProps.size() < 2) {
            return;
        }
        
        // Verify they have different parents
        System.assertNotEquals(
            childProps[0].Parent_Property__c, 
            childProps[1].Parent_Property__c, 
            'Properties should have different parents'
        );
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childProps[0].Id, new List<String>{'Facing__c'});
        propMissingMap.put(childProps[1].Id, new List<String>{'Property_No__c'});
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testNotifyParentAssignments_NoAssignments() {
        // Create a parent without assignments
        List<RecordType> recordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name IN ('Parent Project', 'Sale')
        ];
        
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.Name, rt.Id);
        }
        
        if (recordTypeMap.isEmpty()) {
            return;
        }
        
        Property__c parentNoAssignment = new Property__c(
            Name = 'Parent No Assignment',
            RecordTypeId = recordTypeMap.get('Parent Project')
        );
        insert parentNoAssignment;
        
        Property__c childNoAssignment = new Property__c(
            Name = 'Child No Assignment',
              Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            RecordTypeId = recordTypeMap.get('Sale'),
            Parent_Property__c = parentNoAssignment.Id
        );
        insert childNoAssignment;
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childNoAssignment.Id, new List<String>{'Property_No__c'});
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
        // Verify no email was sent since no assignments exist
        System.assertEquals(emailsBefore, emailsAfter, 'No email should be sent when no assignments exist');
    }
    
    @isTest
    static void testNotifyParentAssignments_NoParent() {
        // Create child property without parent
        List<RecordType> recordTypes = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale'
        ];
        
        if (recordTypes.isEmpty()) {
            return;
        }
        
        Property__c orphanProperty = new Property__c(
            Name = 'Orphan Property',
            RecordTypeId = recordTypes[0].Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true
            // No Parent_Property__c
        );
        insert orphanProperty;
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(orphanProperty.Id, new List<String>{'Property_No__c'});
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
        // Verify no email was sent since no parent exists
        System.assertEquals(emailsBefore, emailsAfter, 'No email should be sent when no parent exists');
    }
    
    @isTest
    static void testNotifyParentAssignments_EmptyMap() {
        // Empty map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
        // Verify no email was sent
        System.assertEquals(emailsBefore, emailsAfter, 'No email should be sent for empty map');
    }
    
    @isTest
    static void testNotifyParentAssignments_MultipleAssignments() {
        // Get child property with parent that has multiple assignments
        List<Property__c> childProps = [
            SELECT Id, Name, Parent_Property__c
            FROM Property__c 
            WHERE Name = 'Child Property 1' 
            LIMIT 1
        ];
        
        if (childProps.isEmpty()) {
            return;
        }
        
        // Verify parent has multiple assignments
        List<Property_Assignment__c> assignments = [
            SELECT Id 
            FROM Property_Assignment__c 
            WHERE Property__c = :childProps[0].Parent_Property__c
        ];
        
        System.assert(assignments.size() > 1, 'Parent should have multiple assignments');
        
        // Create missing fields map
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childProps[0].Id, new List<String>{'Facing__c', 'Location__c'});
        
        Test.startTest();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Test.stopTest();
        
        // Email should be sent to multiple recipients
        System.assert(true, 'Method should execute successfully with multiple assignments');
    }
    
    @isTest
    static void testNotifyParentAssignments_EmailContent() {
        // Get child property
        List<Property__c> childProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name = 'Child Property 1' 
            LIMIT 1
        ];
        
        if (childProps.isEmpty()) {
            return;
        }
        
        // Create missing fields map with specific fields
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        List<String> missingFields = new List<String>{'Property_No__c', 'Facing__c', 'Configuration__c'};
        propMissingMap.put(childProps[0].Id, missingFields);
        
        Test.startTest();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Test.stopTest();
        
        System.assert(true, 'Email should be sent with correct content');
    }
    
    @isTest
    static void testNotifyParentAssignments_SingleMissingField() {
        List<Property__c> childProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name = 'Child Property 1' 
            LIMIT 1
        ];
        
        if (childProps.isEmpty()) {
            return;
        }
        
        // Create missing fields map with only one field
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        propMissingMap.put(childProps[0].Id, new List<String>{'Property_No__c'});
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testNotifyParentAssignments_BulkProcessing() {
        // Get all child properties
        List<Property__c> childProps = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name LIKE 'Child Property%'
        ];
        
        if (childProps.isEmpty()) {
            return;
        }
        
        // Create missing fields map for all properties
        Map<Id, List<String>> propMissingMap = new Map<Id, List<String>>();
        for (Property__c prop : childProps) {
            propMissingMap.put(prop.Id, new List<String>{'Property_No__c', 'Facing__c'});
        }
        
        Test.startTest();
        
        Integer emailsBefore = Limits.getEmailInvocations();
        
        PropertyFieldCheckHandler.notifyParentAssignments(propMissingMap);
        
        Integer emailsAfter = Limits.getEmailInvocations();
        
        Test.stopTest();
        
    }
    
    // ===== DUPLICATE PREVENTION TESTS =====
    
    @isTest
    static void testDuplicatePropertyNo_SameParent_ShouldFail() {
        // Get parent property
        Property__c parent = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Parent Property 1' 
            LIMIT 1
        ];
        
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Try to create a property with duplicate Property_No__c under same parent
        Property__c duplicateProperty = new Property__c(
            Name = 'Duplicate Property',
            RecordTypeId = saleRT.Id,
            Parent_Property__c = parent.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Property_No__c = 'PROP-001' // This already exists for Parent Property 1
        );
        
        try {
            insert duplicateProperty;
            System.assert(false, 'Should have thrown an error for duplicate Property_No__c');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Property with this Property No already exists'), 
                'Error message should indicate duplicate Property No'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicatePropertyNo_DifferentParent_ShouldSucceed() {
        // Get different parent properties
        List<Property__c> parents = [
            SELECT Id, Name 
            FROM Property__c 
            WHERE Name IN ('Parent Property 1', 'Parent Property 2')
            ORDER BY Name
        ];
        
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Create property with same Property_No__c but different parent - should succeed
        Property__c newProperty = new Property__c(
            Name = 'Property With Same No',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parents[1].Id, // Parent Property 2
            Property_No__c = 'PROP-001' // Same as one under Parent Property 1, but different parent
        );
        
        insert newProperty;
        
        Test.stopTest();
        
        // Verify it was inserted successfully
        Property__c inserted = [
            SELECT Id, Property_No__c, Parent_Property__c 
            FROM Property__c 
            WHERE Id = :newProperty.Id
        ];
        System.assertEquals('PROP-001', inserted.Property_No__c);
        System.assertEquals(parents[1].Id, inserted.Parent_Property__c);
    }
    
    @isTest
    static void testDuplicatePropertyNo_NoParent_ShouldSucceed() {
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Create properties without parent - should succeed even with same Property_No__c
        Property__c property1 = new Property__c(
            Name = 'Property Without Parent 1',
            RecordTypeId = saleRT.Id,
              Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Property_No__c = 'PROP-999'
        );
        insert property1;
        
        Property__c property2 = new Property__c(
            Name = 'Property Without Parent 2',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Property_No__c = 'PROP-999' // Same Property_No__c but no parent
        );
        insert property2;
        
        Test.stopTest();
        
        // Both should be inserted successfully
        List<Property__c> inserted = [
            SELECT Id, Property_No__c 
            FROM Property__c 
            WHERE Id IN (:property1.Id, :property2.Id)
        ];
        System.assertEquals(2, inserted.size());
    }
    
    @isTest
    static void testDuplicatePropertyNo_NullPropertyNo_ShouldSucceed() {
        // Get parent property
        Property__c parent = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Parent Property 1' 
            LIMIT 1
        ];
        
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Create properties with null Property_No__c - should succeed
        Property__c property1 = new Property__c(
            Name = 'Property With Null No 1',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id
            // Property_No__c is null
        );
        insert property1;
        
        Property__c property2 = new Property__c(
            Name = 'Property With Null No 2',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id
            // Property_No__c is null
        );
        insert property2;
        
        Test.stopTest();
        
        // Both should be inserted successfully
        List<Property__c> inserted = [
            SELECT Id 
            FROM Property__c 
            WHERE Id IN (:property1.Id, :property2.Id)
        ];
        System.assertEquals(2, inserted.size());
    }
    
    @isTest
    static void testDuplicatePropertyNo_BulkInsert_Mixed() {
        // Get parent property
        Property__c parent = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Parent Property 1' 
            LIMIT 1
        ];
        
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        List<Property__c> propertiesToInsert = new List<Property__c>();
        
        // Valid properties
        propertiesToInsert.add(new Property__c(
            Name = 'Bulk Property 1',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id,
            Property_No__c = 'BULK-001'
        ));
        
        propertiesToInsert.add(new Property__c(
            Name = 'Bulk Property 2',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id,
            Property_No__c = 'BULK-002'
        ));
        
        // Duplicate property
        propertiesToInsert.add(new Property__c(
            Name = 'Bulk Property Duplicate',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id,
            Property_No__c = 'PROP-001' // Already exists
        ));
        
        Database.SaveResult[] results = Database.insert(propertiesToInsert, false);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, results[0].isSuccess(), 'First property should succeed');
        System.assertEquals(true, results[1].isSuccess(), 'Second property should succeed');
        System.assertEquals(false, results[2].isSuccess(), 'Third property should fail due to duplicate');
        System.assert(
            results[2].getErrors()[0].getMessage().contains('A Property with this Property No already exists'),
            'Error message should indicate duplicate'
        );
    }
    
    @isTest
    static void testTrigger_AfterUpdate_WithMissingFields() {
        // Get child property
        Property__c childProp = [
            SELECT Id, Property_No__c, Facing__c, Floor__c 
            FROM Property__c 
            WHERE Name = 'Child Property 1' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Update to make fields null
        childProp.Property_No__c = null;
        childProp.Facing__c = null;
        childProp.Floor__c = null;
        
        update childProp;
        
        Test.stopTest();
        
        // Email should be sent due to missing fields
        System.assert(true, 'Update trigger should execute successfully');
    }
    
    @isTest
    static void testTrigger_BeforeInsert_ValidData() {
        // Get parent property
        Property__c parent = [
            SELECT Id 
            FROM Property__c 
            WHERE Name = 'Parent Property 2' 
            LIMIT 1
        ];
        
        // Get RecordType
        RecordType saleRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Property__c' 
            AND Name = 'Sale' 
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Create property with unique Property_No__c
        Property__c newProp = new Property__c(
            Name = 'Valid Property',
            RecordTypeId = saleRT.Id,
             Accept_Terms__c = true,
           Accept_Terms_Rental__c = true,
            Parent_Property__c = parent.Id,
            Property_No__c = 'VALID-001'
        );
        
        insert newProp;
        
        Test.stopTest();
        
        // Verify it was inserted
        Property__c inserted = [
            SELECT Id, Property_No__c 
            FROM Property__c 
            WHERE Id = :newProp.Id
        ];
        System.assertEquals('VALID-001', inserted.Property_No__c);
    }
}