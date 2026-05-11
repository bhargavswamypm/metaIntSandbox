public class WebToLeadController {
    
    public Lead__c lead { get; set; }
    public Boolean showSuccess { get; set; }
    public Boolean showError { get; set; }
    public String errorMessage { get; set; }
    
    public WebToLeadController() {
        lead = new Lead__c();
        showSuccess = false;
        showError = false;
    }
    
    public PageReference submitLead() {
        showSuccess = false;
        showError = false;
        
        try {
            // Validate required fields
            if (String.isBlank(lead.Last_Name__c)) {
                throw new CustomException('Last Name is required');
            }
            
            if (String.isBlank(lead.Company__c)) {
                throw new CustomException('Company is required');
            }
            
            if (String.isBlank(lead.Lead_Type__c)) {
                throw new CustomException('Lead Type is required');
            }
            
            if (String.isBlank(lead.Property_Interested_in__c)) {
                throw new CustomException('Property is required');
            }
            
            // Set default Lead Status if not provided
            if (String.isBlank(lead.Lead_Status__c)) {
                lead.Lead_Status__c = 'Open';
            }
            
            // Insert the lead record
            insert lead;
            
            // Show success message
            showSuccess = true;
            
            // Reset the form
            lead = new Lead__c();
            
            return null;
            
        } catch (DmlException e) {
            showError = true;
            errorMessage = 'Error saving lead: ' + e.getDmlMessage(0);
            return null;
        } catch (Exception e) {
            showError = true;
            errorMessage = e.getMessage();
            return null;
        }
    }
    
    public PageReference reset() {
        lead = new Lead__c();
        showSuccess = false;
        showError = false;
        return null;
    }
    
    // Custom exception class
    public class CustomException extends Exception {}
}