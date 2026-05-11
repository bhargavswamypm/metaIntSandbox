@RestResource(urlMapping='/api/lead/*')
global class LeadCaptureAPI {

    @HttpGet
    global static PropertyDataResponse getAllProperties() {
        PropertyDataResponse response = new PropertyDataResponse();
        
        try {
            // Get all parent properties (RecordType = Parent_Property)
            Id parentRecordTypeId = [SELECT Id FROM RecordType 
                                     WHERE SObjectType = 'Property__c' 
                                     AND Name = 'Parent Project' 
                                     LIMIT 1].Id;
            
List<Property__c> parentProps = [
    SELECT Id, Name 
    FROM Property__c 
    WHERE RecordTypeId = :parentRecordTypeId
    ORDER BY Name
    LIMIT 1999  // Add limit
];
            
            for (Property__c p : parentProps) {
                response.parentProperties.add(new PropertyResponse(p.Id, p.Name, null, null));
            }
            
            // Get all child properties (RecordType = Sale or Rent) with Parent_Property__c
            Id saleRecordTypeId = [SELECT Id FROM RecordType 
                                   WHERE SObjectType = 'Property__c' 
                                   AND Name = 'Sale' 
                                   LIMIT 1].Id;
            
            Id rentRecordTypeId = [SELECT Id FROM RecordType 
                                   WHERE SObjectType = 'Property__c' 
                                   AND Name = 'Rent' 
                                   LIMIT 1].Id;
            
List<Property__c> childProps = [
    SELECT Id, Name, Parent_Property__c, RecordType.Name
    FROM Property__c 
    WHERE (RecordTypeId = :saleRecordTypeId OR RecordTypeId = :rentRecordTypeId)
    AND (Position__c != 'Sold' OR Position__c != 'Rented' OR Position__c != 'Self Occupied')
    AND Parent_Property__c != null
    ORDER BY Name
    LIMIT 1999  // Add limit
];
            
            for (Property__c p : childProps) {
                response.childProperties.add(
                    new PropertyResponse(p.Id, p.Name, p.Parent_Property__c, p.RecordType.Name)
                );
            }
            
        } catch (Exception e) {
            System.debug('Error fetching properties: ' + e.getMessage());
        }
        
        return response;
    }

    global class PropertyDataResponse {
        public List<PropertyResponse> parentProperties;
        public List<PropertyResponse> childProperties;
        
        public PropertyDataResponse() {
            this.parentProperties = new List<PropertyResponse>();
            this.childProperties = new List<PropertyResponse>();
        }
    }

    global class PropertyResponse {
        public String id;
        public String name;
        public String parentPropertyId;
        public String recordType;
        
        public PropertyResponse(String id, String name, String parentPropertyId, String recordType) {
            this.id = id;
            this.name = name;
            this.parentPropertyId = parentPropertyId;
            this.recordType = recordType;
        }
    }
    
    @HttpPost
    global static APIResponse createLead() {
        APIResponse response = new APIResponse();
        
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            Lead__c lead = new Lead__c();
            
            if (params.containsKey('firstName')) {
                lead.First_Name__c = String.valueOf(params.get('firstName'));
            }
            
            if (params.containsKey('lastName')) {
                lead.Last_Name__c = String.valueOf(params.get('lastName'));
            }
            
            if (params.containsKey('company')) {
                lead.Company__c = String.valueOf(params.get('company'));
            } else {
                lead.Company__c = '[not provided]';
            }
            
            if (params.containsKey('budget')) {
    		lead.Budget__c = Double.valueOf(params.get('budget'));
			}
            
            if (params.containsKey('email')) {
                lead.Email__c = String.valueOf(params.get('email'));
            }
            
            if (params.containsKey('phone')) {
                lead.Phone__c = String.valueOf(params.get('phone'));
            }
            
            lead.Lead_Source__c = 'Web';
            
            if (params.containsKey('leadType')) {
                lead.Lead_Type__c = String.valueOf(params.get('leadType'));
            }
            
            if (params.containsKey('property')) {
                String propertyId = String.valueOf(params.get('property'));
                lead.Property_Interested_in__c = propertyId;

                List<Property__c> props = [
                    SELECT Id, Property_No__c, Facing__c, Configuration__c, Location__c
                    FROM Property__c
                    WHERE Id = :propertyId
                    LIMIT 1
                ];

                if (!props.isEmpty()) {
                    Property__c prop = props[0];
                    lead.Property_No__c = prop.Property_No__c;
                    lead.Facing__c = prop.Facing__c;
                    lead.Configuration__c = prop.Configuration__c;
                    lead.Location__c = prop.Location__c;
                }
            }
            
            if (String.isBlank(lead.Last_Name__c)) {
                response.success = false;
                response.message = 'Last Name is required';
                return response;
            }
            
            if (String.isBlank(lead.Phone__c)) {
                response.success = false;
                response.message = 'Phone is required';
                return response;
            }
            
            if (String.isBlank(lead.Lead_Type__c)) {
                response.success = false;
                response.message = 'Lead Type is required';
                return response;
            }
            
            if (params.containsKey('leadStatus')) {
                lead.Lead_Status__c = String.valueOf(params.get('leadStatus'));
            } else {
                lead.Lead_Status__c = 'Open';
            }
            
            insert lead;
            
            response.success = true;
            response.message = 'Lead created successfully';
            response.leadId = lead.Id;
            
        } catch (Exception e) {
            response.success = false;
            response.message = 'Error: ' + e.getMessage();
        }
        
        return response;
    }
    
    global class APIResponse {
        public Boolean success;
        public String message;
        public String leadId;
        
        public APIResponse() {
            this.success = false;
            this.message = '';
            this.leadId = '';
        }
    }
}