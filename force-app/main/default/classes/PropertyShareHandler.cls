public class PropertyShareHandler {
    
    /**
     * Share all parent properties with given users (called from User trigger)
     */
    public static void shareParentPropertiesWithUsers(List<User> users) {
        if (users.isEmpty()) return;
        
        // Get Parent Property Record Type
        Id parentRtId = Schema.SObjectType.Property__c.getRecordTypeInfosByDeveloperName()
            .get('Parent_Property').getRecordTypeId();
        
        // Get ALL Parent Properties
        List<Property__c> parentProps = [
            SELECT Id
            FROM Property__c
            WHERE RecordTypeId = :parentRtId
        ];
        
        if (parentProps.isEmpty()) return;
        
        // Avoid duplicate shares
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            userIds.add(u.Id);
        }
        
        Map<Id, Set<Id>> alreadyShared = getExistingShares(parentProps, userIds);
        
        // Create new shares
        List<Property__Share> shares = new List<Property__Share>();
        for (Property__c p : parentProps) {
            for (User u : users) {
                if (alreadyShared.containsKey(p.Id) && alreadyShared.get(p.Id).contains(u.Id)) {
                    continue;
                }
                
                shares.add(new Property__Share(
                    ParentId = p.Id,
                    UserOrGroupId = u.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.Property__Share.RowCause.Manual
                ));
            }
        }
        
        if (!shares.isEmpty()) {
            insert shares;
        }
    }
    
    /**
     * Share given properties with all Property Owner users (called from Property trigger)
     */
    public static void sharePropertiesWithPropertyOwners(List<Property__c> properties) {
        if (properties.isEmpty()) return;
        
        // Get all Property Owner users with Customer Community Plus profile
        Profile commProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        
        List<User> propertyOwners = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND ProfileId = :commProfile.Id
            AND UserType__c = 'Property owners'
        ];
        
        if (propertyOwners.isEmpty()) return;
        
        // Avoid duplicate shares
        Set<Id> userIds = new Set<Id>();
        for (User u : propertyOwners) {
            userIds.add(u.Id);
        }
        
        Map<Id, Set<Id>> alreadyShared = getExistingShares(properties, userIds);
        
        // Create new shares
        List<Property__Share> shares = new List<Property__Share>();
        for (Property__c p : properties) {
            for (User u : propertyOwners) {
                if (alreadyShared.containsKey(p.Id) && alreadyShared.get(p.Id).contains(u.Id)) {
                    continue;
                }
                
                shares.add(new Property__Share(
                    ParentId = p.Id,
                    UserOrGroupId = u.Id,
                    AccessLevel = 'Read',
                    RowCause = Schema.Property__Share.RowCause.Manual
                ));
            }
        }
        
        if (!shares.isEmpty()) {
            insert shares;
        }
    }
    
    /**
     * Helper method to get existing shares
     */
    private static Map<Id, Set<Id>> getExistingShares(List<Property__c> properties, Set<Id> userIds) {
        Map<Id, Set<Id>> alreadyShared = new Map<Id, Set<Id>>();
        
        for (Property__Share ps : [
            SELECT ParentId, UserOrGroupId
            FROM Property__Share
            WHERE ParentId IN :properties
            AND UserOrGroupId IN :userIds
        ]) {
            if (!alreadyShared.containsKey(ps.ParentId)) {
                alreadyShared.put(ps.ParentId, new Set<Id>());
            }
            alreadyShared.get(ps.ParentId).add(ps.UserOrGroupId);
        }
        
        return alreadyShared;
    }
}