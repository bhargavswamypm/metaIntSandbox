/**
 * @File Name          : VendorController.cls
 * @Description        : Controller for managing vendor records with enhanced error handling
 * @Author             : Your Name
 * @Last Modified By   : Your Name
 * @Last Modified On   : December 23, 2025
 * @Modification Log   :
 *==============================================================================
 * Ver | Date            | Author      | Modification
 *==============================================================================
 * 1.0 | Dec 23, 2025    | Your Name   | Initial Version
 * 1.1 | Dec 23, 2025    | Your Name   | Added error handling and null checks
 **/

public class VendorController {
    
    /**
     * @description Retrieves vendor records grouped by Record Type
     * @return Map<String, List<Vendor__c>> - Map of Record Type Name to List of Vendors
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Vendor__c>> getVendorRecords() {
        try {
            // Query all vendor records with required fields
            List<Vendor__c> vendorList = [
                SELECT Id, 
                       Name, 
                       RecordType.Name, 
                       Email__c, 
                       Phone__c 
                FROM Vendor__c 
                WHERE RecordType.Name != null
                ORDER BY RecordType.Name, Name
                LIMIT 1000
            ];
            
            // Initialize map to store vendors by Record Type
            Map<String, List<Vendor__c>> vendorMap = new Map<String, List<Vendor__c>>();
            
            // Group vendors by Record Type
            for (Vendor__c vendor : vendorList) {
                String recordTypeName = vendor.RecordType?.Name;
                
                // Skip if Record Type is null
                if (String.isBlank(recordTypeName)) {
                    continue;
                }
                
                // Initialize list if Record Type not in map
                if (!vendorMap.containsKey(recordTypeName)) {
                    vendorMap.put(recordTypeName, new List<Vendor__c>());
                }
                
                // Add vendor to corresponding Record Type list
                vendorMap.get(recordTypeName).add(vendor);
            }
            
            return vendorMap;
            
        } catch (Exception e) {
            // Log error for debugging
            System.debug(LoggingLevel.ERROR, 'Error fetching vendor records: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Throw user-friendly error
            throw new AuraHandledException('Unable to retrieve vendor records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves count of vendors by Record Type
     * @return Map<String, Integer> - Map of Record Type Name to count
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getVendorCount() {
        try {
            Map<String, Integer> countMap = new Map<String, Integer>();
            
            // Aggregate query for better performance
            List<AggregateResult> results = [
                SELECT RecordType.Name recordTypeName, COUNT(Id) vendorCount
                FROM Vendor__c
                WHERE RecordType.Name != null
                GROUP BY RecordType.Name
            ];
            
            for (AggregateResult result : results) {
                String rtName = (String) result.get('recordTypeName');
                Integer count = (Integer) result.get('vendorCount');
                countMap.put(rtName, count);
            }
            
            return countMap;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching vendor count: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve vendor count: ' + e.getMessage());
        }
    }
}