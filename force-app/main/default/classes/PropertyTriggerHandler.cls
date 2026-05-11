public class PropertyTriggerHandler {
    
    public static void handlePropertyRecords(List<Property__c> properties) {
        
        // Collect phone numbers and emails for matching
        Set<String> phoneNumbers = new Set<String>();
        Set<String> emails = new Set<String>();
        
        for(Property__c prop : properties) {
            if(String.isNotBlank(prop.OwnerPhoneNumber__c) || 
               String.isNotBlank(prop.OwnerEmail__c)) {
                
                if(String.isNotBlank(prop.OwnerPhoneNumber__c)) {
                    phoneNumbers.add(prop.OwnerPhoneNumber__c);
                }
                if(String.isNotBlank(prop.OwnerEmail__c)) {
                    emails.add(prop.OwnerEmail__c);
                }
            }
        }
        
        // If no data to process, exit
        if(phoneNumbers.isEmpty() && emails.isEmpty()) {
            return;
        }
        
        // Get Seller RecordType Id
        Id sellerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                                .get('Sellers').getRecordTypeId();
        
        // Query existing Contacts with Seller RecordType
        List<Contact> existingContacts = [
            SELECT Id, Phone, Secondary_Phone__c, Email 
            FROM Contact 
            WHERE RecordTypeId = :sellerRecordTypeId
            AND (Phone != null 
                 OR Secondary_Phone__c != null 
                 OR Email IN :emails)
        ];
        
        // Create maps for quick lookup with normalized phone numbers
        Map<String, Id> normalizedPhoneToContactId = new Map<String, Id>();
        Map<String, Id> emailToContactId = new Map<String, Id>();
        
        for(Contact con : existingContacts) {
            // Normalize and map Phone
            if(String.isNotBlank(con.Phone)) {
                String normalizedPhone = normalizePhoneNumber(con.Phone);
                if(String.isNotBlank(normalizedPhone)) {
                    normalizedPhoneToContactId.put(normalizedPhone, con.Id);
                }
            }
            // Normalize and map Secondary_Phone__c
            if(String.isNotBlank(con.Secondary_Phone__c)) {
                String normalizedSecondaryPhone = normalizePhoneNumber(con.Secondary_Phone__c);
                if(String.isNotBlank(normalizedSecondaryPhone)) {
                    normalizedPhoneToContactId.put(normalizedSecondaryPhone, con.Id);
                }
            }
            // Map Email (case-insensitive)
            if(String.isNotBlank(con.Email)) {
                emailToContactId.put(con.Email.toLowerCase(), con.Id);
            }
        }
        
        // List to hold new contacts to be created
        List<Contact> newContacts = new List<Contact>();
        Map<String, Property__c> keyToProperty = new Map<String, Property__c>();
        
        // Process each property
        for(Property__c prop : properties) {
            
            // Skip if owner details are not filled
            if(String.isBlank(prop.OwnerPhoneNumber__c) && 
               String.isBlank(prop.OwnerEmail__c)) {
                continue;
            }
            
            Id matchedContactId = null;
            
            // Priority 1: Check Phone match with normalized number
            if(String.isNotBlank(prop.OwnerPhoneNumber__c)) {
                String normalizedPropertyPhone = normalizePhoneNumber(prop.OwnerPhoneNumber__c);
                if(String.isNotBlank(normalizedPropertyPhone) && 
                   normalizedPhoneToContactId.containsKey(normalizedPropertyPhone)) {
                    matchedContactId = normalizedPhoneToContactId.get(normalizedPropertyPhone);
                }
            }
            
            // Priority 2: If no phone match, check Email (case-insensitive)
            if(matchedContactId == null && 
               String.isNotBlank(prop.OwnerEmail__c)) {
                String normalizedEmail = prop.OwnerEmail__c.toLowerCase();
                if(emailToContactId.containsKey(normalizedEmail)) {
                    matchedContactId = emailToContactId.get(normalizedEmail);
                }
            }
            
            // If match found, assign to property
            if(matchedContactId != null) {
                prop.Seller_Contact__c = matchedContactId;
            } else {
                // No match found, prepare new contact
                Contact newContact = new Contact();
                newContact.LastName = String.isNotBlank(prop.OwnerName__c) ? 
                                     prop.OwnerName__c : 'Unknown Owner';
                newContact.Phone = prop.OwnerPhoneNumber__c;
                newContact.Email = prop.OwnerEmail__c;
                newContact.RecordTypeId = sellerRecordTypeId;
                
                newContacts.add(newContact);
                
                // Create unique key for mapping after insert
                String uniqueKey = normalizePhoneNumber(prop.OwnerPhoneNumber__c) + '_' + 
                                  (String.isNotBlank(prop.OwnerEmail__c) ? prop.OwnerEmail__c.toLowerCase() : '');
                keyToProperty.put(uniqueKey, prop);
            }
        }
        
        // Insert new contacts if any
        if(!newContacts.isEmpty()) {
            insert newContacts;
            
            // Map newly created contact Ids back to properties
            for(Contact con : newContacts) {
                String uniqueKey = normalizePhoneNumber(con.Phone) + '_' + 
                                  (String.isNotBlank(con.Email) ? con.Email.toLowerCase() : '');
                if(keyToProperty.containsKey(uniqueKey)) {
                    Property__c prop = keyToProperty.get(uniqueKey);
                    prop.Seller_Contact__c = con.Id;
                }
            }
        }
    }
    
    // Helper method to normalize phone numbers
    // Removes all non-numeric characters and standardizes format
    private static String normalizePhoneNumber(String phone) {
        if(String.isBlank(phone)) {
            return null;
        }
        
        // Remove all non-numeric characters (spaces, hyphens, parentheses, plus signs)
        String normalized = phone.replaceAll('[^0-9]', '');
        
        // Handle different formats:
        // If starts with country code (91 for India), keep last 10 digits
        // Examples: +918296020419, 918296020419, 91 829 20 419 -> 8296020419
        if(normalized.length() > 10) {
            // Take last 10 digits (actual phone number without country code)
            normalized = normalized.substring(normalized.length() - 10);
        }
        
        return normalized;
    }
    
}