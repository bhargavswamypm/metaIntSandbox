public class PropertyFieldCheckHandler {

    public static void notifyParentAssignments(Map<Id, List<String>> propMissingMap) {

        // 1. Fetch Parent Property IDs
        Map<Id, Id> childToParent = new Map<Id, Id>();

        for (Property__c p : [
            SELECT Id,name, Parent_Property__c
            FROM Property__c
            WHERE Id IN :propMissingMap.keySet()
        ]) {
            childToParent.put(p.Id, p.Parent_Property__c);
        }

        // 2. Fetch assignments on Parent Property
        List<Property_Assignment__c> assignments = [
            SELECT Property__c, User__r.Email
            FROM Property_Assignment__c
            WHERE Property__c IN :childToParent.values()
                  AND User__r.Email != null
        ];

        // Map Parent -> Emails
        Map<Id, List<String>> parentToEmails = new Map<Id, List<String>>();

        for (Property_Assignment__c pa : assignments) {
            if (!parentToEmails.containsKey(pa.Property__c)) {
                parentToEmails.put(pa.Property__c, new List<String>());
            }
            parentToEmails.get(pa.Property__c).add(pa.User__r.Email);
        }

        // 3. Send emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id childPropId : propMissingMap.keySet()) {
            Id parentId = childToParent.get(childPropId);

            if (!parentToEmails.containsKey(parentId)) continue;

            List<String> missingFields = propMissingMap.get(childPropId);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(parentToEmails.get(parentId));

            mail.setSubject('Missing Details in Child Property Record');

            String recordUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + childPropId;

            Map<Id, Property__c> props = new Map<Id, Property__c>(
    [SELECT Id, Name, Parent_Property__c 
     FROM Property__c 
     WHERE Id IN :propMissingMap.keySet()]
);
            
String propName = props.get(childPropId).Name;

String body =
    'Dear Team,' + '\n\n' +
    'We have identified that certain required details are missing in the Property record listed below:' + '\n\n' +
    'Property Name: ' + propName + '\n' +
    'Missing Fields: ' + String.join(missingFields, ', ') + '\n\n' +
    'Kindly review and update the record at your earliest convenience:' + '\n' +
    recordUrl + '\n\n' +
    'Thanks & Regards,' + '\n' +
    'Team Getta Properties';


            mail.setPlainTextBody(body);

            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}