public with sharing class ZuciPortalController {

    // ─────────────────────────────────────────────
    // LEAD__C  (Custom Lead Object)
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Lead__c> getLeads() {
        return [
            SELECT 
                Id,
                Full_Name__c,
                Email__c,
                Phone__c,
                Lead_Source__c,
                Property_Interested_in__r.Name,
                Configuration__c,
                Lead_Status__c
            FROM Lead__c
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Lead__c getLeadById(Id leadId) {
        return [
            SELECT
                Id,
                Full_Name__c,
                Email__c,
                Phone__c,
                Lead_Status__c,
                Lead_Source__c,
                Property_Interested_in__c,
                Property_Interested_in__r.Name,
                Configuration__c
            FROM Lead__c
            WHERE Id = :leadId
            LIMIT 1
        ];
    }

    // ─────────────────────────────────────────────
    // PROPERTY__C  (Custom Property Object)
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Property__c> getProperties() {
        return [
            SELECT
                Id,
                Name,
                RecordType.Name,
                Asking_Price__c,
                Market_Price__c,
                Parent_Property__r.Name,
                Position__c,
                Built_Up_Area__c,
                Configuration__c,
                RecordTypeId
            FROM Property__c
            WHERE RecordType.Name != 'Parent_Property'
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Property__c getPropertyById(Id propertyId) {
        return [
            SELECT
                Id,
                Name,
                Position__c,
                Configuration__c,
                Facing__c,
                Built_Up_Area__c,
                Asking_Price__c,
                Market_Price__c,
                Bathrooms__c,
                Description__c,
                Parent_Property__r.Name,
                RecordType.Name
            FROM Property__c
            WHERE Id = :propertyId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Lead__c> getLeadsForProperty(Id propertyId) {
        return [
            SELECT
                Id,
                Full_Name__c,
                Phone__c,
                Email__c,
                Lead_Status__c,
                Lead_Source__c
            FROM Lead__c
            WHERE Property_Interested_in__c = :propertyId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getActivitiesForProperty(Id propertyId) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        // Tasks linked via WhatId to Property__c
        for (Task t : [
            SELECT Id, Subject, ActivityDate, Status, Priority, Description,
                   CallType, IsRecurrence, CreatedDate
            FROM Task
            WHERE WhatId = :propertyId
            ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC
            LIMIT 50
        ]) {
            result.add(new Map<String, Object>{
                'Id'           => t.Id,
                'Subject'      => t.Subject,
                'ActivityDate' => t.ActivityDate,
                'Status'       => t.Status,
                'Priority'     => t.Priority,
                'Description'  => t.Description,
                'CallType'     => t.CallType,
                'IsRecurrence' => t.IsRecurrence,
                'CreatedDate'  => t.CreatedDate,
                'RecordType'   => 'Task'
            });
        }

        // Events linked via WhatId to Property__c
        for (Event e : [
            SELECT Id, Subject, StartDateTime, EndDateTime, Description, CreatedDate
            FROM Event
            WHERE WhatId = :propertyId
            ORDER BY StartDateTime DESC NULLS LAST, CreatedDate DESC
            LIMIT 50
        ]) {
            result.add(new Map<String, Object>{
                'Id'            => e.Id,
                'Subject'       => e.Subject,
                'ActivityDate'  => e.StartDateTime,
                'StartDateTime' => e.StartDateTime,
                'EndDateTime'   => e.EndDateTime,
                'Description'   => e.Description,
                'CreatedDate'   => e.CreatedDate,
                'RecordType'    => 'Event'
            });
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<Site_Visit__c> getSiteVisitsForProperty(Id propertyId) {
        return [
            SELECT
                Id,
                Name,
                Visit_Date_Time__c,
                Status__c,
                Property_Manager1__c,
                Property_Manager1__r.Name,
                CustomLead__c,
                CustomLead__r.Full_Name__c,
                CreatedDate
            FROM Site_Visit__c
            WHERE Property__c = :propertyId
            ORDER BY Visit_Date_Time__c DESC NULLS LAST
            LIMIT 50
        ];
    }

    // ─────────────────────────────────────────────
    // CONTACT  (Standard Object)
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts() {
        return [
            SELECT
                Id,
                Name,
                FirstName,
                LastName,
                Email,
                MobilePhone,
                Title,
                Department,
                MailingAddress
            FROM Contact
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    // ─────────────────────────────────────────────
    // OPPORTUNITY__C  (Custom Opportunity Object)
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Opportunity__c> getOpportunities() {
        return [
            SELECT
                Id,
                Name,
                Stage__c,
                Amount__c,
                Property__r.Name
            FROM Opportunity__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    // ─────────────────────────────────────────────
    // PROPERTY DML
    // ─────────────────────────────────────────────
    @AuraEnabled
    public static void deleteProperty(Id recordId) {
        delete [SELECT Id FROM Property__c WHERE Id = :recordId];
    }

    // ─────────────────────────────────────────────
    // LEGACY: getPropertyDetail (Map-based, keep for
    // any existing components that reference it)
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPropertyDetail(Id propertyId) {
        Property__c prop = [
            SELECT Id, Name, RecordType.Name, RecordTypeId,
                   Asking_Price__c, Market_Price__c, Built_Up_Area__c,
                   Configuration__c, Bathrooms__c, Position__c,
                   Parent_Property__r.Name, Description__c
            FROM Property__c
            WHERE Id = :propertyId
            WITH USER_MODE
            LIMIT 1
        ];

        List<Site_Visit__c> siteVisits = [
            SELECT Id, Name, Visit_Date_Time__c, Status__c, Lead__r.Name
            FROM Site_Visit__c
            WHERE Property__c = :propertyId
            WITH USER_MODE
            ORDER BY Visit_Date_Time__c DESC
            LIMIT 50
        ];

        List<Lead__c> leads = [
            SELECT Id, Full_Name__c, Mobile__c, Email__c, Lead_Status__c
            FROM Lead__c
            WHERE Property_Interested_in__c = :propertyId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<Property_Document__c> docs = [
            SELECT Id, Name, Document_Type__c, CreatedDate
            FROM Property_Document__c
            WHERE Property__c = :propertyId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        List<Opportunity__c> opps = [
            SELECT Id, Name, Stage__c, Amount__c
            FROM Opportunity__c
            WHERE Property__c = :propertyId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        return new Map<String, Object>{
            'property'      => prop,
            'siteVisits'    => siteVisits,
            'leads'         => leads,
            'documents'     => docs,
            'opportunities' => opps
        };
    }

    // ─────────────────────────────────────────────
    // ACTIVITIES FOR LEAD
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getActivitiesForLead(Id leadId) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        // Tasks
        for (Task t : [
            SELECT Id, Subject, ActivityDate, Status, Priority, Description,
                   CallType, IsRecurrence, CreatedDate
            FROM Task
            WHERE WhatId = :leadId
            ORDER BY ActivityDate DESC NULLS LAST, CreatedDate DESC
            LIMIT 50
        ]) {
            result.add(new Map<String, Object>{
                'Id'           => t.Id,
                'Subject'      => t.Subject,
                'ActivityDate' => t.ActivityDate,
                'Status'       => t.Status,
                'Priority'     => t.Priority,
                'Description'  => t.Description,
                'CallType'     => t.CallType,
                'IsRecurrence' => t.IsRecurrence,
                'CreatedDate'  => t.CreatedDate,
                'RecordType'   => 'Task'
            });
        }

        // Events
        for (Event e : [
            SELECT Id, Subject, StartDateTime, EndDateTime, Description, CreatedDate
            FROM Event
            WHERE WhatId = :leadId
            ORDER BY StartDateTime DESC NULLS LAST, CreatedDate DESC
            LIMIT 50
        ]) {
            result.add(new Map<String, Object>{
                'Id'            => e.Id,
                'Subject'       => e.Subject,
                'ActivityDate'  => e.StartDateTime,
                'StartDateTime' => e.StartDateTime,
                'EndDateTime'   => e.EndDateTime,
                'Description'   => e.Description,
                'CreatedDate'   => e.CreatedDate,
                'RecordType'    => 'Event'
            });
        }

        return result;
    }

    // ─────────────────────────────────────────────
    // SITE VISITS FOR LEAD
    // ─────────────────────────────────────────────
    @AuraEnabled(cacheable=false)
    public static List<Site_Visit__c> getSiteVisitsForLead(Id leadId) {
        return [
            SELECT
                Id,
                Name,
                Visit_Date_Time__c,
                Status__c,
                Property__c,
                Property__r.Name,
                Property_Manager1__c,
                Property_Manager1__r.Name,
                CustomLead__c,
                CreatedDate
            FROM Site_Visit__c
            WHERE CustomLead__c = :leadId
            ORDER BY Visit_Date_Time__c DESC NULLS LAST
            LIMIT 50
        ];
    }

}