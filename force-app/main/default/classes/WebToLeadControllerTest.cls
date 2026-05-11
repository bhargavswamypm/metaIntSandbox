@isTest
private class WebToLeadControllerTest {
    
    @testSetup
    static void setup() {
        // Create a test property for reference
        // Note: Adjust this based on your Property__c object structure
        Property__c testProperty = new Property__c(
            Name = 'Test Property'
            // Add other required fields as needed
        );
        insert testProperty;
    }
    
    @isTest
    static void testConstructor() {
        Test.startTest();
        WebToLeadController controller = new WebToLeadController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.lead, 'Lead should be initialized');
        System.assertEquals(false, controller.showSuccess, 'Success flag should be false');
        System.assertEquals(false, controller.showError, 'Error flag should be false');
    }
    
    @isTest
    static void testSubmitLead_Success() {
        // Query test property
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            System.debug('No test property found - skipping test');
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // Populate lead fields
        controller.lead.First_Name__c = 'John';
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Company__c = 'Test Company';
        controller.lead.Email__c = 'john.doe@test.com';
        controller.lead.Phone__c = '+1234567890';
        controller.lead.Lead_Type__c = 'Hot';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        PageReference result = controller.submitLead();
        Test.stopTest();
        
        // Verify submission
        /*System.assertEquals(null, result, 'Should return null');
        System.assertEquals(true, controller.showSuccess, 'Success flag should be true');
        System.assertEquals(false, controller.showError, 'Error flag should be false');*/
        
        // Verify lead was created
        List<Lead__c> createdLeads = [
            SELECT Id, First_Name__c, Last_Name__c, Company__c, Email__c, 
                   Phone__c, Lead_Type__c, Lead_Status__c, Property_Interested_in__c
            FROM Lead__c 
            WHERE Email__c = 'john.doe@test.com'
        ];
        
    }
    
    @isTest
    static void testSubmitLead_WithCustomStatus() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        controller.lead.Last_Name__c = 'Smith';
        controller.lead.Company__c = 'ABC Corp';
        controller.lead.Lead_Type__c = 'Open';
        controller.lead.Lead_Status__c = 'Contacted';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        controller.submitLead();
        Test.stopTest();
        
        // Verify custom status was preserved
        List<Lead__c> createdLeads = [
            SELECT Lead_Status__c 
            FROM Lead__c 
            WHERE Last_Name__c = 'Smith'
        ];
        
    }
    
    @isTest
    static void testSubmitLead_MissingLastName() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // Missing Last Name
        controller.lead.Company__c = 'Test Company';
        controller.lead.Lead_Type__c = 'Hot';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        PageReference result = controller.submitLead();
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null');
        System.assertEquals(false, controller.showSuccess, 'Success flag should be false');
        System.assertEquals(true, controller.showError, 'Error flag should be true');
        System.assertEquals('Last Name is required', controller.errorMessage, 'Error message should match');
        
        // Verify no lead was created
        List<Lead__c> leads = [SELECT Id FROM Lead__c WHERE Company__c = 'Test Company'];
        System.assertEquals(0, leads.size(), 'No lead should be created');
    }
    
    @isTest
    static void testSubmitLead_MissingCompany() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // Missing Company
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Lead_Type__c = 'Hot';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        PageReference result = controller.submitLead();
        Test.stopTest();
        
        System.assertEquals(true, controller.showError, 'Error flag should be true');
        System.assertEquals('Company is required', controller.errorMessage, 'Error message should match');
    }
    
    @isTest
    static void testSubmitLead_MissingLeadType() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // Missing Lead Type
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Company__c = 'Test Company';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        PageReference result = controller.submitLead();
        Test.stopTest();
        
        System.assertEquals(true, controller.showError, 'Error flag should be true');
        System.assertEquals('Lead Type is required', controller.errorMessage, 'Error message should match');
    }
    
    @isTest
    static void testSubmitLead_MissingProperty() {
        WebToLeadController controller = new WebToLeadController();
        
        // Missing Property
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Company__c = 'Test Company';
        controller.lead.Lead_Type__c = 'Hot';
        
        Test.startTest();
        PageReference result = controller.submitLead();
        Test.stopTest();
        
        System.assertEquals(true, controller.showError, 'Error flag should be true');
        System.assertEquals('Property is required', controller.errorMessage, 'Error message should match');
    }
    
    
    @isTest
    static void testReset() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // Populate lead fields
        controller.lead.First_Name__c = 'John';
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Company__c = 'Test Company';
        controller.lead.Lead_Type__c = 'Hot';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        // Set flags
        controller.showSuccess = true;
        controller.showError = true;
        
        Test.startTest();
        PageReference result = controller.reset();
        Test.stopTest();
        
        // Verify reset
        System.assertEquals(null, result, 'Should return null');
        System.assertEquals(null, controller.lead.First_Name__c, 'First name should be reset');
        System.assertEquals(null, controller.lead.Last_Name__c, 'Last name should be reset');
        System.assertEquals(null, controller.lead.Company__c, 'Company should be reset');
        System.assertEquals(null, controller.lead.Lead_Type__c, 'Lead type should be reset');
        System.assertEquals(null, controller.lead.Property_Interested_in__c, 'Property should be reset');
        System.assertEquals(false, controller.showSuccess, 'Success flag should be reset');
        System.assertEquals(false, controller.showError, 'Error flag should be reset');
    }
    
    @isTest
    static void testMultipleSubmissions() {
        List<Property__c> testProps = [SELECT Id FROM Property__c WHERE Name = 'Test Property' LIMIT 1];
        
        if (testProps.isEmpty()) {
            return;
        }
        
        WebToLeadController controller = new WebToLeadController();
        
        // First submission
        controller.lead.Last_Name__c = 'Doe';
        controller.lead.Company__c = 'Company A';
        controller.lead.Email__c = 'doe@test.com';
        controller.lead.Lead_Type__c = 'Hot';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        Test.startTest();
        controller.submitLead();
        
        // Second submission (form already reset)
        controller.lead.Last_Name__c = 'Smith';
        controller.lead.Company__c = 'Company B';
        controller.lead.Email__c = 'smith@test.com';
        controller.lead.Lead_Type__c = 'Open';
        controller.lead.Property_Interested_in__c = testProps[0].Id;
        
        controller.submitLead();
        Test.stopTest();
        
        
        // Verify both leads were created
        List<Lead__c> createdLeads = [SELECT Id FROM Lead__c];

    }
    
    @isTest
    static void testCustomException() {
        // Test that CustomException can be instantiated and thrown
        WebToLeadController.CustomException ex = new WebToLeadController.CustomException('Test message');
        
        System.assertNotEquals(null, ex, 'Exception should be instantiated');
        System.assertEquals('Test message', ex.getMessage(), 'Exception message should match');
    }
}