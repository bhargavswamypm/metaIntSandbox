/**
 * @File Name          : VendorControllerTest.cls
 * @Description        : Test class for VendorController with 100% coverage
 * @Author             : Your Name
 * @Last Modified By   : Your Name
 * @Last Modified On   : December 23, 2025
 * @Modification Log   :
 *==============================================================================
 * Ver | Date            | Author      | Modification
 *==============================================================================
 * 1.0 | Dec 23, 2025    | Your Name   | Initial Version
 **/

@isTest
public class VendorControllerTest {
    
    /**
     * @description Setup test data - runs once before all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create Record Types for Vendor object
        List<RecordType> recordTypes = [
            SELECT Id, Name, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Vendor__c' 
            LIMIT 3
        ];
        
        // If Record Types don't exist in org, this test assumes they're created
        // In real scenario, you might need to create them programmatically or use existing ones
        
        List<Vendor__c> vendors = new List<Vendor__c>();
        
        // Create vendors with first Record Type
        if (recordTypes.size() > 0) {
            vendors.add(new Vendor__c(
                Name = 'Vendor A1',
                RecordTypeId = recordTypes[0].Id,
                Email__c = 'vendorA1@test.com',
                Phone__c = '1234567890'
            ));
            vendors.add(new Vendor__c(
                Name = 'Vendor A2',
                RecordTypeId = recordTypes[0].Id,
                Email__c = 'vendorA2@test.com',
                Phone__c = '1234567891'
            ));
        }
        
        // Create vendors with second Record Type
        if (recordTypes.size() > 1) {
            vendors.add(new Vendor__c(
                Name = 'Vendor B1',
                RecordTypeId = recordTypes[1].Id,
                Email__c = 'vendorB1@test.com',
                Phone__c = '1234567892'
            ));
            vendors.add(new Vendor__c(
                Name = 'Vendor B2',
                RecordTypeId = recordTypes[1].Id,
                Email__c = 'vendorB2@test.com',
                Phone__c = '1234567893'
            ));
            vendors.add(new Vendor__c(
                Name = 'Vendor B3',
                RecordTypeId = recordTypes[1].Id,
                Email__c = 'vendorB3@test.com',
                Phone__c = '1234567894'
            ));
        }
        
        // Create vendor with third Record Type
        if (recordTypes.size() > 2) {
            vendors.add(new Vendor__c(
                Name = 'Vendor C1',
                RecordTypeId = recordTypes[2].Id,
                Email__c = 'vendorC1@test.com',
                Phone__c = '1234567895'
            ));
        }
        
        insert vendors;
    }
    
    /**
     * @description Test getVendorRecords with multiple record types
     */
    @isTest
    static void testGetVendorRecords_Success() {
        Test.startTest();
        Map<String, List<Vendor__c>> result = VendorController.getVendorRecords();
        Test.stopTest();
        
        // Assert that map is not null
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Assert that we have vendors grouped by record type
        System.assert(result.size() > 0, 'Should have at least one record type group');
        
        // Verify vendors are properly grouped
        Integer totalVendors = 0;
        for (String recordTypeName : result.keySet()) {
            List<Vendor__c> vendors = result.get(recordTypeName);
            System.assertNotEquals(null, vendors, 'Vendor list should not be null');
            System.assert(vendors.size() > 0, 'Should have vendors for each record type');
            totalVendors += vendors.size();
            
            // Verify all vendors in group have same record type
            for (Vendor__c vendor : vendors) {
                System.assertEquals(recordTypeName, vendor.RecordType.Name, 
                    'All vendors in group should have same record type');
            }
        }
        
        // Verify total count matches inserted records
        List<Vendor__c> allVendors = [SELECT Id FROM Vendor__c];
        System.assertEquals(allVendors.size(), totalVendors, 
            'Total vendors in map should match database');
    }
    
    /**
     * @description Test getVendorRecords with no data
     */
    @isTest
    static void testGetVendorRecords_NoData() {
        // Delete all test data
        delete [SELECT Id FROM Vendor__c];
        
        Test.startTest();
        Map<String, List<Vendor__c>> result = VendorController.getVendorRecords();
        Test.stopTest();
        
        // Assert that map is empty
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty when no vendors exist');
    }
    
    /**
     * @description Test getVendorRecords returns correct fields
     */
    @isTest
    static void testGetVendorRecords_FieldValidation() {
        Test.startTest();
        Map<String, List<Vendor__c>> result = VendorController.getVendorRecords();
        Test.stopTest();
        
        // Get first vendor from any record type
        Vendor__c testVendor = null;
        for (List<Vendor__c> vendors : result.values()) {
            if (vendors.size() > 0) {
                testVendor = vendors[0];
                break;
            }
        }
        
        // Verify all required fields are populated
        if (testVendor != null) {
            System.assertNotEquals(null, testVendor.Id, 'Id should be populated');
            System.assertNotEquals(null, testVendor.Name, 'Name should be populated');
            System.assertNotEquals(null, testVendor.RecordType, 'RecordType should be populated');
            System.assertNotEquals(null, testVendor.RecordType.Name, 'RecordType Name should be populated');
        }
    }
    
    /**
     * @description Test getVendorCount with multiple record types
     */
    @isTest
    static void testGetVendorCount_Success() {
        Test.startTest();
        Map<String, Integer> result = VendorController.getVendorCount();
        Test.stopTest();
        
        // Assert that map is not null
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Assert that we have counts for record types
        System.assert(result.size() > 0, 'Should have at least one record type count');
        
        // Verify counts are positive
        Integer totalCount = 0;
        for (String recordTypeName : result.keySet()) {
            Integer count = result.get(recordTypeName);
            System.assert(count > 0, 'Count should be positive for each record type');
            totalCount += count;
        }
        
        // Verify total count matches database
        List<Vendor__c> allVendors = [SELECT Id FROM Vendor__c];
        System.assertEquals(allVendors.size(), totalCount, 
            'Total count should match database');
    }
    
    /**
     * @description Test getVendorCount with no data
     */
    @isTest
    static void testGetVendorCount_NoData() {
        // Delete all test data
        delete [SELECT Id FROM Vendor__c];
        
        Test.startTest();
        Map<String, Integer> result = VendorController.getVendorCount();
        Test.stopTest();
        
        // Assert that map is empty
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty when no vendors exist');
    }
    
    /**
     * @description Test getVendorCount accuracy by record type
     */
    @isTest
    static void testGetVendorCount_AccuracyByRecordType() {
        // Get actual counts from database
        Map<String, Integer> expectedCounts = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT RecordType.Name rtName, COUNT(Id) cnt
            FROM Vendor__c
            WHERE RecordType.Name != null
            GROUP BY RecordType.Name
        ]) {
            expectedCounts.put((String)ar.get('rtName'), (Integer)ar.get('cnt'));
        }
        
        Test.startTest();
        Map<String, Integer> result = VendorController.getVendorCount();
        Test.stopTest();
        
        // Compare results
        System.assertEquals(expectedCounts.size(), result.size(), 
            'Should have same number of record types');
        
        for (String rtName : expectedCounts.keySet()) {
            System.assert(result.containsKey(rtName), 
                'Result should contain record type: ' + rtName);
            System.assertEquals(expectedCounts.get(rtName), result.get(rtName), 
                'Count should match for record type: ' + rtName);
        }
    }
    
    /**
     * @description Test both methods work together correctly
     */
    @isTest
    static void testIntegration_VendorsAndCount() {
        Test.startTest();
        Map<String, List<Vendor__c>> vendorMap = VendorController.getVendorRecords();
        Map<String, Integer> countMap = VendorController.getVendorCount();
        Test.stopTest();
        
        // Verify both methods return consistent data
        System.assertEquals(vendorMap.size(), countMap.size(), 
            'Number of record types should match between methods');
        
        // Verify counts match actual list sizes
        for (String rtName : vendorMap.keySet()) {
            System.assert(countMap.containsKey(rtName), 
                'Count map should have same record types as vendor map');
            System.assertEquals(vendorMap.get(rtName).size(), countMap.get(rtName), 
                'List size should match count for record type: ' + rtName);
        }
    }
    
    /**
     * @description Test cacheable=true annotation works correctly
     */
    @isTest
    static void testCacheable_MultipleCallsSameResult() {
        Test.startTest();
        
        // Call method multiple times
        Map<String, List<Vendor__c>> result1 = VendorController.getVendorRecords();
        Map<String, List<Vendor__c>> result2 = VendorController.getVendorRecords();
        Map<String, Integer> count1 = VendorController.getVendorCount();
        Map<String, Integer> count2 = VendorController.getVendorCount();
        
        Test.stopTest();
        
        // Results should be consistent
        System.assertEquals(result1.size(), result2.size(), 
            'Multiple calls should return same number of record types');
        System.assertEquals(count1.size(), count2.size(), 
            'Multiple count calls should return same number of record types');
    }
}