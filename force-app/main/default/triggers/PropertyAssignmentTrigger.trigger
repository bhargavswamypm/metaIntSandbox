/**
 * Trigger: PropertyAssignmentTrigger
 * Object: Property_Assignment__c
 * Description: Updates the Assigned_To__c field on Property__c whenever 
 *              assignments are created, updated, or deleted
 */
trigger PropertyAssignmentTrigger on Property_Assignment__c (after insert, after update, after delete, after undelete) {
    Set<Id> propertyIds = new Set<Id>();
    
    // Collect Property IDs from all contexts
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Property_Assignment__c pa : Trigger.new) {
            if (pa.Property__c != null) {
                propertyIds.add(pa.Property__c);
            }
        }
    }
    
    if (Trigger.isUpdate) {
        for (Property_Assignment__c pa : Trigger.old) {
            if (pa.Property__c != null) {
                propertyIds.add(pa.Property__c);
            }
        }
    }
    
    if (Trigger.isDelete) {
        for (Property_Assignment__c pa : Trigger.old) {
            if (pa.Property__c != null) {
                propertyIds.add(pa.Property__c);
            }
        }
    }
    
    if (!propertyIds.isEmpty()) {
        PropertyAssignmentTriggerHandler.updatePropertyAssignedTo(propertyIds);
    }
}