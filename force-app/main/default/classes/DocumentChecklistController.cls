public with sharing class DocumentChecklistController {

    @AuraEnabled(cacheable=true)
    public static List<Object> getChecklistData(Id propertyId, String fieldsCsv) {

        if (propertyId == null) {
            throw new AuraHandledException('No Property Id received from Lightning Action.');
        }

        // Parse API names
        List<String> fieldApiNames = new List<String>();
        if (!String.isBlank(fieldsCsv)) {
            for (String s : fieldsCsv.split(',')) {
                if (String.isNotBlank(s)) fieldApiNames.add(s.trim());
            }
        }

        // Build query
        String selectList = 'Id, Name';
        for (String f : fieldApiNames) selectList += ', ' + f;

        List<Property__c> pList = Database.query(
            'SELECT ' + selectList + ' FROM Property__c WHERE Id = :propertyId LIMIT 1'
        );

        if (pList.isEmpty()) {
            throw new AuraHandledException('Property not found: ' + propertyId);
        }

        Property__c prop = pList[0];

        // Label lookup
        Map<String, Schema.SObjectField> fieldsMap =
            Schema.getGlobalDescribe().get('Property__c').getDescribe().fields.getMap();

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        List<String> labels = new List<String>();

        for (String apiName : fieldApiNames) {
            String label = apiName;
            if (fieldsMap.containsKey(apiName)) {
                label = fieldsMap.get(apiName).getDescribe().getLabel();
            }

            Boolean checked = false;
            try {
                checked = (Boolean)prop.get(apiName);
            } catch (Exception e) { checked = false; }

            rows.add(new Map<String, Object>{
                'apiName' => apiName,
                'label' => label,
                'checked' => checked,
                'uploaded' => false,
                'propertyDocumentId' => null,
                'contentDocumentId' => null,
                'fileName' => null
            });

            labels.add(label);
        }

        // Child document lookup - Get ALL documents for each type
        List<Property_Document__c> docs = [
            SELECT Id, Name, Document_Type__c,
                   (SELECT Id, ContentDocumentId FROM ContentDocumentLinks LIMIT 1)
            FROM Property_Document__c
            WHERE Property__c = :propertyId
            AND Document_Type__c IN :labels
            ORDER BY Document_Type__c, CreatedDate DESC
        ];

        // Group by label - support multiple documents per type
        Map<String, List<Property_Document__c>> byLabel = new Map<String, List<Property_Document__c>>();
        for (Property_Document__c d : docs) {
            if (!byLabel.containsKey(d.Document_Type__c)) {
                byLabel.put(d.Document_Type__c, new List<Property_Document__c>());
            }
            byLabel.get(d.Document_Type__c).add(d);
        }

        // Mark uploaded - return ALL documents for each type
        for (Map<String, Object> r : rows) {
            String lbl = (String)r.get('label');

            if (byLabel.containsKey(lbl) && !byLabel.get(lbl).isEmpty()) {
                List<Property_Document__c> docList = byLabel.get(lbl);
                r.put('uploaded', true);
                
                // Build documents array with all documents
                List<Map<String, String>> documentsArray = new List<Map<String, String>>();
                for (Property_Document__c doc : docList) {
                    String contentDocId = null;
                    if (doc.ContentDocumentLinks != null && !doc.ContentDocumentLinks.isEmpty()) {
                        contentDocId = doc.ContentDocumentLinks[0].ContentDocumentId;
                    }
                    
                    documentsArray.add(new Map<String, String>{
                        'propertyDocumentId' => doc.Id,
                        'contentDocumentId' => contentDocId,
                        'fileName' => doc.Name
                    });
                }
                
                r.put('documents', documentsArray);
                
                // Keep backward compatibility fields (use first document)
                Property_Document__c firstDoc = docList[0];
                r.put('propertyDocumentId', firstDoc.Id);
                r.put('fileName', firstDoc.Name);
                if (firstDoc.ContentDocumentLinks != null && !firstDoc.ContentDocumentLinks.isEmpty()) {
                    r.put('contentDocumentId', firstDoc.ContentDocumentLinks[0].ContentDocumentId);
                }
            }
        }

        return new List<Object>{ rows, prop.Name };
    }


    @AuraEnabled
    public static Map<String, String> uploadFile(
        Id propertyId,
        String documentType,
        String base64Data,
        String fileName,
        String contentType
    ) {
        Map<String, String> resp = new Map<String, String>();

        if (propertyId == null) {
            resp.put('success','false');
            resp.put('error','Missing Property Id.');
            return resp;
        }

        if (String.isBlank(documentType)) {
            resp.put('success','false');
            resp.put('error','Missing document type.');
            return resp;
        }

        try {
            // Create ContentVersion
            ContentVersion cv = new ContentVersion(
                Title = fileName,
                PathOnClient = fileName,
                VersionData = EncodingUtil.base64Decode(base64Data)
            );
            insert cv;

            // Fetch ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Id cdId = cv.ContentDocumentId;

            // Create child record
            Property_Document__c pd = new Property_Document__c(
                Property__c = propertyId,
                Document_Type__c = documentType,
                Name = fileName
            );
            insert pd;

            // Link file to parent + child
            insert new List<ContentDocumentLink>{
                new ContentDocumentLink(ContentDocumentId = cdId, LinkedEntityId = propertyId, ShareType='V', Visibility='AllUsers'),
                new ContentDocumentLink(ContentDocumentId = cdId, LinkedEntityId = pd.Id, ShareType='V', Visibility='AllUsers')
            };

            resp.put('success','true');
            resp.put('propertyDocumentId', String.valueOf(pd.Id));
            resp.put('contentDocumentId', String.valueOf(cdId));
            resp.put('fileName', fileName);
            return resp;

        } catch (Exception e) {
            resp.put('success','false');
            resp.put('error', e.getMessage());
            return resp;
        }
    }


    @AuraEnabled
    public static void deletePropertyDocument(Id propertyDocumentId) {
        if (propertyDocumentId == null) {
            throw new AuraHandledException('No Property Document Id provided.');
        }

        try {
            // Query the Property Document and its ContentDocumentLinks
            List<Property_Document__c> docList = [
                SELECT Id, 
                       (SELECT ContentDocumentId FROM ContentDocumentLinks)
                FROM Property_Document__c 
                WHERE Id = :propertyDocumentId
                LIMIT 1
            ];

            if (docList.isEmpty()) {
                throw new AuraHandledException('Property Document not found.');
            }

            Property_Document__c doc = docList[0];
            Set<Id> contentDocIds = new Set<Id>();

            // Collect all ContentDocument IDs
            for (ContentDocumentLink cdl : doc.ContentDocumentLinks) {
                contentDocIds.add(cdl.ContentDocumentId);
            }

            // Delete ContentDocuments (this will cascade delete ContentVersions and ContentDocumentLinks)
            if (!contentDocIds.isEmpty()) {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds];
            }

            // Delete the Property Document record
            delete doc;

        } catch (Exception e) {
            throw new AuraHandledException('Error deleting document: ' + e.getMessage());
        }
    }

}