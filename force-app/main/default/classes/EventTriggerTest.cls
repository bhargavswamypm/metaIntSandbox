@isTest
public class EventTriggerTest {

    @testSetup
    static void setupData() {
        // Create Leads
        List<Lead__c> leads = new List<Lead__c>{
            new Lead__c(Last_Name__c='Lead One',Phone__c = '9876543210',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers'),
            new Lead__c(Last_Name__c='Lead Two',Phone__c = '9876543212',
            Lead_Status__c = 'Open',
            Lead_Type__c = 'Buyers')
        };
        insert leads;

        // Create initial Events for Lead One
        List<Event> evts = new List<Event>{
            new Event(
                Subject='Visit 1',
                StartDateTime=System.now().addDays(-2),
                EndDateTime=System.now().addDays(-2).addHours(1),
                WhatId=leads[0].Id
            ),
            new Event(
                Subject='Visit 2',
                StartDateTime=System.now().addDays(-1),
                EndDateTime=System.now().addDays(-1).addHours(1),
                WhatId=leads[0].Id
            )
        };
        insert evts;
    }

    @isTest
    static void testInsertEventUpdatesLead() {

        Lead__c lead = [SELECT Id, Site_Visit__c FROM Lead__c WHERE Last_Name__c='Lead One' LIMIT 1];

        // Latest event should be Visit 2 (yesterday)
        System.assertNotEquals(null, lead.Site_Visit__c, 'Site Visit should be populated after insert');
    }

    @isTest
    static void testUpdateEventChangesLatestVisit() {

        Lead__c lead = [SELECT Id FROM Lead__c WHERE Last_Name__c='Lead One' LIMIT 1];

        // Create a new event with an even newer date → latest
        Event newEvt = new Event(
            Subject='Updated Visit',
            StartDateTime=System.now(),
            EndDateTime=System.now().addHours(1),
            WhatId=lead.Id
        );
        insert newEvt;

        Lead__c updatedLead = [SELECT Site_Visit__c FROM Lead__c WHERE Id=:lead.Id];

        System.assertEquals(
            newEvt.StartDateTime,
            updatedLead.Site_Visit__c,
            'Lead should update to newest event date'
        );
    }

    @isTest
    static void testDeleteEventClearsOrUpdatesLead() {

        Lead__c lead = [SELECT Id FROM Lead__c WHERE Last_Name__c='Lead One' LIMIT 1];

        // Fetch all events for this Lead
        List<Event> evts = [
            SELECT Id, StartDateTime 
            FROM Event 
            WHERE WhatId=:lead.Id 
            ORDER BY StartDateTime DESC
        ];

        // DELETE latest event (highest StartDateTime)
        delete evts[0];

        // After deleting latest, Lead should now have next latest date
        Lead__c updatedLead = [
            SELECT Site_Visit__c 
            FROM Lead__c 
            WHERE Id=:lead.Id
        ];

        System.assertEquals(
            evts[1].StartDateTime,
            updatedLead.Site_Visit__c,
            'Lead should fallback to second latest event'
        );

        // Delete all events → Lead.Site_Visit__c must clear
        delete evts[1];

        Lead__c clearedLead = [
            SELECT Site_Visit__c 
            FROM Lead__c 
            WHERE Id=:lead.Id
        ];

        System.assertEquals(
            null,
            clearedLead.Site_Visit__c,
            'Lead Site Visit must be cleared when all events deleted'
        );
    }

    @isTest
    static void testBulkInsert() {

        List<Lead__c> leads = [
            SELECT Id FROM Lead__c WHERE Last_Name__c IN ('Lead One','Lead Two')
        ];

        List<Event> bulkEvents = new List<Event>();
        for (Lead__c ld : leads) {
            bulkEvents.add(new Event(
                Subject='Bulk Visit',
                StartDateTime=System.now(),
                EndDateTime=System.now().addHours(1),
                WhatId=ld.Id
            ));
        }
        insert bulkEvents;

        Map<Id, Lead__c> updatedLeads = new Map<Id, Lead__c>(
            [SELECT Id, Site_Visit__c FROM Lead__c WHERE Id IN :leads]
        );

        for (Lead__c ld : leads) {
            System.assertNotEquals(
                null, 
                updatedLeads.get(ld.Id).Site_Visit__c,
                'Each lead should have updated Site Visit after bulk insert'
            );
        }
    }
}