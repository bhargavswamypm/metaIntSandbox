public with sharing class PropertyAssignmentController {
 
    @AuraEnabled
    public static Map<String, Object> getAssignmentsData(Id propertyId, String type) {
        Map<String, Object> result = new Map<String, Object>();
 
        List<Profile> pf = [SELECT Id, Name FROM Profile WHERE Name IN ('System Administrator')];//'Standard Platform User')];
        // 1️⃣ Fetch available options
        if (type == 'User') {
            List<User> users = [SELECT Id, Name FROM User WHERE IsActive = TRUE AND ProfileId IN :pf ORDER BY Name];
            result.put('availableList', users);
        } else if (type == 'Group') {
            // Fetch Public Groups (Type = 'Regular')
            List<Group> groups = [
                SELECT Id, Name 
                FROM Group 
                WHERE Type = 'Regular' 
                ORDER BY Name
            ];
            result.put('availableList', groups);
        }
 
        // 2️⃣ Fetch assigned ones
        List<Property_Assignment__c> existingAssignments = [
            SELECT Id, Assignment_Type__c, User__c, Group_Id__c
            FROM Property_Assignment__c
            WHERE Property__c = :propertyId
            AND Assignment_Type__c = :type
        ];
 
        List<Id> assignedIds = new List<Id>();
        for (Property_Assignment__c pa : existingAssignments) {
            if (type == 'User' && pa.User__c != null) assignedIds.add(pa.User__c);
            if (type == 'Group' && pa.Group_Id__c != null) assignedIds.add((Id)pa.Group_Id__c);
        }
        result.put('assignedIds', assignedIds);
 
        return result;
    }
 
    @AuraEnabled
    public static Map<String, Object> getAssignedRecords(Id propertyId) {
        Map<String, Object> result = new Map<String, Object>();
        // Fetch all assignments for this property
        List<Property_Assignment__c> assignments = [
            SELECT Id, Name, Assignment_Type__c, User__c, User__r.Name, Group_Id__c, Group_Name__c
            FROM Property_Assignment__c
            WHERE Property__c = :propertyId
            ORDER BY Assignment_Type__c, Name
        ];
 
        List<Map<String, Object>> userList = new List<Map<String, Object>>();
        List<Map<String, Object>> groupList = new List<Map<String, Object>>();
 
        for (Property_Assignment__c pa : assignments) {
            if (pa.Assignment_Type__c == 'User' && pa.User__c != null) {
                Map<String, Object> userRecord = new Map<String, Object>();
                userRecord.put('Id', pa.Id);
                userRecord.put('Name', pa.User__r.Name);
                userRecord.put('Assignment_Type__c', pa.Assignment_Type__c);
                userList.add(userRecord);
            } else if (pa.Assignment_Type__c == 'Group' && pa.Group_Id__c != null) {
                Map<String, Object> groupRecord = new Map<String, Object>();
                groupRecord.put('Id', pa.Id);
                groupRecord.put('Group_Name__c', pa.Group_Name__c);
                groupRecord.put('Assignment_Type__c', pa.Assignment_Type__c);
                groupList.add(groupRecord);
            }
        }
 
        result.put('users', userList);
        result.put('groups', groupList);
 
        return result;
    }
 
    @AuraEnabled
    public static void saveAssignments(Id propertyId, String type, List<Id> newSelectedIds, List<Id> previousSelectedIds) {
        Set<Id> newSet = new Set<Id>(newSelectedIds);
        Set<Id> oldSet = new Set<Id>(previousSelectedIds);
 
        // Determine which to insert or delete
        Set<Id> toInsert = new Set<Id>(newSet);
        toInsert.removeAll(oldSet);
 
        Set<Id> toDelete = new Set<Id>(oldSet);
        toDelete.removeAll(newSet);
 
        List<Property_Assignment__c> insertList = new List<Property_Assignment__c>();
        List<Property_Assignment__c> deleteList = new List<Property_Assignment__c>();
 
        if (type == 'User') {
            if (!toInsert.isEmpty()) {
                for (User u : [SELECT Id, Name FROM User WHERE Id IN :toInsert]) {
                    insertList.add(new Property_Assignment__c(
                        Property__c = propertyId,
                        Assignment_Type__c = 'User',
                        User__c = u.Id,
                        Name = u.Name
                    ));
                }
            }
 
            if (!toDelete.isEmpty()) {
                deleteList = [
                    SELECT Id FROM Property_Assignment__c
                    WHERE Property__c = :propertyId
                    AND Assignment_Type__c = 'User'
                    AND User__c IN :toDelete
                ];
            }
        } else if (type == 'Group') {
            if (!toInsert.isEmpty()) {
                // Query Salesforce Public Groups
                for (Group g : [SELECT Id, Name FROM Group WHERE Id IN :toInsert AND Type = 'Regular']) {
                    insertList.add(new Property_Assignment__c(
                        Property__c = propertyId,
                        Assignment_Type__c = 'Group',
                        Group_Id__c = g.Id,
                        Group_Name__c = g.Name,
                        Name = g.Name
                    ));
                }
            }
 
            if (!toDelete.isEmpty()) {
                deleteList = [
                    SELECT Id FROM Property_Assignment__c
                    WHERE Property__c = :propertyId
                    AND Assignment_Type__c = 'Group'
                    AND Group_Id__c IN :toDelete
                ];
            }
        }
 
        if (!insertList.isEmpty()) insert insertList;
        if (!deleteList.isEmpty()) delete deleteList;
    }
}