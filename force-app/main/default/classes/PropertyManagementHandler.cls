public class PropertyManagementHandler {
    public static void syncServices(List<Property_Management__c> newList, Map<Id, Property_Management__c> oldMap) {
        Set<Id> pmIds = new Set<Id>();
        for (Property_Management__c pm : newList) {
            pmIds.add(pm.Id);
        }
        
        // Existing child services
        Map<Id, List<Services_Requested__c>> existingServicesMap = new Map<Id, List<Services_Requested__c>>();
        for (Services_Requested__c sr : [
            SELECT Id, Name, Service__c, Service__r.Name, Property_Management__c
            FROM Services_Requested__c
            WHERE Property_Management__c IN :pmIds
        ]) {
            if (!existingServicesMap.containsKey(sr.Property_Management__c)) {
                existingServicesMap.put(sr.Property_Management__c, new List<Services_Requested__c>());
            }
            existingServicesMap.get(sr.Property_Management__c).add(sr);
        }
        
        List<Services_Requested__c> recordsToInsert = new List<Services_Requested__c>();
        List<Services_Requested__c> recordsToDelete = new List<Services_Requested__c>();
        
        for (Property_Management__c pm : newList) {
            // FIX: Don't split by semicolon - treat entire field value as comma-separated or use proper delimiter
            List<String> selectedValues = new List<String>();
            if (pm.Legal_Services_Required__c != null) {
                // If your picklist uses semicolon as THE delimiter between multiple services, keep split
                // But trim each value to remove whitespace
                for (String val : pm.Legal_Services_Required__c.split(';')) {
                    selectedValues.add(val.trim());
                }
            }
            
            // Get previous selection
            List<String> previousValues = new List<String>();
            if (oldMap != null && oldMap.containsKey(pm.Id) && oldMap.get(pm.Id).Legal_Services_Required__c != null) {
                for (String val : oldMap.get(pm.Id).Legal_Services_Required__c.split(';')) {
                    previousValues.add(val.trim());
                }
            }
            
            // Convert to Sets for proper diff operation
            Set<String> selectedValuesSet = new Set<String>(selectedValues);
            Set<String> previousValuesSet = new Set<String>(previousValues);
            
            // Services to add = new selection - old selection
            Set<String> servicesToAdd = selectedValuesSet.clone();
            servicesToAdd.removeAll(previousValuesSet);
            
            // Services to remove = old selection - new selection
            Set<String> servicesToRemove = previousValuesSet.clone();
            servicesToRemove.removeAll(selectedValuesSet);
            
            // Fetch matching service details
            Map<String, Property_Management_Services__c> serviceDetailsMap = new Map<String, Property_Management_Services__c>();
            for (Property_Management_Services__c svc : [
                SELECT Id, Name, Charge__c, Government_Charges__c
                FROM Property_Management_Services__c
                WHERE Name IN :servicesToAdd
            ]) {
                serviceDetailsMap.put(svc.Name, svc);
            }
            
            for (String serviceName : servicesToAdd) {
                if (serviceDetailsMap.containsKey(serviceName)) {
                    Property_Management_Services__c svc = serviceDetailsMap.get(serviceName);
                    if (svc != null) {
                        Decimal charge = svc.Charge__c != null ? svc.Charge__c : 0;
                        Decimal govtCharge = svc.Government_Charges__c != null ? svc.Government_Charges__c : 0;
                        recordsToInsert.add(new Services_Requested__c(
                            Name = svc.Name, // FIX: Explicitly set the Name field
                            Property_Management__c = pm.Id,
                            Service__c = svc.Id,
                            Charge_Amount__c = charge,
                            Government_Charges__c = govtCharge,
                            Total_Charges__c = charge + govtCharge
                        ));
                    }
                }
            }
            
            // Prepare delete records
            if (existingServicesMap.containsKey(pm.Id)) {
                for (Services_Requested__c sr : existingServicesMap.get(pm.Id)) {
                    if (servicesToRemove.contains(sr.Service__r.Name)) {
                        recordsToDelete.add(sr);
                    }
                }
            }
        }
        
        // DML operations
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        if (!recordsToDelete.isEmpty()) {
            delete recordsToDelete;
        }
    }
}