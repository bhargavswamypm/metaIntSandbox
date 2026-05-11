public class RecordHelper {
    
    @AuraEnabled(cacheable=true)
    public static String getObjectApiName(Id recordId) {
        if (recordId == null) {
            return null;
        }
        
        try {
            // Get the object type from the record Id
            Schema.SObjectType objectType = recordId.getSObjectType();
            return objectType.getDescribe().getName();
        } catch (Exception e) {
            System.debug('Error getting object API name: ' + e.getMessage());
            return null;
        }
    }
}