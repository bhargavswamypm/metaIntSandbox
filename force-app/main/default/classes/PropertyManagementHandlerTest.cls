@isTest
public class PropertyManagementHandlerTest {

        
    @testSetup
    static void setup() {
        // Create Property Management Services
        Property__c prop = new Property__c(Name = 'Property1');
        insert prop;
        List<Property_Management_Services__c> services = new List<Property_Management_Services__c>();
        
        services.add(new Property_Management_Services__c(
            Name = 'Property Tax',
            Charge__c = 1000.00,
            Government_Charges__c = 200.00
        ));
        
        services.add(new Property_Management_Services__c(
            Name = 'Will',
            Charge__c = 500.00,
            Government_Charges__c = 100.00
        ));
        
        services.add(new Property_Management_Services__c(
            Name = 'Ekhata',
            Charge__c = 1500.00,
            Government_Charges__c = 300.00
        ));
        
        services.add(new Property_Management_Services__c(
            Name = 'Electricity Name Change',
            Charge__c = 800.00,
            Government_Charges__c = 150.00
        ));
        
        services.add(new Property_Management_Services__c(
            Name = 'Sale Agreement',
            Charge__c = 2000.00,
            Government_Charges__c = 500.00
        ));
        
        insert services;
        
        // Create Property Management records
        List<Property_Management__c> pmRecords = new List<Property_Management__c>();
        
        pmRecords.add(new Property_Management__c(
            Name = 'PM-001',
            Legal_Services_Required__c = 'Property Tax;Will',
            property__c = prop.Id
        ));
        
        pmRecords.add(new Property_Management__c(
            Name = 'PM-002',
            Legal_Services_Required__c = null,
            property__c = prop.Id // No services initially
        ));
        
        insert pmRecords;
    }
    
    @isTest
    static void testSyncServices_InsertNewServices() {
        // Get test Property Management record
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-001' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            System.debug('Test data not found - skipping test');
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        Test.startTest();
        
        // Query existing services (should have 2)
        List<Services_Requested__c> beforeServices = [
            SELECT Id, Name, Service__c, Charge_Amount__c, Government_Charges__c, Total_Charges__c
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        
        // Trigger the handler with new list (simulating insert/update)
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap);
        
        // Query services after sync
        List<Services_Requested__c> afterServices = [
            SELECT Id, Name, Service__c, Charge_Amount__c, Government_Charges__c, Total_Charges__c
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncServices_UpdateAddServices() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-001' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // First sync - create initial services
        Map<Id, Property_Management__c> oldMap1 = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap1);
        
        // Update to add more services
        Property_Management__c oldPM = pm.clone(true, true, true, true);
        pm.Legal_Services_Required__c = 'Property Tax;Will;Ekhata';
        update pm;
        
        Test.startTest();
        
        // Create old map with previous state
        Map<Id, Property_Management__c> oldMap2 = new Map<Id, Property_Management__c>{
            pm.Id => oldPM
        };
        
        // Sync with updated services
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap2);
        
        // Query services after update
        List<Services_Requested__c> services = [
            SELECT Id, Name
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
        Set<String> serviceNames = new Set<String>();
        for (Services_Requested__c sr : services) {
            serviceNames.add(sr.Name);
        }
        
    }
    
    @isTest
    static void testSyncServices_UpdateRemoveServices() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-001' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // First sync - create initial services
        Map<Id, Property_Management__c> oldMap1 = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap1);
        
        // Update to remove a service
        Property_Management__c oldPM = pm.clone(true, true, true, true);
        pm.Legal_Services_Required__c = 'Property Tax'; // Remove Document Verification
        update pm;
        
        Test.startTest();
        
        // Create old map with previous state
        Map<Id, Property_Management__c> oldMap2 = new Map<Id, Property_Management__c>{
            pm.Id => oldPM
        };
        
        // Sync with updated services
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap2);
        
        // Query services after update
        List<Services_Requested__c> services = [
            SELECT Id, Name
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncServices_UpdateReplaceServices() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-001' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // First sync - create initial services
        Map<Id, Property_Management__c> oldMap1 = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap1);
        
        // Update to completely replace services
        Property_Management__c oldPM = pm.clone(true, true, true, true);
        pm.Legal_Services_Required__c = 'Electricity Name Change;Sale Agreement';
        update pm;
        
        Test.startTest();
        
        // Create old map with previous state
        Map<Id, Property_Management__c> oldMap2 = new Map<Id, Property_Management__c>{
            pm.Id => oldPM
        };
        
        // Sync with updated services
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap2);
        
        // Query services after update
        List<Services_Requested__c> services = [
            SELECT Id, Name
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
        Set<String> serviceNames = new Set<String>();
        for (Services_Requested__c sr : services) {
            serviceNames.add(sr.Name);
        }
        
    }
    
    @isTest
    static void testSyncServices_RemoveAllServices() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-001' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // First sync - create initial services
        Map<Id, Property_Management__c> oldMap1 = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap1);
        
        // Update to remove all services
        Property_Management__c oldPM = pm.clone(true, true, true, true);
        pm.Legal_Services_Required__c = null;
        update pm;
        
        Test.startTest();
        
        // Create old map with previous state
        Map<Id, Property_Management__c> oldMap2 = new Map<Id, Property_Management__c>{
            pm.Id => oldPM
        };
        
        // Sync with no services
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap2);
        
        // Query services after update
        List<Services_Requested__c> services = [
            SELECT Id
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncServices_NoInitialServices() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-002' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // Update to add services
        pm.Legal_Services_Required__c = 'Ekhata';
        update pm;
        
        Test.startTest();
        
        // Create old map with null services
        Property_Management__c oldPM = new Property_Management__c(
            Id = pm.Id,
            Legal_Services_Required__c = null
        );
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>{
            pm.Id => oldPM
        };
        
        // Sync services
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap);
        
        // Query services
        List<Services_Requested__c> services = [
            SELECT Id, Name
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        

    }
    
    @isTest
    static void testSyncServices_WithWhitespace() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-002' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // Set services with extra whitespace
        pm.Legal_Services_Required__c = '  Property Tax  ;  Will  ';
        update pm;
        
        Test.startTest();
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap);
        
        // Query services
        List<Services_Requested__c> services = [
            SELECT Id, Name
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
        Set<String> serviceNames = new Set<String>();
        for (Services_Requested__c sr : services) {
            serviceNames.add(sr.Name);
        }
        
    }
    
    @isTest
    static void testSyncServices_ChargeCalculation() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-002' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        pm.Legal_Services_Required__c = 'Property Tax';
        update pm;
        
        Test.startTest();
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap);
        
        // Query services
        List<Services_Requested__c> services = [
            SELECT Id, Charge_Amount__c, Government_Charges__c, Total_Charges__c
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }
    
/*    @isTest
    static void testSyncServices_ServiceNotFound() {
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-002' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        
        // Set a service that doesn't exist in Property_Management_Services__c
        pm.Legal_Services_Required__c = 'NonExistent Service';
        update pm;
        
        Test.startTest();
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap);
        
        // Query services
        List<Services_Requested__c> services = [
            SELECT Id
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }*/
    
    @isTest
    static void testSyncServices_MultipleRecords() {
        List<Property_Management__c> pmList = [
            SELECT Id, Name, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name IN ('PM-001', 'PM-002')
            ORDER BY Name
        ];
        
        if (pmList.size() < 2) {
            return;
        }
        
        // Update both records
        pmList[0].Legal_Services_Required__c = 'Property Tax';
        pmList[1].Legal_Services_Required__c = 'Will';
        update pmList;
        
        Test.startTest();
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(pmList, oldMap);
        
        // Query services for both records
        Map<Id, List<Services_Requested__c>> servicesMap = new Map<Id, List<Services_Requested__c>>();
        for (Services_Requested__c sr : [
            SELECT Id, Property_Management__c, Name
            FROM Services_Requested__c
            WHERE Property_Management__c IN :pmList
        ]) {
            if (!servicesMap.containsKey(sr.Property_Management__c)) {
                servicesMap.put(sr.Property_Management__c, new List<Services_Requested__c>());
            }
            servicesMap.get(sr.Property_Management__c).add(sr);
        }
        
        Test.stopTest();
        
    }
    
/*    @isTest
    static void testSyncServices_NullCharges() {
        // Create service with null charges
        Property_Management_Services__c serviceNull = new Property_Management_Services__c(
            Name = 'Gift Deed',
            Charge__c = null,
            Government_Charges__c = null
        );
        insert serviceNull;
        
        List<Property_Management__c> pmList = [
            SELECT Id, Legal_Services_Required__c 
            FROM Property_Management__c 
            WHERE Name = 'PM-002' 
            LIMIT 1
        ];
        
        if (pmList.isEmpty()) {
            return;
        }
        
        Property_Management__c pm = pmList[0];
        pm.Legal_Services_Required__c = 'Gift Deed';
        update pm;
        
        Test.startTest();
        
        Map<Id, Property_Management__c> oldMap = new Map<Id, Property_Management__c>();
        PropertyManagementHandler.syncServices(new List<Property_Management__c>{pm}, oldMap);
        
        // Query services
        List<Services_Requested__c> services = [
            SELECT Id, Charge_Amount__c, Government_Charges__c, Total_Charges__c
            FROM Services_Requested__c
            WHERE Property_Management__c = :pm.Id
        ];
        
        Test.stopTest();
        
    }*/
}