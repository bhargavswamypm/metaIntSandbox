public with sharing class PropertyDocumentSlideshowController {
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getPropertyDocuments(String propertyId) {
        try {
            List<DocumentWrapper> documentList = new List<DocumentWrapper>();
            
            // Query Property_Document__c records related to the property
            List<Property_Document__c> propertyDocs = [
                SELECT Id, Name
                FROM Property_Document__c 
                WHERE Property__c = :propertyId
                ORDER BY CreatedDate ASC
            ];
            
            if (propertyDocs.isEmpty()) {
                return documentList;
            }
            
            // Collect all Property_Document__c IDs
            Set<Id> propertyDocIds = new Set<Id>();
            for (Property_Document__c pd : propertyDocs) {
                propertyDocIds.add(pd.Id);
            }
            
            // Query ContentDocumentLinks for these Property_Document__c records
            List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocumentId, ContentDocument.Title, 
                       ContentDocument.FileType, ContentDocument.FileExtension,
                       ContentDocument.ContentSize, ContentDocument.CreatedDate,
                       LinkedEntityId
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :propertyDocIds
                ORDER BY ContentDocument.CreatedDate ASC
            ];
            
            if (cdLinks.isEmpty()) {
                return documentList;
            }
            
            // Process each ContentDocumentLink
            for (ContentDocumentLink cdl : cdLinks) {
                DocumentWrapper wrapper = new DocumentWrapper();
                wrapper.contentDocumentId = cdl.ContentDocumentId;
                wrapper.title = cdl.ContentDocument.Title;
                wrapper.fileType = cdl.ContentDocument.FileType;
                wrapper.fileExtension = cdl.ContentDocument.FileExtension;
                wrapper.fileSize = formatFileSize(cdl.ContentDocument.ContentSize);
                wrapper.createdDate = cdl.ContentDocument.CreatedDate;
                
                // Set URLs based on file type
                String extension = cdl.ContentDocument.FileExtension != null ? 
                    cdl.ContentDocument.FileExtension.toLowerCase() : '';
                if (extension == 'pdf' || extension == 'png' || extension == 'jpg' || 
                    extension == 'jpeg' || extension == 'gif' || extension == 'bmp') {
                    wrapper.downloadUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + 
                        getLatestVersionId(cdl.ContentDocumentId);
                    wrapper.previewUrl = '/lightning/r/ContentDocument/' + cdl.ContentDocumentId + '/view';
                } else {
                    wrapper.downloadUrl = '/sfc/servlet.shepherd/document/download/' + cdl.ContentDocumentId;
                    wrapper.previewUrl = '/lightning/r/ContentDocument/' + cdl.ContentDocumentId + '/view';
                }
                
                wrapper.iconName = getIconName(cdl.ContentDocument.FileExtension);
                
                documentList.add(wrapper);
            }
            
            return documentList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving property documents: ' + e.getMessage());
        }
    }
    
    // Helper method to get latest version ID for preview
    private static String getLatestVersionId(Id contentDocumentId) {
        try {
            ContentVersion cv = [
                SELECT Id 
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentDocumentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            return cv.Id;
        } catch (Exception e) {
            return '';
        }
    }
    
    // Helper method to format file size
    private static String formatFileSize(Integer bytes) {
        if (bytes == null) return '0 B';
        
        if (bytes < 1024) {
            return bytes + ' B';
        } else if (bytes < 1048576) {
            return String.valueOf(Math.round(bytes / 1024.0)) + ' KB';
        } else if (bytes < 1073741824) {
            return String.valueOf(Math.round(bytes / 1048576.0)) + ' MB';
        } else {
            return String.valueOf(Math.round(bytes / 1073741824.0)) + ' GB';
        }
    }
    
    // Helper method to get appropriate icon based on file extension
    private static String getIconName(String extension) {
        if (extension == null) return 'doctype:attachment';
        
        extension = extension.toLowerCase();
        
        Map<String, String> iconMap = new Map<String, String>{
            'pdf' => 'doctype:pdf',
            'doc' => 'doctype:word',
            'docx' => 'doctype:word',
            'xls' => 'doctype:excel',
            'xlsx' => 'doctype:excel',
            'ppt' => 'doctype:ppt',
            'pptx' => 'doctype:ppt',
            'txt' => 'doctype:txt',
            'csv' => 'doctype:csv',
            'zip' => 'doctype:zip',
            'xml' => 'doctype:xml',
            'mp4' => 'doctype:video',
            'mov' => 'doctype:video',
            'mp3' => 'doctype:audio',
            'wav' => 'doctype:audio',
            'jpg' => 'doctype:image',
            'jpeg' => 'doctype:image',
            'png' => 'doctype:image',
            'gif' => 'doctype:image',
            'bmp' => 'doctype:image',
            'svg' => 'doctype:image'
        };
        
        return iconMap.containsKey(extension) ? iconMap.get(extension) : 'doctype:attachment';
    }
    
    // Wrapper class for document data
    public class DocumentWrapper {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String fileSize;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public String iconName;
    }
}