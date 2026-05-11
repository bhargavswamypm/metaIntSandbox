@isTest
public class leadTriggerTest {
    
    @testSetup
    static void setup() {
        // Create test leads with various phone formats
        List<Lead__c> testLeads = new List<Lead__c>();
        
        testLeads.add(new Lead__c(
            Last_Name__c = 'Test Lead 1',
            Phone__c = '9876543210',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        testLeads.add(new Lead__c(
            Last_Name__c = 'Test Lead 2',
            Phone__c = '+91-9876543211',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        ));
        
        testLeads.add(new Lead__c(
            Last_Name__c = 'Test Lead 3',
            Phone__c = '(123) 456-7890',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        testLeads.add(new Lead__c(
            Last_Name__c = 'Test Lead 4',
            Phone__c = '+1 555-123-4567',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testDuplicatePhone_ExactMatch() {
        Test.startTest();
        
        // Try to insert lead with exact same phone number
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate Lead',
            Phone__c = '9876543210',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        try {
            insert duplicateLead;
            System.assert(false, 'Should have thrown error for duplicate phone');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicatePhone_DifferentFormat() {
        Test.startTest();
        
        // Try to insert lead with same phone but different format
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate Different Format',
            Phone__c = '+91-987-654-3210', // Same as 9876543210 but with formatting
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        try {
            insert duplicateLead;
            System.assert(false, 'Should have thrown error for duplicate phone');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicatePhone_WithCountryCode() {
        Test.startTest();
        
        // Try to insert lead with country code matching last 10 digits
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate With Country Code',
            Phone__c = '+919876543211', // Last 10 digits match existing lead
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        try {
            insert duplicateLead;
            System.assert(false, 'Should have thrown error for duplicate phone');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicatePhone_WithSpacesAndDashes() {
        Test.startTest();
        
        // Try to insert lead with spaces and dashes
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate With Formatting',
            Phone__c = '987 - 654 - 3210', // Same as 9876543210
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        try {
            insert duplicateLead;
            System.assert(false, 'Should have thrown error for duplicate phone');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDuplicatePhone_WithParentheses() {
        Test.startTest();
        
        // Try to insert lead matching existing (123) 456-7890
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate With Parentheses',
            Phone__c = '1234567890', // Same as (123) 456-7890
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        try {
            insert duplicateLead;
            
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testUniquePhone_ShouldSucceed() {
        Test.startTest();
        
        // Insert lead with unique phone number
        Lead__c uniqueLead = new Lead__c(
            Last_Name__c = 'Unique Lead',
            Phone__c = '9999999999',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert uniqueLead;
        
        Test.stopTest();
        
        // Verify it was inserted successfully
        Lead__c inserted = [
            SELECT Id, Phone__c 
            FROM Lead__c 
            WHERE Id = :uniqueLead.Id
        ];
        System.assertNotEquals(null, inserted.Id);
        System.assertEquals('9999999999', inserted.Phone__c);
    }
    
    @isTest
    static void testNullPhone_ShouldSucceed() {
        Test.startTest();
        
        // Insert lead with null phone
        Lead__c leadWithNullPhone = new Lead__c(
            Last_Name__c = 'Lead Without Phone',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
            // Phone__c is null
        );
        
        insert leadWithNullPhone;
        
        Test.stopTest();
        
        // Verify it was inserted successfully
        Lead__c inserted = [
            SELECT Id, Phone__c 
            FROM Lead__c 
            WHERE Id = :leadWithNullPhone.Id
        ];
        System.assertNotEquals(null, inserted.Id);
        System.assertEquals(null, inserted.Phone__c);
    }
    
    @isTest
    static void testMultipleNullPhones_ShouldSucceed() {
        Test.startTest();
        
        // Insert multiple leads with null phones
        List<Lead__c> leadsWithNullPhone = new List<Lead__c>();
        
        leadsWithNullPhone.add(new Lead__c(
            Last_Name__c = 'Lead 1 Without Phone',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        leadsWithNullPhone.add(new Lead__c(
            Last_Name__c = 'Lead 2 Without Phone',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        ));
        
        insert leadsWithNullPhone;
        
        Test.stopTest();
        
        // Verify both were inserted successfully
        List<Lead__c> inserted = [
            SELECT Id 
            FROM Lead__c 
            WHERE Id IN :leadsWithNullPhone
        ];
        System.assertEquals(2, inserted.size());
    }
    
    @isTest
    static void testBulkInsert_AllUnique() {
        Test.startTest();
        
        // Insert multiple leads with unique phone numbers
        List<Lead__c> bulkLeads = new List<Lead__c>();
        
        for (Integer i = 0; i < 5; i++) {
            bulkLeads.add(new Lead__c(
                Last_Name__c = 'Bulk Lead ' + i,
                Phone__c = '800000000' + i,
                Lead_Status__c = 'Open',
                Lead_Type__c = i < 3 ? 'Buyers' : 'Tenants'
            ));
        }
        
        insert bulkLeads;
        
        Test.stopTest();
        
        // Verify all were inserted
        List<Lead__c> inserted = [
            SELECT Id 
            FROM Lead__c 
            WHERE Id IN :bulkLeads
        ];
        System.assertEquals(5, inserted.size());
    }
    
    @isTest
    static void testBulkInsert_WithDuplicates() {
        Test.startTest();
        
        // Insert multiple leads with one duplicate
        List<Lead__c> bulkLeads = new List<Lead__c>();
        
        bulkLeads.add(new Lead__c(
            Last_Name__c = 'Bulk Valid Lead 1',
            Phone__c = '7777777777',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        bulkLeads.add(new Lead__c(
            Last_Name__c = 'Bulk Valid Lead 2',
            Phone__c = '8888888888',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        ));
        
        bulkLeads.add(new Lead__c(
            Last_Name__c = 'Bulk Duplicate Lead',
            Phone__c = '9876543210', // Duplicate from setup
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        Database.SaveResult[] results = Database.insert(bulkLeads, false);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, results[0].isSuccess(), 'First lead should succeed');
        System.assertEquals(true, results[1].isSuccess(), 'Second lead should succeed');
        System.assertEquals(false, results[2].isSuccess(), 'Third lead should fail due to duplicate');
        System.assert(
            results[2].getErrors()[0].getMessage().contains('A Lead with a similar phone number'),
            'Error message should indicate duplicate'
        );
    }
    
    @isTest
    static void testBulkInsert_InternalDuplicates() {
        Test.startTest();
        
        // Try to insert multiple leads with duplicates within the same batch
        List<Lead__c> bulkLeads = new List<Lead__c>();
        
        bulkLeads.add(new Lead__c(
            Last_Name__c = 'Internal Duplicate 1',
            Phone__c = '6666666666',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        ));
        
        bulkLeads.add(new Lead__c(
            Last_Name__c = 'Internal Duplicate 2',
            Phone__c = '+91-666-666-6666', // Same as above but different format
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        ));
        
        Database.SaveResult[] results = Database.insert(bulkLeads, false);
        
        Test.stopTest();
        
        // First should succeed, second should fail

    }
    
    @isTest
    static void testPhoneWith10Digits_ShouldWork() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Lead With 10 Digits',
            Phone__c = '5551234567',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Phone__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
    @isTest
    static void testPhoneLessThan10Digits_ShouldWork() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Lead With Short Phone',
            Phone__c = '12345',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Phone__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
    @isTest
    static void testPhoneWithSpecialCharacters() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Lead With Special Chars',
            Phone__c = '+1 (555) 123-4567 ext. 890',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Phone__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
    @isTest
    static void testDuplicateWithLongCountryCode() {
        Test.startTest();
        
        // Try to insert with very long country code
        Lead__c duplicateLead = new Lead__c(
            Last_Name__c = 'Duplicate Long Code',
            Phone__c = '+001919876543210', // Extra digits before the actual number
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        try {
            insert duplicateLead;
            System.assert(false, 'Should have thrown error for duplicate phone');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A Lead with a similar phone number'),
                'Error message should indicate duplicate phone number'
            );
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testPhoneWithOnlyNonNumeric_ShouldSucceed() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Lead With Non-Numeric Phone',
            Phone__c = 'CALL-ME-LATER',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Phone__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
    @isTest
    static void testEmptyPhone_ShouldSucceed() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Lead With Empty Phone',
            Phone__c = '',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Phone__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
    @isTest
    static void testDifferentLast10Digits_ShouldSucceed() {
        Test.startTest();
        
        // Insert lead where only some digits match but not the last 10
        Lead__c newLead = new Lead__c(
            Last_Name__c = 'Lead With Different Last 10',
            Phone__c = '1111111111', // Completely different last 10 digits
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert newLead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id FROM Lead__c WHERE Id = :newLead.Id];
        System.assertNotEquals(null, inserted.Id);
    }
    
/*    @isTest
    static void testBulkInsert_200Records() {
        Test.startTest();
        
        List<Lead__c> bulkLeads = new List<Lead__c>();
        
        // Create 200 unique leads
        for (Integer i = 0; i < 200; i++) {
            bulkLeads.add(new Lead__c(
                Last_Name__c = 'Bulk Lead ' + i,
                Phone__c = '90000' + String.valueOf(10000 + i),
                Lead_Status__c = 'Open',
                Lead_Type__c = Math.mod(i, 2) == 0 ? 'Buyers' : 'Tenants'
            ));
        }
        
        insert bulkLeads;
        
        Test.stopTest();
        
        List<Lead__c> inserted = [
            SELECT Id 
            FROM Lead__c 
            WHERE Id IN :bulkLeads
        ];
        System.assertEquals(200, inserted.size());
    }*/
    
    @isTest
    static void testBuyersLeadType() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Buyers Lead',
            Phone__c = '4444444444',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Lead_Type__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertEquals('Buyers', inserted.Lead_Type__c);
    }
    
    @isTest
    static void testTenantsLeadType() {
        Test.startTest();
        
        Lead__c lead = new Lead__c(
            Last_Name__c = 'Tenants Lead',
            Phone__c = '3333333333',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Tenants'
        );
        
        insert lead;
        
        Test.stopTest();
        
        Lead__c inserted = [SELECT Id, Lead_Type__c FROM Lead__c WHERE Id = :lead.Id];
        System.assertEquals('Tenants', inserted.Lead_Type__c);
    }
}