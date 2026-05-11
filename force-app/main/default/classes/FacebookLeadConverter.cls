public class FacebookLeadConverter {
    
    /**
     * Convert Facebook lead to Salesforce Lead and insert
     */
    public static void processLead(FacebookLead facebookLead) {
        if (facebookLead == null) return;
        
        try {
            // Check for existing lead to avoid duplicates
            String email = facebookLead.fieldData.get('email');
            if (String.isNotBlank(email)) {
                List<Lead> existingLeads = [SELECT Id FROM Lead WHERE Email = :email LIMIT 1];
                if (!existingLeads.isEmpty()) {
                    System.debug('Duplicate lead found for email: ' + email);
                    return;
                }
            }
            
            // Create new Salesforce Lead
            Lead newLead = convertToSalesforceLead(facebookLead);
            
            if (newLead != null) {
                Database.SaveResult result = Database.insert(newLead, false);
                
                if (result.isSuccess()) {
                    System.debug('Successfully created lead: ' + result.getId());
                } else {
                    System.debug('Failed to create lead: ' + result.getErrors());
                }
            }
            
        } catch (Exception e) {
            System.debug('Error processing Facebook lead: ' + e.getMessage());
        }
    }
    
    /**
     * Convert FacebookLead to Salesforce Lead object
     */
    private static Lead convertToSalesforceLead(FacebookLead fbLead) {
        Lead sfLead = new Lead();
        
        // Map common fields
        if (fbLead.fieldData.containsKey('first_name')) {
            sfLead.FirstName = fbLead.fieldData.get('first_name');
        }
        
        if (fbLead.fieldData.containsKey('last_name')) {
            sfLead.LastName = fbLead.fieldData.get('last_name');
        }
        
        // Handle full name if first/last not separate
        if (fbLead.fieldData.containsKey('full_name') && String.isBlank(sfLead.FirstName)) {
            String[] nameParts = fbLead.fieldData.get('full_name').split(' ', 2);
            if (nameParts.size() > 0) {
                sfLead.FirstName = nameParts[0];
                if (nameParts.size() > 1) {
                    sfLead.LastName = nameParts[1];
                }
            }
        }
        
        if (fbLead.fieldData.containsKey('email')) {
            sfLead.Email = fbLead.fieldData.get('email');
        }
        
        if (fbLead.fieldData.containsKey('phone_number')) {
            sfLead.Phone = fbLead.fieldData.get('phone_number');
        }
        
        if (fbLead.fieldData.containsKey('company_name')) {
            sfLead.Company = fbLead.fieldData.get('company_name');
        } else if (String.isNotBlank(sfLead.FirstName) && String.isNotBlank(sfLead.LastName)) {
            sfLead.Company = sfLead.FirstName + ' ' + sfLead.LastName; // Required field
        } else {
            sfLead.Company = 'Facebook Lead'; // Fallback
        }
        
        // Set lead source and description
        sfLead.LeadSource = 'Facebook';
        sfLead.Description = 'Facebook Lead ID: ' + fbLead.facebookId + 
                           '\nCreated: ' + fbLead.createdTime;
        
        // Add any additional custom field mappings here
        // Example: sfLead.Custom_Field__c = fbLead.fieldData.get('facebook_field_name');
        
        return sfLead;
    }
}