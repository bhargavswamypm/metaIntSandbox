// CredentialsController.cls (Apex Controller)
public with sharing class CredentialsController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentWrapper> getRelatedFiles(Id recordId) {
        try {
            Set<Id> contentDocumentIds = new Set<Id>();
            
            // Get ContentDocumentLinks related to the record
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
            ]) {
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
            
            // Get ContentDocument details with latest version description
            List<ContentDocument> documents = [
                SELECT Id, Title, FileExtension, CreatedDate, ContentSize,
                       LatestPublishedVersion.Description
                FROM ContentDocument 
                WHERE Id IN :contentDocumentIds
                ORDER BY CreatedDate DESC
            ];
            
            // Build wrapper list
            List<ContentDocumentWrapper> wrappers = new List<ContentDocumentWrapper>();
            for (ContentDocument doc : documents) {
                ContentDocumentWrapper wrapper = new ContentDocumentWrapper();
                wrapper.Id = doc.Id;
                wrapper.Title = doc.Title;
                wrapper.FileExtension = doc.FileExtension;
                wrapper.CreatedDate = doc.CreatedDate;
                wrapper.ContentSize = doc.ContentSize;
                
                // Format credential type for display from Description
                String credType = doc.LatestPublishedVersion.Description;
                if (String.isNotBlank(credType)) {
                    wrapper.CredentialType = credType.replace('_', ' ');
                } else {
                    wrapper.CredentialType = 'Not Specified';
                }
                
                wrappers.add(wrapper);
            }
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving files: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void tagFilesWithCredentialType(List<Id> contentVersionIds, String credentialType) {
        try {
            // Query ContentVersions to update
            List<ContentVersion> versionsToUpdate = [
                SELECT Id, Description, ContentDocumentId
                FROM ContentVersion 
                WHERE Id IN :contentVersionIds
            ];
            
            System.debug('ContentVersions found: ' + versionsToUpdate.size());
            System.debug('Credential Type: ' + credentialType);
            
            // Update Description with credential type
            for (ContentVersion cv : versionsToUpdate) {
                cv.Description = credentialType;
                System.debug('Updating CV: ' + cv.Id + ' with type: ' + credentialType);
            }
            
            if (!versionsToUpdate.isEmpty()) {
                update versionsToUpdate;
                System.debug('Updated ' + versionsToUpdate.size() + ' ContentVersions');
            }
        } catch (Exception e) {
            System.debug('Error in tagFilesWithCredentialType: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error tagging files: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteFile(Id contentDocumentId) {
        try {
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }
    
    // Wrapper class for content document with credential type
    public class ContentDocumentWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Title { get; set; }
        @AuraEnabled public String FileExtension { get; set; }
        @AuraEnabled public Datetime CreatedDate { get; set; }
        @AuraEnabled public Integer ContentSize { get; set; }
        @AuraEnabled public String CredentialType { get; set; }
    }
}