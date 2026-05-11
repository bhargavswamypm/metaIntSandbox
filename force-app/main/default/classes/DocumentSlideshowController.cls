public with sharing class DocumentSlideshowController {
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getRelatedDocuments(String recordId) {
        try {
            List<DocumentWrapper> documentList = new List<DocumentWrapper>();
            
            // Query ContentDocumentLinks related to the record
            List<ContentDocumentLink> cdLinks = [
                SELECT ContentDocumentId, ContentDocument.Title, 
                       ContentDocument.FileType, ContentDocument.FileExtension,
                       ContentDocument.ContentSize, ContentDocument.CreatedDate
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId
                ORDER BY ContentDocument.CreatedDate ASC
            ];
            
            // Process each document
            for (ContentDocumentLink cdl : cdLinks) {
                DocumentWrapper doc = new DocumentWrapper();
                doc.contentDocumentId = cdl.ContentDocumentId;
                doc.title = cdl.ContentDocument.Title;
                doc.fileType = cdl.ContentDocument.FileType;
                doc.fileExtension = cdl.ContentDocument.FileExtension;
                doc.fileSize = formatFileSize(cdl.ContentDocument.ContentSize);
                doc.createdDate = cdl.ContentDocument.CreatedDate;
                
                // Use preview URL for PDFs and images, download URL for others
                String extension = cdl.ContentDocument.FileExtension != null ? 
                    cdl.ContentDocument.FileExtension.toLowerCase() : '';
                if (extension == 'pdf' || extension == 'png' || extension == 'jpg' || 
                    extension == 'jpeg' || extension == 'gif' || extension == 'bmp') {
                    doc.downloadUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + 
                        getLatestVersionId(cdl.ContentDocumentId);
                    doc.previewUrl = '/lightning/r/ContentDocument/' + cdl.ContentDocumentId + '/view';
                } else {
                    doc.downloadUrl = '/sfc/servlet.shepherd/document/download/' + cdl.ContentDocumentId;
                    doc.previewUrl = '/lightning/r/ContentDocument/' + cdl.ContentDocumentId + '/view';
                }
                
                doc.iconName = getIconName(cdl.ContentDocument.FileExtension);
                
                documentList.add(doc);
            }
            
            return documentList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving documents: ' + e.getMessage());
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