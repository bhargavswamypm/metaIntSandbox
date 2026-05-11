@isTest
private class PropertyAssignmentControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Property record (assuming Property__c is a custom object)
        Property__c testProperty = new Property__c(
            Name = 'Test Property',
             Accept_Terms__c = true,
            Accept_Terms_Rental__c = true
            // Add other required fields as needed
        );
        insert testProperty;
        
        // Create test Public Groups
        List<Group> testGroups = new List<Group>();
        for (Integer i = 1; i <= 3; i++) {
            testGroups.add(new Group(
                Name = 'Test Public Group ' + i,
                Type = 'Regular'
            ));
        }
        insert testGroups;
    }
    
    @isTest
    static void testGetAssignmentsDataForUsers() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = PropertyAssignmentController.getAssignmentsData(property.Id, 'User');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('availableList'), 'Result should contain availableList');
        System.assert(result.containsKey('assignedIds'), 'Result should contain assignedIds');
        
        List<User> availableUsers = (List<User>) result.get('availableList');
        System.assertNotEquals(null, availableUsers, 'Available users should not be null');
        
        List<Id> assignedIds = (List<Id>) result.get('assignedIds');
        System.assertEquals(0, assignedIds.size(), 'Should have no assigned users initially');
    }
    
    @isTest
    static void testGetAssignmentsDataForGroups() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = PropertyAssignmentController.getAssignmentsData(property.Id, 'Group');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('availableList'), 'Result should contain availableList');
        System.assert(result.containsKey('assignedIds'), 'Result should contain assignedIds');
        
        List<Group> availableGroups = (List<Group>) result.get('availableList');
       // System.assertEquals(3, availableGroups.size(), 'Should have 3 test public groups');
        
        List<Id> assignedIds = (List<Id>) result.get('assignedIds');
      //  System.assertEquals(0, assignedIds.size(), 'Should have no assigned groups initially');
    }
    
    @isTest
    static void testGetAssignmentsDataWithExistingAssignments() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        Group testGroup = [SELECT Id, Name FROM Group WHERE Type = 'Regular' LIMIT 1];
        
        // Create existing assignment
        Property_Assignment__c assignment = new Property_Assignment__c(
            Property__c = property.Id,
            Assignment_Type__c = 'Group',
            Group_Id__c = testGroup.Id,
            Group_Name__c = testGroup.Name,
            Name = testGroup.Name
        );
        insert assignment;
        
        Test.startTest();
        Map<String, Object> result = PropertyAssignmentController.getAssignmentsData(property.Id, 'Group');
        Test.stopTest();
        
        List<Id> assignedIds = (List<Id>) result.get('assignedIds');
        System.assertEquals(1, assignedIds.size(), 'Should have 1 assigned group');
        System.assertEquals(testGroup.Id, assignedIds[0], 'Assigned ID should match test group');
    }
    
    @isTest
    static void testGetAssignedRecords() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = TRUE LIMIT 1];
        Group testGroup = [SELECT Id, Name FROM Group WHERE Type = 'Regular' LIMIT 1];
        
        // Create assignments
        List<Property_Assignment__c> assignments = new List<Property_Assignment__c>();
        assignments.add(new Property_Assignment__c(
            Property__c = property.Id,
            Assignment_Type__c = 'User',
            User__c = testUser.Id,
            Name = testUser.Name
        ));
        assignments.add(new Property_Assignment__c(
            Property__c = property.Id,
            Assignment_Type__c = 'Group',
            Group_Id__c = testGroup.Id,
            Group_Name__c = testGroup.Name,
            Name = testGroup.Name
        ));
        insert assignments;
        
        Test.startTest();
        Map<String, Object> result = PropertyAssignmentController.getAssignedRecords(property.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        List<Map<String, Object>> users = (List<Map<String, Object>>) result.get('users');
        List<Map<String, Object>> groups = (List<Map<String, Object>>) result.get('groups');
        
        System.assertEquals(1, users.size(), 'Should have 1 user assignment');
        System.assertEquals(1, groups.size(), 'Should have 1 group assignment');
        
        System.assertEquals(testUser.Name, users[0].get('Name'), 'User name should match');
        System.assertEquals(testGroup.Name, groups[0].get('Group_Name__c'), 'Group name should match');
    }
    
    @isTest
    static void testSaveAssignmentsInsertUsers() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = TRUE LIMIT 1];
        
        List<Id> newSelectedIds = new List<Id>{ testUser.Id };
        List<Id> previousSelectedIds = new List<Id>();
        
        Test.startTest();
        PropertyAssignmentController.saveAssignments(property.Id, 'User', newSelectedIds, previousSelectedIds);
        Test.stopTest();
        
        List<Property_Assignment__c> assignments = [
            SELECT Id, User__c, Assignment_Type__c 
            FROM Property_Assignment__c 
            WHERE Property__c = :property.Id AND Assignment_Type__c = 'User'
        ];
        
        System.assertEquals(1, assignments.size(), 'Should have 1 user assignment');
        System.assertEquals(testUser.Id, assignments[0].User__c, 'User ID should match');
    }
    
    @isTest
    static void testSaveAssignmentsInsertGroups() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        List<Group> testGroups = [SELECT Id, Name FROM Group WHERE Type = 'Regular' LIMIT 2];
        
        List<Id> newSelectedIds = new List<Id>();
        for (Group g : testGroups) {
            newSelectedIds.add(g.Id);
        }
        List<Id> previousSelectedIds = new List<Id>();
        
        Test.startTest();
        PropertyAssignmentController.saveAssignments(property.Id, 'Group', newSelectedIds, previousSelectedIds);
        Test.stopTest();
        
        List<Property_Assignment__c> assignments = [
            SELECT Id, Group_Id__c, Assignment_Type__c 
            FROM Property_Assignment__c 
            WHERE Property__c = :property.Id AND Assignment_Type__c = 'Group'
        ];
        
        System.assertEquals(2, assignments.size(), 'Should have 2 group assignments');
    }
    
    @isTest
    static void testSaveAssignmentsDeleteUsers() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = TRUE LIMIT 1];
        
        // Create existing assignment
        Property_Assignment__c assignment = new Property_Assignment__c(
            Property__c = property.Id,
            Assignment_Type__c = 'User',
            User__c = testUser.Id,
            Name = testUser.Name
        );
        insert assignment;
        
        List<Id> newSelectedIds = new List<Id>();
        List<Id> previousSelectedIds = new List<Id>{ testUser.Id };
        
        Test.startTest();
        PropertyAssignmentController.saveAssignments(property.Id, 'User', newSelectedIds, previousSelectedIds);
        Test.stopTest();
        
        List<Property_Assignment__c> assignments = [
            SELECT Id 
            FROM Property_Assignment__c 
            WHERE Property__c = :property.Id AND Assignment_Type__c = 'User'
        ];
        
        System.assertEquals(0, assignments.size(), 'Should have no user assignments after deletion');
    }
    
    @isTest
    static void testSaveAssignmentsUpdateMixed() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        List<Group> testGroups = [SELECT Id, Name FROM Group WHERE Type = 'Regular' LIMIT 3];
        
        // Create existing assignments for first 2 groups
        List<Property_Assignment__c> existingAssignments = new List<Property_Assignment__c>();
        for (Integer i = 0; i < 2; i++) {
            existingAssignments.add(new Property_Assignment__c(
                Property__c = property.Id,
                Assignment_Type__c = 'Group',
                Group_Id__c = testGroups[i].Id,
                Group_Name__c = testGroups[i].Name,
                Name = testGroups[i].Name
            ));
        }
        insert existingAssignments;
        
        // New selection: remove first group, keep second, add third
        List<Id> newSelectedIds = new List<Id>{ testGroups[1].Id, testGroups[2].Id };
        List<Id> previousSelectedIds = new List<Id>{ testGroups[0].Id, testGroups[1].Id };
        
        Test.startTest();
        PropertyAssignmentController.saveAssignments(property.Id, 'Group', newSelectedIds, previousSelectedIds);
        Test.stopTest();
        
        List<Property_Assignment__c> assignments = [
            SELECT Id, Group_Id__c 
            FROM Property_Assignment__c 
            WHERE Property__c = :property.Id AND Assignment_Type__c = 'Group'
        ];
        
        System.assertEquals(2, assignments.size(), 'Should have 2 group assignments');
        
        Set<Id> assignedGroupIds = new Set<Id>();
        for (Property_Assignment__c pa : assignments) {
            assignedGroupIds.add((Id)pa.Group_Id__c);
        }
        
        System.assert(assignedGroupIds.contains(testGroups[1].Id), 'Should contain second group');
        System.assert(assignedGroupIds.contains(testGroups[2].Id), 'Should contain third group');
        System.assert(!assignedGroupIds.contains(testGroups[0].Id), 'Should not contain first group');
    }
    
    @isTest
    static void testSaveAssignmentsEmptyLists() {
        Property__c property = [SELECT Id FROM Property__c LIMIT 1];
        
        List<Id> newSelectedIds = new List<Id>();
        List<Id> previousSelectedIds = new List<Id>();
        
        Test.startTest();
        PropertyAssignmentController.saveAssignments(property.Id, 'User', newSelectedIds, previousSelectedIds);
        Test.stopTest();
        
        List<Property_Assignment__c> assignments = [
            SELECT Id 
            FROM Property_Assignment__c 
            WHERE Property__c = :property.Id
        ];
        
        System.assertEquals(0, assignments.size(), 'Should have no assignments');
    }
}