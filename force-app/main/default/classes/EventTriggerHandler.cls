public class EventTriggerHandler {

    public static void updateCustomLeadSiteVisit(List<Event> eventList, Boolean isDelete) {

        Set<Id> leadIds = new Set<Id>();

        // Identify custom Lead using WhatId prefix 'a0'
        for (Event ev : eventList) {
            if (ev.WhatId != null && ev.WhatId.getSObjectType() == Lead__c.SObjectType) {
                leadIds.add(ev.WhatId);
            }
        }

        if (leadIds.isEmpty()) return;

        // Query remaining or updated latest events
        List<Event> latestEvents = [
            SELECT Id, StartDateTime, WhatId
            FROM Event
            WHERE WhatId IN :leadIds
            ORDER BY StartDateTime DESC
        ];

        // Map of Latest Event
        Map<Id, DateTime> leadLatestDateMap = new Map<Id, DateTime>();

        for (Event ev : latestEvents) {
            if (!leadLatestDateMap.containsKey(ev.WhatId)) {
                leadLatestDateMap.put(ev.WhatId, ev.StartDateTime);
            }
        }

        List<Lead__c> leadsToUpdate = new List<Lead__c>();

        for (Id leadId : leadIds) {

            Lead__c ld = new Lead__c();
            ld.Id = leadId;

            if (leadLatestDateMap.containsKey(leadId)) {
                // Update with latest StartDateTime
                ld.Site_Visit__c = leadLatestDateMap.get(leadId);
            } else {
                // No events left → clear the field
                ld.Site_Visit__c = null;
            }

            leadsToUpdate.add(ld);
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}