public with sharing class leadConvertController {
   /* 
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchKey) {
        String searchPattern = '%' + searchKey + '%';
        return [SELECT Id, Name 
                FROM Account 
                WHERE Name LIKE :searchPattern 
                ORDER BY Name
                LIMIT 50];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchKey) {
        String searchPattern = '%' + searchKey + '%';
        return [SELECT Id, Name, Email 
                FROM Contact 
                WHERE Name LIKE :searchPattern 
                ORDER BY Name
                LIMIT 50];
    }
    private static Map<String, Id> getRTMap(String objectName) {
    Map<String, Id> rtMap = new Map<String, Id>();
    for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = :objectName]) {
        rtMap.put(rt.DeveloperName, rt.Id);
        system.debug('return recordtype'+rtMap);
    }
    return rtMap;
}

    
    @AuraEnabled
    public static Map<String, Id> convertLead(Map<String, Object> request) {
        Id leadId = (Id)request.get('leadId');
        Id ownerId = (Id)request.get('ownerId');
        Id Property =(Id)request.get('PropertyId');
        system.debug('property id'+Property);
        string leadStatus = (String)request.get('convertStatus');
        if (ownerId == null) {
            ownerId = UserInfo.getUserId(); // Default to current user if not specified
        }
        Lead__c l = [SELECT Id, Name, Company__c, Email__c, Lead_Status__c  
                  FROM Lead__c 
                  WHERE Id = :leadId 
                  LIMIT 1];
        
        if (l.Lead_Status__c == 'Converted') {
            throw new AuraHandledException('Lead is already converted');
        }

        Id accountId;
        Id contactId;
        Id opportunityId;
        String leadType = (String)request.get('recordType'); // Buyer / Seller / Tenant
system.debug('lead type'+leadType);
// Map Lead Type → RecordType Developer Name
String accountRTDev = null;
String contactRTDev = null;
String opportunityRTDev = null;

if (leadType == 'Buyer') {
    accountRTDev = 'Buyers';
    system.debug('buyeser'+accountRTDev);
    contactRTDev = 'Buyers';
    opportunityRTDev = 'Buyers';
} else if (leadType == 'Seller') {
    accountRTDev = 'Sellers';
    contactRTDev = 'Sellers';
    opportunityRTDev = 'Sellers';
} else if (leadType == 'Tenant') {
    accountRTDev = 'Tenants';
    contactRTDev = 'Tenants';
    opportunityRTDev = 'Tenants';
}

Map<String, Id> accRTMap = getRTMap('Account');
Map<String, Id> conRTMap = getRTMap('Contact');
Map<String, Id> oppRTMap = getRTMap('Opportunity__c');
system.debug('Account recordtype id'+accRTMap);

        try {
            
            // Account handling
            if((String)request.get('accountOption') == 'new'){
                String accName = (String)request.get('accountName');
                if (String.isBlank(accName)) {
                    throw new AuraHandledException('Account Name is required');
                }
                Account acc = new Account(Name = accName, OwnerId = ownerId,RecordTypeId = accRTMap.get(accountRTDev) );
                insert acc;
                accountId = acc.Id;
            } else {
                accountId = (Id)request.get('selectedAccountId');
                if (accountId == null) {
                    throw new AuraHandledException('Please select an Account');
                }
            }

            // Contact handling
            if((String)request.get('contactOption') == 'new'){
                String lastNameValue = (String)request.get('lastName');
                if (String.isBlank(lastNameValue)) {
                    throw new AuraHandledException('Last Name is required');
                }
                
                Contact c = new Contact(
                    Salutation = (String)request.get('salutation'),
                    FirstName = (String)request.get('firstName'),
                    OwnerId = ownerId , 
                    LastName = lastNameValue,
                    Email = l.Email__c, 
                    AccountId = accountId,
                    RecordTypeId = conRTMap.get(contactRTDev)
                );
                
                // Use Database.insert with allOrNone=false to handle duplicate detection
                Database.SaveResult sr = Database.insert(c, false);
                
                if (!sr.isSuccess()) {
                    // Check for duplicate errors
                    for(Database.Error err : sr.getErrors()) {
                        if(err.getStatusCode() == StatusCode.DUPLICATES_DETECTED) {
                            throw new AuraHandledException('A Contact with similar information already exists. Please use the "Existing Contact" option and select from the existing records.');
                        } else {
                            throw new AuraHandledException('Error creating Contact: ' + err.getMessage());
                        }
                    }
                } else {
                    contactId = sr.getId();
                }
            } else {
                contactId = (Id)request.get('selectedContactId');
                if (contactId == null) {
                    throw new AuraHandledException('Please select a Contact');
                }
                // Update contact's account if needed
                Contact existingContact = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
                if (existingContact.AccountId != accountId) {
                    existingContact.AccountId = accountId;
                    update existingContact;
                }
            }

            // Opportunity handling
            String oppName = (String)request.get('opportunityName');
            if(String.isNotBlank(oppName)){
                Opportunity__c opp = new Opportunity__c(
                    Name = oppName, 
                    Buyer_Account__c = accountId, 
                    Stage__c = 'Inquiry',
                    Property__c= Property,
                     RecordTypeId = oppRTMap.get(opportunityRTDev), 
                    Actual_Close_Date__c = System.today().addMonths(1),
                    OwnerId = ownerId
                );
                insert opp;
                opportunityId = opp.Id;
            }
            
            // Update lead status
            l.Lead_Status__c = leadStatus;
            update l;

            return new Map<String, Id>{
                'accountId' => accountId,
                'contactId' => contactId,
                'opportunityId' => opportunityId
            };

        } catch (DmlException e) {
            // Handle DML exceptions with better error messages
            String errorMessage = e.getMessage();
            if (errorMessage.contains('DUPLICATES_DETECTED')) {
                throw new AuraHandledException('A duplicate record was detected. Please select an existing record instead of creating a new one.');
            } else if (errorMessage.contains('REQUIRED_FIELD_MISSING')) {
                throw new AuraHandledException('Required field is missing. Please fill in all required fields.');
            } else {
                throw new AuraHandledException('Database error: ' + errorMessage);
            }
        } catch (AuraHandledException e) {
            // Re-throw AuraHandledException as-is
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error converting lead: ' + e.getMessage());
        }
    }*/
}