/**
 * Handler Class: PropertyAssignmentTriggerHandler
 * Description: Contains business logic for Property Assignment trigger
 */
public class PropertyAssignmentTriggerHandler {
    

    public static void updatePropertyAssignedTo(Set<Id> propertyIds) {
        // Query all Property Assignment records for the affected Properties
        List<Property_Assignment__c> assignments = [
            SELECT Id, Name, Property__c 
            FROM Property_Assignment__c 
            WHERE Property__c IN :propertyIds
            ORDER BY Name ASC
        ];
        
        // Map to store concatenated names for each Property
        Map<Id, List<String>> propertyToNamesMap = new Map<Id, List<String>>();
        
        // Group assignment names by Property
        for (Property_Assignment__c pa : assignments) {
            if (!propertyToNamesMap.containsKey(pa.Property__c)) {
                propertyToNamesMap.put(pa.Property__c, new List<String>());
            }
            propertyToNamesMap.get(pa.Property__c).add(pa.Name);
        }
        
        // Query Properties to update
        List<Property__c> propertiesToUpdate = [
            SELECT Id, Assigned_To__c 
            FROM Property__c 
            WHERE Id IN :propertyIds
        ];
        
        // Update each Property with concatenated names
        for (Property__c prop : propertiesToUpdate) {
            if (propertyToNamesMap.containsKey(prop.Id)) {
                // Join names with semicolon
                prop.Assigned_To__c = String.join(propertyToNamesMap.get(prop.Id), ';');
            } else {
                // No assignments, clear the field
                prop.Assigned_To__c = '';
            }
        }
        
        // Update Properties
        if (!propertiesToUpdate.isEmpty()) {
            update propertiesToUpdate;
        }
    }
}