trigger leadTrigger on Lead__c (before insert) {

    if (Trigger.isInsert && Trigger.isBefore) {

        Set<String> phonePatterns = new Set<String>();

        // Build pattern by extracting last 10 digits as key
        for (Lead__c lead : Trigger.new) {
            if (lead.Phone__c != null) {
                String clearedPhone = lead.Phone__c.replaceAll('[^0-9]', ''); // remove all non-numeric
                if (clearedPhone.length() > 10) {
                    clearedPhone = clearedPhone.substring(clearedPhone.length() - 10); // take last 10 digits
                }
                phonePatterns.add('%' + clearedPhone + '%');
            }
        }

        // Fetch leads using LIKE (fuzzy match)
        List<Lead__c> existingLeads = new List<Lead__c>();
        for (String phoneLike : phonePatterns) {
            existingLeads.addAll([
                SELECT Id, Phone__c
                FROM Lead__c
                WHERE Phone__c LIKE :phoneLike
            ]);
        }

        // Now validate
        for (Lead__c lead : Trigger.new) {
            if (lead.Phone__c != null) {
                String leadPhone = lead.Phone__c.replaceAll('[^0-9]', '');
                if (leadPhone.length() > 10) {
                    leadPhone = leadPhone.substring(leadPhone.length() - 10);
                }

                for (Lead__c exLead : existingLeads) {
                    String exPhone = exLead.Phone__c != null ? exLead.Phone__c.replaceAll('[^0-9]', '') : '';
                    if (exPhone.length() > 10) {
                        exPhone = exPhone.substring(exPhone.length() - 10);
                    }

                    if (leadPhone == exPhone) {
                        lead.addError('A Lead with a similar phone number (' + exLead.Phone__c +
                                      ') already exists. Please review before creating a new one.');
                    }
                }
            }
        }
    }
}