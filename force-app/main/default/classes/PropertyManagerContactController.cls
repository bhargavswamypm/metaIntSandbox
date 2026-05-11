public class PropertyManagerContactController {
    
    @AuraEnabled(cacheable=true)
    public static PropertyManagerInfo getPropertyManagerInfo(Id propertyId) {
        try {
            // Query both formula fields and source User fields
            List<Property__c> properties = [
                SELECT Id, Name, Parent_Property__c,
                       Parent_Property__r.Name,
                       Parent_Property__r.Assigned_to_parent__c,
                       PM_Name__c,
                       PM_Email__c,
                       PM_Phone__c,
                       Assigned_to_parent__r.Title
                FROM Property__c 
                WHERE Id = :propertyId 
                LIMIT 1
            ];
            
            PropertyManagerInfo info = new PropertyManagerInfo();
            
            if (properties.isEmpty()) {
                info.hasManager = false;
                info.message = 'Property record not found.';
                return info;
            }
            
            Property__c property = properties[0];
            
            // Check if there's a parent property and assigned manager
            if (property.Parent_Property__c != null && 
                property.Parent_Property__r.Assigned_to_parent__c != null) {
                
                info.hasManager = true;
                info.parentPropertyName = property.Parent_Property__r.Name;
                
                // Try formula fields first, fallback to direct User fields
                info.managerName = property.PM_Name__c;
                
                info.managerEmail = property.PM_Email__c;
                
                info.managerPhone = property.PM_Phone__c;
                
                info.managerTitle = property.Assigned_to_parent__r.Title;
                
                System.debug('Final Manager Info - Name: ' + info.managerName + 
                           ', Email: ' + info.managerEmail + 
                           ', Phone: ' + info.managerPhone);
            } else {
                info.hasManager = false;
                if (property.Parent_Property__c == null) {
                    info.message = 'This property does not have a parent property assigned.';
                } else {
                    info.message = 'No property manager is currently assigned to the parent property.';
                }
            }
            
            return info;
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving property manager information: ' + e.getMessage());
        }
    }
    
    public class PropertyManagerInfo {
        @AuraEnabled public Boolean hasManager { get; set; }
        @AuraEnabled public String managerName { get; set; }
        @AuraEnabled public String managerPhone { get; set; }
        @AuraEnabled public String managerEmail { get; set; }
        @AuraEnabled public String managerTitle { get; set; }
        @AuraEnabled public String parentPropertyName { get; set; }
        @AuraEnabled public String message { get; set; }
        
        public PropertyManagerInfo() {
            this.hasManager = false;
        }
    }
}