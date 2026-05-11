public class SalesProcessVisibilityController {

    @AuraEnabled(cacheable=true)
    public static Boolean isPropertyRecord(Id recordId) {
        if (recordId == null) return false;

        return recordId.getSObjectType() == Property__c.SObjectType;
    }
}