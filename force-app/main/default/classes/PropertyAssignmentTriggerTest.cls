@isTest
public class PropertyAssignmentTriggerTest {

    @testSetup
    static void setup() {

        // Create 2 test Properties
        List<Property__c> props = new List<Property__c>{
            new Property__c(Name = 'Prop A',Built_Up_Area__c = '1800', Asking_Price__c = 1010001),
            new Property__c(Name = 'Prop B',Built_Up_Area__c = '1800', Asking_Price__c = 1010001)
        };
        insert props;
    }

    // -------------------------------
    // Test Insert
    // -------------------------------
    @isTest
    static void testInsertAssignments() {

        Property__c p = [SELECT Id FROM Property__c WHERE Name = 'Prop A' LIMIT 1];

        List<Property_Assignment__c> assigns = new List<Property_Assignment__c>{
            new Property_Assignment__c(Name = 'Owner',Assignment_Type__c ='User', Property__c = p.Id),
            new Property_Assignment__c(Name = 'Agent 1',Assignment_Type__c ='Group', Property__c = p.Id)
        };
        insert assigns; // Trigger should fire

        Property__c updated = [SELECT Assigned_To__c FROM Property__c WHERE Id = :p.Id];

        System.assertEquals('Agent 1;Owner', updated.Assigned_To__c,
            'Names should be sorted alphabetically and concatenated');
    }

    // -------------------------------
    // Test Update
    // -------------------------------
    @isTest
    static void testUpdateAssignments() {

        Property__c p = [SELECT Id FROM Property__c WHERE Name = 'Prop A' LIMIT 1];

        Property_Assignment__c a = new Property_Assignment__c(
            Name = 'Manager',
            Property__c = p.Id,
            Assignment_Type__c ='User'
        );
        insert a;

        // Update name (trigger should reflect the change)
        a.Name = 'Super Manager';
        update a;

        Property__c updated = [SELECT Assigned_To__c FROM Property__c WHERE Id = :p.Id];

        System.assertEquals('Super Manager', updated.Assigned_To__c);
    }

    // -------------------------------
    // Test Delete
    // -------------------------------
    @isTest
    static void testDeleteAssignments() {

        Property__c p = [SELECT Id FROM Property__c WHERE Name = 'Prop A' LIMIT 1];

        // Insert assignment
        Property_Assignment__c a = new Property_Assignment__c(
            Name = 'Temp',
            Property__c = p.Id,
            Assignment_Type__c ='User'
        );
        insert a;

        // Delete it
        delete a;

        Property__c updated = [SELECT Assigned_To__c FROM Property__c WHERE Id = :p.Id];

    }

    // -------------------------------
    // Test Undelete
    // -------------------------------
    @isTest
    static void testUndeleteAssignments() {

        Property__c p = [SELECT Id FROM Property__c WHERE Name = 'Prop A' LIMIT 1];

        // Create and delete record
        Property_Assignment__c a = new Property_Assignment__c(
            Name = 'Recovered',
            Property__c = p.Id,
            Assignment_Type__c ='User'
        );
        insert a;
        delete a;

        // Undelete
        undelete a;

        Property__c updated = [SELECT Assigned_To__c FROM Property__c WHERE Id = :p.Id];

        System.assertEquals('Recovered', updated.Assigned_To__c);
    }

    // -------------------------------
    // Test Multiple Properties
    // -------------------------------
    @isTest
    static void testMultipleProperties() {

        List<Property__c> props = [
            SELECT Id, Name FROM Property__c WHERE Name IN ('Prop A', 'Prop B')
        ];

        Id pA = props[0].Id;
        Id pB = props[1].Id;

        insert new List<Property_Assignment__c>{
            new Property_Assignment__c(Name = 'A1', Property__c = pA,Assignment_Type__c ='User'),
            new Property_Assignment__c(Name = 'A2', Property__c = pA,Assignment_Type__c ='User'),
            new Property_Assignment__c(Name = 'B1', Property__c = pB,Assignment_Type__c ='User')
        };

        Map<Id, Property__c> mapProps = new Map<Id, Property__c>([
            SELECT Id, Assigned_To__c FROM Property__c WHERE Id IN :new Set<Id>{pA, pB}
        ]);

        System.assertEquals('A1;A2', mapProps.get(pA).Assigned_To__c);
        System.assertEquals('B1', mapProps.get(pB).Assigned_To__c);
    }
}